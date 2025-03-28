import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/pdf_file_info.dart';
import '../../services/storage/storage_service.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../core/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../core/base/result.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/enums/pdf_file_status.dart';
import 'package:cross_file/cross_file.dart';
import '../../domain/models/pdf_document.dart';
import '../../services/pdf/pdf_service.dart';

/// PDF 파일 관리를 위한 ViewModel
class PdfFileViewModel extends BaseViewModel {
  final PDFRepository _repository;
  List<PDFDocument> _pdfFiles = [];
  PdfFileStatus _status = PdfFileStatus.initial;
  double _downloadProgress = 0.0;
  
  // 생성자
  PdfFileViewModel({required PDFRepository repository}) : _repository = repository {
    _loadFiles();
  }
  
  // 게터
  List<PDFDocument> get pdfFiles => _pdfFiles;
  PdfFileStatus get status => _status;
  
  /// 선택된 파일
  PDFDocument? get selectedFile => _pdfFiles.isNotEmpty
      ? _pdfFiles.firstWhere((file) => file.isSelected, orElse: () => _pdfFiles.first)
      : null;
  
  // PDF 파일 목록 불러오기
  Future<void> _loadFiles() async {
    try {
      _setStatus(PdfFileStatus.loading);
      
      final result = await _repository.getDocuments();
      if (result.isSuccess) {
        _pdfFiles = result.data!;
        _setStatus(PdfFileStatus.success);
      } else {
        _setError('PDF 파일 목록을 불러오는 데 실패했습니다: ${result.error}');
      }
    } catch (e) {
      _setError('PDF 파일 목록을 불러오는 데 실패했습니다: $e');
    }
  }
  
  // PDF 파일 추가 (로컬 파일에서)
  Future<void> addPdfFromFile(BuildContext context, String userId) async {
    try {
      _setStatus(PdfFileStatus.loading);
      
      // FileUtils를 사용하여 파일 선택
      final result = await FileUtils.pickPdfFile(context);
      
      if (result.isSuccess && result.getOrNull() != null) {
        final xFile = result.getOrNull()!;
        
        // 파일 객체 생성
        final file = File(xFile.path);
        
        // repository를 통해 PDF 가져오기
        final importResult = await _repository.importPDF(file);
        
        if (importResult.isSuccess) {
          // 가져온 PDF를 목록에 추가
          final savedPdf = importResult.data!;
          
          // 기존 목록에 없으면 추가
          if (!_pdfFiles.any((pdf) => pdf.id == savedPdf.id)) {
            _pdfFiles.add(savedPdf);
          }
          
          _setStatus(PdfFileStatus.success);
        } else {
          _setError('PDF 가져오기 실패: ${importResult.error}');
        }
      } else if (result.isFailure) {
        _setError('파일 선택 실패: ${result.error?.toString() ?? ''}');
      } else {
        _setStatus(PdfFileStatus.success); // 사용자가 취소한 경우
      }
    } catch (e) {
      _setError('PDF 파일 추가에 실패했습니다: $e');
    }
  }
  
  /// 상태 설정
  void _setStatus(PdfFileStatus status) {
    _status = status;
    
    switch (status) {
      case PdfFileStatus.loading:
      case PdfFileStatus.downloading:
        setLoading(true);
        break;
      case PdfFileStatus.success:
        setLoading(false);
        clearError();
        break;
      case PdfFileStatus.error:
        // 오류는 _setError 메서드에서 처리됩니다.
        break;
      case PdfFileStatus.initial:
        resetState();
        break;
    }
    
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String message) {
    _status = PdfFileStatus.error;
    setError(message);
  }
  
