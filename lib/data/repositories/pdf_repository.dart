import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_document.dart';
import '../services/file_storage_service.dart';
import '../services/thumbnail_service.dart';
import '../utils/web_utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'pdf_document_repository.dart';
import 'pdf_storage_repository.dart';
import 'pdf_thumbnail_repository.dart';
import 'pdf_bookmark_repository.dart';
import 'pdf_web_repository.dart';

/// PDF 저장소
class PDFRepository {
  final PDFDocumentRepository _documentRepository;
  final PDFStorageRepository _storageRepository;
  final PDFThumbnailRepository _thumbnailRepository;
  final PDFBookmarkRepository _bookmarkRepository;
  final PDFWebRepository _webRepository;
  
  PDFRepository({
    required FileStorageService storageService,
    required ThumbnailService thumbnailService,
  }) : _documentRepository = PDFDocumentRepository(storageService: storageService),
       _storageRepository = PDFStorageRepository(storageService: storageService),
       _thumbnailRepository = PDFThumbnailRepository(
         storageService: storageService,
         thumbnailService: thumbnailService,
       ),
       _bookmarkRepository = PDFBookmarkRepository(storageService: storageService),
       _webRepository = PDFWebRepository();
  
  /// 문서 목록 스트림
  Stream<List<PDFDocument>> get documentsStream => _documentRepository.documentsStream;
  
  /// 문서 목록
  List<PDFDocument> get documents => _documentRepository.documents;
  
  /// 문서 목록 로드
  Future<List<PDFDocument>> loadDocuments() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 로드
        final webDocuments = await _webRepository._loadDocumentsFromWebStorage();
        
        if (webDocuments.isNotEmpty) {
          _documentRepository._documents = webDocuments;
        } else {
          // 웹 스토리지에 문서가 없으면 샘플 문서 로드
          _documentRepository._documents = await _webRepository._getWebSampleDocuments();
          // 샘플 문서를 로컬 스토리지에 저장
          await _webRepository._saveDocumentsToWebStorage(_documentRepository._documents);
        }
      } else {
        // 네이티브 환경에서는 파일 시스템에서 로드
        _documentRepository._documents = await _storageRepository.getDocuments();
      }
      
      _documentRepository._notifyDocumentsChanged();
      debugPrint('문서 목록 로드됨: ${_documentRepository._documents.length}개의 문서');
      return _documentRepository._documents;
    } catch (e) {
      debugPrint('문서 목록 로드 중 오류: $e');
      _documentRepository._documents = [];
      return [];
    }
  }
  
  /// URL에서 문서 추가
  Future<PDFDocument?> addDocumentFromUrl(String url, String title) async {
    try {
      if (kIsWeb) {
        return await _webRepository.addDocumentFromUrl(url, title);
      }
      
      final filePath = await _storageRepository.downloadAndSaveFromUrl(url, title);
      if (filePath == null) return null;
      
      final bytes = await _storageRepository.downloadPdfAsBytes(filePath);
      final thumbnailPath = await _thumbnailRepository.generateThumbnail(bytes, filePath);
      
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: filePath,
        thumbnailPath: thumbnailPath ?? '',
        totalPages: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        bookmarks: [],
      );
      
      return document;
    } catch (e) {
      debugPrint('URL에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 파일에서 문서 추가
  Future<PDFDocument?> addDocumentFromFile(File file, String title) async {
    try {
      if (kIsWeb) return null;
      
      final filePath = await _storageRepository.saveFromFile(file, title);
      if (filePath == null) return null;
      
      final bytes = await _storageRepository.downloadPdfAsBytes(filePath);
      final thumbnailPath = await _thumbnailRepository.generateThumbnail(bytes, filePath);
      
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: filePath,
        thumbnailPath: thumbnailPath ?? '',
        totalPages: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        bookmarks: [],
      );
      
      return document;
    } catch (e) {
      debugPrint('파일에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 바이트 데이터에서 PDF 추가
  Future<PDFDocument?> addDocumentFromBytes(Uint8List bytes, String title) async {
    try {
      if (kIsWeb) {
        return await _webRepository.addDocumentFromBytes(bytes, title);
      }
      
      final filePath = await _storageRepository.saveFromBytes(bytes, title);
      if (filePath == null) return null;
      
      final thumbnailPath = await _thumbnailRepository.generateThumbnail(bytes, filePath);
      
      final document = PDFDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: filePath,
        thumbnailPath: thumbnailPath ?? '',
        totalPages: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        bookmarks: [],
      );
      
      return document;
    } catch (e) {
      debugPrint('바이트에서 문서 추가 오류: $e');
      return null;
    }
  }
  
  /// 문서 삭제
  Future<bool> deleteDocument(PDFDocument document) async {
    try {
      if (kIsWeb) {
        return await _webRepository.deleteDocument(document);
      }
      
      // 파일 삭제
      await _storageRepository.deleteFile(document.filePath);
      
      // 썸네일 삭제
      if (document.thumbnailPath.isNotEmpty) {
        await _thumbnailRepository.deleteThumbnail(document.thumbnailPath);
      }
      
      // 북마크 삭제
      await _bookmarkRepository.deleteBookmark(document, document.id);
      
      return true;
    } catch (e) {
      debugPrint('문서 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 문서 업데이트
  Future<bool> updateDocument(PDFDocument document) async {
    return await _documentRepository.updateDocument(document);
  }
  
  /// ID로 문서 검색
  Future<PDFDocument?> getDocumentById(String documentId) async {
    return await _documentRepository.getDocumentById(documentId);
  }
  
  /// 북마크 추가
  Future<bool> addBookmark(PDFDocument document, bookmark.PDFBookmark bookmark) async {
    return await _bookmarkRepository.addBookmark(document, bookmark);
  }
  
  /// 북마크 삭제
  Future<bool> deleteBookmark(PDFDocument document, String bookmarkId) async {
    return await _bookmarkRepository.deleteBookmark(document, bookmarkId);
  }
  
  /// 북마크 업데이트
  Future<bool> updateBookmark(PDFDocument document, bookmark.PDFBookmark bookmark) async {
    return await _bookmarkRepository.updateBookmark(document, bookmark);
  }
  
  /// 북마크 목록 가져오기
  List<bookmark.PDFBookmark> getBookmarks(PDFDocument document) {
    return _bookmarkRepository.getBookmarks(document);
  }
  
  /// 북마크 로드
  Future<List<bookmark.PDFBookmark>> loadBookmarks(PDFDocument document) async {
    return await _bookmarkRepository.loadBookmarks(document);
  }
  
  /// 리소스 해제
  void dispose() {
    _documentRepository.dispose();
  }
} 