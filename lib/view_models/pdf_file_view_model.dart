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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final PdfRepository _pdfRepository = PdfRepository();
  
  List<PdfFileInfo> _pdfFiles = [];
  PdfFileInfo? _selectedPdf;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<PdfFileInfo> get pdfFiles => _pdfFiles;
  PdfFileInfo? get selectedPdf => _selectedPdf;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// 사용자의 PDF 파일 목록 로드
  Future<void> loadPdfFiles(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // 게스트 사용자인 경우 빈 목록 반환
      if (userId == 'guest_user') {
        debugPrint('게스트 사용자: 빈 PDF 목록 사용');
        _pdfFiles = [];
        notifyListeners();
        return;
      }
      
      final files = await _pdfRepository.getPdfFiles(userId);
      _pdfFiles = files;
      
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 목록을 불러오는 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 파일 선택
  void selectPdf(PdfFileInfo pdf) {
    _selectedPdf = pdf;
    notifyListeners();
  }
  
  /// 파일 선택기를 통해 PDF 파일 업로드
  Future<void> uploadPdfFromFilePicker(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final isGuestUser = userId == 'guest_user';
        
        // 게스트 사용자인 경우 로컬에만 저장
        if (isGuestUser) {
          debugPrint('게스트 사용자: 로컬에만 PDF 저장');
          
          final file = File(result.files.first.path!);
          final fileName = result.files.first.name;
          final fileSize = result.files.first.size;
          
          // 게스트 사용자는 파일 크기 제한 (5MB)
          if (fileSize > 5 * 1024 * 1024) {
            _setError('게스트 모드에서는 5MB 이하의 PDF만 업로드할 수 있습니다.');
            return;
          }
          
          // 로컬 파일 정보만 생성 (Firestore에 저장하지 않음)
          final bytes = await file.readAsBytes();
          final pdfFile = PdfFileInfo(
            id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
            fileName: fileName,
            fileSize: fileSize,
            bytes: bytes,
            createdAt: DateTime.now(),
            userId: userId,
          );
          
          _pdfFiles.add(pdfFile);
          notifyListeners();
          return;
        }
        
        // 로그인 사용자는 정상적으로 저장소에 업로드
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        final fileSize = result.files.first.size;
        
        final pdfFile = await _pdfRepository.uploadPdfFile(file, fileName, fileSize, userId);
        _pdfFiles.add(pdfFile);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 업로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 드래그 앤 드롭으로 PDF 파일 업로드
  Future<void> uploadPdfFromDragDrop(List<File> files, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      for (final file in files) {
        if (file.path.toLowerCase().endsWith('.pdf')) {
          final fileName = file.path.split('/').last;
          final fileSize = await file.length();
          
          final pdfFile = await _pdfRepository.uploadPdfFile(file, fileName, fileSize, userId);
          _pdfFiles.add(pdfFile);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 업로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// URL에서 PDF 파일 업로드
  Future<void> uploadPdfFromUrl(String url, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final isGuestUser = userId == 'guest_user';
      
      // 게스트 사용자인 경우 로컬에만 저장
      if (isGuestUser) {
        debugPrint('게스트 사용자: URL에서 로컬에만 PDF 저장');
        
        // URL에서 PDF 다운로드
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('PDF 다운로드 실패: ${response.statusCode}');
        }
        
        final bytes = response.bodyBytes;
        
        // 게스트 사용자는 파일 크기 제한 (5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          _setError('게스트 모드에서는 5MB 이하의 PDF만 업로드할 수 있습니다.');
          return;
        }
        
        // 파일 이름 추출
        String fileName = url.split('/').last;
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName = 'document.pdf';
        }
        
        // 로컬 파일 정보만 생성 (Firestore에 저장하지 않음)
        final pdfFile = PdfFileInfo(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          fileName: fileName,
          fileSize: bytes.length,
          bytes: bytes,
          url: url,
          createdAt: DateTime.now(),
          userId: userId,
        );
        
        _pdfFiles.add(pdfFile);
        notifyListeners();
        return;
      }
      
      // 로그인 사용자는 정상적으로 저장소에 업로드
      final pdfFile = await _pdfRepository.uploadPdfFromUrl(url, userId);
      _pdfFiles.add(pdfFile);
      
      notifyListeners();
    } catch (e) {
      _setError('URL에서 PDF 파일 업로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 파일 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _pdfRepository.deletePdf(pdfId, userId);
      _pdfFiles.removeWhere((pdf) => pdf.id == pdfId);
      
      if (_selectedPdf?.id == pdfId) {
        _selectedPdf = null;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('PDF 파일 삭제 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 파일 데이터 가져오기
  Future<Uint8List?> getPdfData(String pdfId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // PDF 파일 목록이 비어있는 경우 처리
      if (_pdfFiles.isEmpty) {
        debugPrint('PDF 파일 목록이 비어 있습니다.');
        _setError('PDF 파일 목록이 비어 있습니다.');
        return null;
      }
      
      // 해당 ID의 PDF 파일 찾기
      PdfFileInfo? pdf;
      try {
        pdf = _pdfFiles.firstWhere((pdf) => pdf.id == pdfId);
      } catch (e) {
        debugPrint('ID가 $pdfId인 PDF 파일을 찾을 수 없습니다: $e');
        _setError('요청한 PDF 파일을 찾을 수 없습니다.');
        return null;
      }
      
      if (pdf == null) {
        debugPrint('ID가 $pdfId인 PDF 파일이 null입니다.');
        _setError('요청한 PDF 파일이 유효하지 않습니다.');
        return null;
      }
      
      // 게스트 사용자 파일인 경우 바로 bytes 반환
      if (pdf.id.startsWith('guest_') && pdf.bytes != null) {
        debugPrint('게스트 사용자 PDF 파일 데이터 반환: ${pdf.bytes!.length} 바이트');
        return pdf.bytes;
      }
      
      // PDF 데이터 읽기 시도
      Uint8List? data;
      try {
        data = await pdf.readAsBytes();
        if (data == null || data.isEmpty) {
          throw Exception('PDF 데이터가 비어 있습니다.');
        }
      } catch (e) {
        debugPrint('PDF 데이터 읽기 오류: $e');
        _setError('PDF 데이터를 읽는 중 오류가 발생했습니다: $e');
        return null;
      }
      
      return data;
    } catch (e) {
      debugPrint('getPdfData 메서드 오류: $e');
      _setError('PDF 데이터를 가져오는 중 오류가 발생했습니다: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // 내부 헬퍼 메서드
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
} 