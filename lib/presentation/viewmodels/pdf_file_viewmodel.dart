import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pdf_file_info.dart';
import '../services/storage_service.dart';
import '../repositories/pdf_repository.dart';
import '../../core/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../core/base/result.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/enums/pdf_file_status.dart';
import 'package:cross_file/cross_file.dart';

/// PDF 파일 관리를 위한 ViewModel
class PdfFileViewModel extends BaseViewModel {
  final PDFRepository _repository;
  List<PdfFileInfo> _pdfFiles = [];
  PdfFileStatus _status = PdfFileStatus.initial;
  double _downloadProgress = 0.0;
  
  // 생성자
  PdfFileViewModel({required PDFRepository repository}) : _repository = repository {
    _loadFiles();
  }
  
  // 게터
  List<PdfFileInfo> get pdfFiles => _pdfFiles;
  PdfFileStatus get status => _status;
  
  /// 선택된 파일
  PdfFileInfo? get selectedFile => _pdfFiles.isNotEmpty
      ? _pdfFiles.firstWhere((file) => file.isSelected, orElse: () => _pdfFiles.first)
      : null;
  
  // PDF 파일 목록 불러오기
  Future<void> _loadFiles() async {
    try {
      _setStatus(PdfFileStatus.loading);
      
      final files = await _repository.getPdfFiles();
      _pdfFiles = files;
      
      _setStatus(PdfFileStatus.success);
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
        
        // XFile에서 데이터 읽기
        final Uint8List fileData = await xFile.readAsBytes();
        final int fileSize = fileData.length;
        
        // PDF 정보 생성
        final pdfInfo = PdfFileInfo(
          id: '',  // 아이디는 저장 과정에서 생성됨
          userId: userId,
          fileName: xFile.name,
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
        
        _setStatus(PdfFileStatus.success);
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
  Future<Result<PdfFileInfo>> downloadPdf(String url, String title, {Map<String, dynamic>? metadata}) async {
    _setStatus(PdfFileStatus.downloading);
    _downloadProgress = 0.0;
    notifyListeners();
    
    try {
      final result = await _repository.downloadPdf(url);
      
      if (result.isSuccess) {
        final filePath = result.getOrNull();
        if (filePath != null && filePath.isNotEmpty) {
          final file = File(filePath);
          
          // 저장 경로 생성
          final appDir = await getApplicationDocumentsDirectory();
          final pdfDir = Directory('${appDir.path}/pdfs');
          if (!await pdfDir.exists()) {
            await pdfDir.create(recursive: true);
          }
          
          // 파일명 생성
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
          final savedPath = '${pdfDir.path}/$fileName';
          
          // 파일 복사
          await file.copy(savedPath);
          
          // 메타데이터 생성
          final pdfInfo = PdfFileInfo(
            id: const Uuid().v4(),
            title: title,
            filePath: savedPath,
            downloadUrl: url,
            lastAccessed: DateTime.now(),
            addedDate: DateTime.now(),
            metadata: metadata ?? {},
            isFavorite: false,
          );
          
          // 파일 정보 저장
          await _repository.saveFileInfo(pdfInfo);
          
          // 목록 갱신
          await _loadFiles();
          
          _setStatus(PdfFileStatus.success);
          return Result.success(pdfInfo);
        }
      }
      
      _setStatus(PdfFileStatus.error);
      return Result.failure(result.error ?? Exception('파일 다운로드 실패'));
    } catch (e) {
      _setStatus(PdfFileStatus.error);
      return Result.failure(e);
    }
  }
  
  /// 다운로드 진행 상태 업데이트
  void updateDownloadProgress(double progress) {
    _downloadProgress = progress;
    notifyListeners();
  }
  
  /// 다운로드 진행 상태 가져오기
  double get downloadProgress => _downloadProgress;
} 