  /// PDF 파일 다운로드
  Future<Result<PDFDocument>> downloadPdf(String url, String title, {Map<String, dynamic>? metadata}) async {
    _setStatus(PdfFileStatus.downloading);
    _downloadProgress = 0.0;
    notifyListeners();
    
    try {
      // PDF 문서 객체 생성
      final tempDocument = PDFDocument(
        id: const Uuid().v4(),
        title: title,
        downloadUrl: url,
        filePath: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
      );
      
      // repository의 downloadPdf 메서드 호출 (PDFDocument 객체 전달)
      final contentResult = await _repository.downloadPdf(tempDocument);
      if (contentResult.isFailure) {
        _setStatus(PdfFileStatus.error);
        return Result.failure(contentResult.error!);
      }
      
      final pdfContent = contentResult.data!;
      
      // 저장 경로 생성
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/pdfs');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }
      
      // 파일명 생성
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
      final savedPath = '${pdfDir.path}/$fileName';
      
      // 파일 저장
      final saveResult = await _repository.saveFile(
        Uint8List.fromList(pdfContent as List<int>), 
        fileName,
        directory: pdfDir.path
      );
      if (saveResult.isFailure) {
        _setStatus(PdfFileStatus.error);
        return Result.failure(saveResult.error!);
      }
      
      final filePath = saveResult.data!;
      
      // PDF 문서 생성
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: title,
        filePath: filePath,
        downloadUrl: url,
        fileSize: pdfContent.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PDFDocumentStatus.downloaded,
        metadata: metadata ?? {},
      );
      
      // 문서 저장
      final saveDocResult = await _repository.saveDocument(document);
      if (saveDocResult.isFailure) {
        _setStatus(PdfFileStatus.error);
        return Result.failure(saveDocResult.error!);
      }
      
      final savedDocument = saveDocResult.data!;
      
      // 목록에 추가
      if (!_pdfFiles.any((pdf) => pdf.id == savedDocument.id)) {
        _pdfFiles.add(savedDocument);
      }
      
      _setStatus(PdfFileStatus.success);
      return Result.success(savedDocument);
      
    } catch (e) {
      _setStatus(PdfFileStatus.error);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }
  
  /// 다운로드 진행 상태 업데이트
  void updateDownloadProgress(double progress) {
    _downloadProgress = progress;
    notifyListeners();
  }
  
  /// 다운로드 진행 상태 가져오기
  double get downloadProgress => _downloadProgress;
  
  /// 파일 즐겨찾기 토글
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final result = await _repository.toggleFavorite(id);
      if (result.isSuccess) {
        // 로컬 상태 업데이트
        final index = _pdfFiles.indexWhere((file) => file.id == id);
        if (index != -1) {
          final updatedFile = _pdfFiles[index].copyWith(
            isFavorite: result.data!,
          );
          _pdfFiles[index] = updatedFile;
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return Result.failure(Exception('즐겨찾기 설정 실패: $e'));
    }
  }
  
  /// 파일 삭제
  Future<Result<bool>> deleteFile(String id) async {
    try {
      final result = await _repository.deleteDocument(id);
      if (result.isSuccess) {
        // 로컬 상태 업데이트
        _pdfFiles.removeWhere((file) => file.id == id);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return Result.failure(Exception('파일 삭제 실패: $e'));
    }
  }
  
  /// 마지막으로 읽은 페이지 저장
  Future<Result<void>> saveLastReadPage(String documentId, int page) async {
    try {
      final result = await _repository.saveLastReadPage(documentId, page);
      if (result.isSuccess) {
        // 로컬 상태 업데이트
        final index = _pdfFiles.indexWhere((file) => file.id == documentId);
        if (index != -1) {
          final updatedFile = _pdfFiles[index].copyWith(
            lastReadPage: page,
            updatedAt: DateTime.now(),
          );
          _pdfFiles[index] = updatedFile;
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return Result.failure(Exception('마지막 읽은 페이지 저장 실패: $e'));
    }
  }
  
  /// 마지막으로 읽은 페이지 가져오기
  Future<Result<int>> getLastReadPage(String documentId) async {
    return await _repository.getLastReadPage(documentId);
  }
  
  /// 즐겨찾기한 문서 목록 가져오기
  Future<Result<List<PDFDocument>>> getFavoriteDocuments() async {
    return await _repository.getFavoriteDocuments();
  }
  
  /// 최근 문서 목록 가져오기
  Future<Result<List<PDFDocument>>> getRecentDocuments() async {
    return await _repository.getRecentDocuments();
  }
  
  /// 문서 정보 업데이트
  Future<Result<PDFDocument>> updateDocument(PDFDocument document) async {
    try {
      final result = await _repository.updateDocument(document);
      if (result.isSuccess) {
        // 로컬 상태 업데이트
        final index = _pdfFiles.indexWhere((file) => file.id == document.id);
        if (index != -1) {
          _pdfFiles[index] = result.data!;
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return Result.failure(Exception('문서 업데이트 실패: $e'));
    }
  }
} 