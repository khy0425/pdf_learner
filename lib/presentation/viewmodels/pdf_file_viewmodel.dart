import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import '../../domain/repositories/pdf_repository.dart';
import '../../core/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/base/result.dart';
import '../../core/base/base_viewmodel.dart';
import '../../core/enums/pdf_file_status.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/services/pdf_service.dart';
import '../../services/storage/thumbnail_service.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/storage/storage_service.dart';

/// PDF 파일 관리를 위한 ViewModel
@injectable
class PdfFileViewModel extends BaseViewModel {
  final PDFRepository _repository;
  final PDFService _pdfService;
  final ThumbnailService _thumbnailService;
  final StorageService _storageService;
  List<PDFDocument> _pdfFiles = [];
  PdfFileStatus _status = PdfFileStatus.initial;
  double _downloadProgress = 0.0;
  
  // 생성자
  PdfFileViewModel({
    required PDFRepository repository,
    required PDFService pdfService,
    required ThumbnailService thumbnailService,
    required StorageService storageService,
  }) : 
    _repository = repository,
    _pdfService = pdfService,
    _thumbnailService = thumbnailService,
    _storageService = storageService {
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
        final xFile = result.getOrNull();
        
        // 파일 객체 생성
        final file = File(xFile!.path);
        
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
      
      final filePath = saveResult.data;
      
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
      
      final savedDocument = saveDocResult.data;
      
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
            isFavorite: result.data,
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
          _pdfFiles[index] = result.data;
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return Result.failure(Exception('문서 업데이트 실패: $e'));
    }
  }
  
  /// 파일 선택기를 통해 PDF 파일을 로드합니다.
  Future<Result<PDFDocument>> loadPDFFile() async {
    try {
      setLoading(true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return Result.failure(Exception('파일이 선택되지 않았습니다.'));
      }

      final file = File(result.files.first.path!);
      final fileName = path.basename(file.path);
      final fileSize = await file.length();

      // 문서 객체 생성
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        filePath: file.path,
        fileSize: fileSize,
        pageCount: await _pdfService.getPageCount(file.path),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 문서 저장
      final saveResult = await _repository.saveDocument(document);
      
      if (saveResult.isFailure) {
        return Result.failure(Exception(saveResult.error?.toString() ?? '문서 저장에 실패했습니다.'));
      }

      // 썸네일 생성
      _generateThumbnail(document.id);

      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 로드 중 오류가 발생했습니다: $e'));
    } finally {
      setLoading(false);
    }
  }
  
  /// URL에서 PDF를 다운로드합니다.
  Future<Result<PDFDocument>> downloadPDFFromUrl(String url) async {
    try {
      setLoading(true);

      // PDF 다운로드
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        return Result.failure(Exception('PDF 다운로드에 실패했습니다: ${response.statusCode}'));
      }

      // 임시 파일로 저장
      final fileName = path.basename(url);
      final tempDir = await _storageService.getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // 영구 저장소로 복사
      final docsDir = await _storageService.getDocumentsDirectory();
      final targetPath = '${docsDir.path}/pdfs/$fileName';
      final targetFile = File(targetPath);
      
      // 디렉토리가 없으면 생성
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      
      // 파일 복사
      await _storageService.copyFile(tempFile.path, targetPath);

      // 문서 객체 생성
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        filePath: targetPath,
        fileSize: await targetFile.length(),
        pageCount: await _pdfService.getPageCount(targetPath),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        downloadUrl: url,
      );

      // 문서 저장
      final saveResult = await _repository.saveDocument(document);
      
      if (saveResult.isFailure) {
        return Result.failure(Exception(saveResult.error?.toString() ?? '문서 저장에 실패했습니다.'));
      }

      // 썸네일 생성
      _generateThumbnail(document.id);

      return Result.success(document);
    } catch (e) {
      return Result.failure(Exception('PDF 다운로드 중 오류가 발생했습니다: $e'));
    } finally {
      setLoading(false);
    }
  }
  
  /// 문서의 썸네일을 생성합니다.
  Future<void> _generateThumbnail(String documentId) async {
    try {
      // 첫 페이지에 대한 썸네일 생성
      await _thumbnailService.generateThumbnail(documentId, 1);
    } catch (e) {
      print('썸네일 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 파일을 공유합니다.
  Future<Result<void>> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure(Exception('파일이 존재하지 않습니다.'));
      }
      
      // 웹에서는 다른 방식으로 공유 처리
      if (kIsWeb) {
        return Result.success(null);
      }
      
      // TODO: 공유 기능 구현
      // await Share.shareFiles([filePath]);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('파일 공유 중 오류가 발생했습니다: $e'));
    }
  }
  
  // PDF 파일 추가 메서드 (웹용)
  Future<Result<PDFDocument>> loadPdfFromDevice() async {
    try {
      setLoading(true);
      
      // 파일 선택 로직 (웹에서는 FilePicker 사용)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) {
        setLoading(false);
        return Result.failure(Exception('파일이 선택되지 않았습니다.'));
      }
      
      // 파일 정보 읽기
      final file = result.files.first;
      final bytes = file.bytes;
      final fileName = file.name;
      
      if (bytes == null) {
        setLoading(false);
        return Result.failure(Exception('파일 데이터를 읽을 수 없습니다.'));
      }
      
      // PDF 문서 객체 생성
      final id = const Uuid().v4();
      PDFDocument document = PDFDocument(
        id: id,
        title: fileName,
        fileSize: bytes.length,
        filePath: 'web_$id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PDFDocumentStatus.downloaded,
      );
      
      // 파일 저장
      final saveResult = await _repository.saveDocument(document);
      
      if (saveResult.isFailure) {
        setLoading(false);
        return Result.failure(Exception(saveResult.error?.toString() ?? '문서 저장에 실패했습니다.'));
      }
      
      // 성공 반환
      setLoading(false);
      return Result.success(document);
    } catch (e) {
      setLoading(false);
      return Result.failure(Exception('PDF 로드 중 오류가 발생했습니다: $e'));
    }
  }

  // 썸네일 생성 (매개변수 수정)
  Future<void> generateThumbnail(String documentId, String filePath) async {
    try {
      print('썸네일 생성 시작: $documentId, $filePath');
      // documentId를 문자열로, pageNumber를 1(첫 페이지)로 고정
      await _thumbnailService.generateThumbnail(documentId, 1);
    } catch (e) {
      debugPrint('썸네일 생성 중 오류: $e');
    }
  }
} 