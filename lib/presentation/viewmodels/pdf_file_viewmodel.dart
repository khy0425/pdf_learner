import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pdf_file_info.dart';
import '../services/storage_service.dart';
import '../repositories/pdf_repository.dart';

/// PDF 파일 관리를 위한 ViewModel
class PdfFileViewModel extends ChangeNotifier {
  final PDFRepository _repository;
  List<PdfFileInfo> _pdfFiles = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // 생성자
  PdfFileViewModel({required PDFRepository repository}) : _repository = repository {
    _loadFiles();
  }
  
  // 게터
  List<PdfFileInfo> get pdfFiles => _pdfFiles;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  
  // PDF 파일 목록 불러오기
  Future<void> _loadFiles() async {
    try {
      _setLoading(true);
      _clearError();
      
      final files = await _repository.getPdfFiles();
      _pdfFiles = files;
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 파일 목록을 불러오는 데 실패했습니다: $e');
    }
  }
  
  // PDF 파일 추가 (로컬 파일에서)
  Future<void> addPdfFromFile(String userId, File file, {String? filename}) async {
    try {
      _setLoading(true);
      _clearError();
      
      // 파일 크기 확인
      int fileSize = await file.length();
      
      // 파일 이름이 제공되지 않은 경우 파일 경로에서 추출
      final String fileName = filename ?? file.path.split('/').last;
      
      // 파일 데이터 읽기
      final Uint8List fileData = await file.readAsBytes();
      
      // PDF 정보 생성
      final pdfInfo = PdfFileInfo(
        id: '',  // 아이디는 저장 과정에서 생성됨
        userId: userId,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePath: '',  // 파일 경로는 저장 과정에서 설정됨
        thumbnailUrl: '',  // 썸네일은 저장 과정에서 생성됨
        pageCount: 0,  // 페이지 수는 저장 과정에서 확인됨
      );
      
      // PDF 저장 (리포지토리를 통해)
      final savedPdf = await _repository.addPdf(pdfInfo, fileData);
      
      // 저장된 PDF를 목록에 추가
      _pdfFiles.add(savedPdf);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 추가에 실패했습니다: $e');
    }
  }
  
  // PDF 파일 추가 (URL에서)
  Future<void> addPdfFromUrl(String userId, String url) async {
    try {
      _setLoading(true);
      _clearError();
      
      // URL에서 파일 이름 추출
      final Uri uri = Uri.parse(url);
      final String fileName = uri.pathSegments.last.isEmpty 
          ? 'document.pdf' 
          : uri.pathSegments.last;
      
      // URL에서 파일 다운로드
      final response = await http.get(uri);
      
      if (response.statusCode != 200) {
        throw Exception('URL에서 PDF를 다운로드할 수 없습니다: ${response.statusCode}');
      }
      
      // 파일 데이터
      final fileData = response.bodyBytes;
      final fileSize = fileData.length;
      
      // PDF 정보 생성
      final pdfInfo = PdfFileInfo(
        id: '',  // 아이디는 저장 과정에서 생성됨
        userId: userId,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePath: '',  // 파일 경로는 저장 과정에서 설정됨
        thumbnailUrl: '',  // 썸네일은 저장 과정에서 생성됨
        pageCount: 0,  // 페이지 수는 저장 과정에서 확인됨
      );
      
      // PDF 저장 (리포지토리를 통해)
      final savedPdf = await _repository.addPdf(pdfInfo, fileData);
      
      // 저장된 PDF를 목록에 추가
      _pdfFiles.add(savedPdf);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('URL에서 PDF 파일 추가에 실패했습니다: $e');
    }
  }
  
  // PDF 파일 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // 삭제할 PDF 파일 찾기
      final pdfToDelete = _pdfFiles.firstWhere(
        (pdf) => pdf.id == pdfId,
        orElse: () => throw Exception('PDF 파일을 찾을 수 없습니다'),
      );
      
      // 사용자 권한 확인
      if (pdfToDelete.userId != userId) {
        throw Exception('이 PDF 파일을 삭제할 권한이 없습니다');
      }
      
      // PDF 삭제 (리포지토리를 통해)
      await _repository.deletePdf(pdfId);
      
      // 목록에서 삭제
      _pdfFiles.removeWhere((pdf) => pdf.id == pdfId);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 삭제에 실패했습니다: $e');
    }
  }
  
  // PDF 파일 목록 새로고침
  Future<void> refreshFiles() async {
    await _loadFiles();
    notifyListeners();
  }
  
  // 로딩 상태 설정
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
  
  // 오류 설정
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
  
  // 오류 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
} 