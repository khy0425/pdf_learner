import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_document.dart';

/// PDF 문서 관리를 위한 뷰모델
class PdfViewModel extends ChangeNotifier {
  /// 현재 로드된 PDF 문서 목록
  List<PdfDocument> _documents = [];
  
  /// 현재 선택된 PDF 문서
  PdfDocument? _selectedDocument;
  
  /// 문서 열기 상태 추적
  bool _isLoading = false;
  String? _error;
  
  /// 게터
  List<PdfDocument> get documents => _documents;
  PdfDocument? get selectedDocument => _selectedDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDocuments => _documents.isNotEmpty;
  
  /// 로컬 스토리지에서 모든 PDF 불러오기
  Future<void> loadDocuments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/pdfs');
      
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final files = await documentsDir.list().where((file) => file.path.endsWith('.pdf')).toList();
      final metadataFiles = await documentsDir.list().where((file) => file.path.endsWith('.metadata')).toList();
      
      _documents = [];
      
      for (var file in files) {
        final fileName = file.path.split('/').last;
        final id = fileName.replaceAll('.pdf', '');
        
        // 메타데이터 파일 찾기
        final metadataFile = metadataFiles.firstWhere(
          (f) => f.path.contains(id) && f.path.endsWith('.metadata'),
          orElse: () => File(''),
        );
        
        if (metadataFile.path.isNotEmpty) {
          final metadataString = await File(metadataFile.path).readAsString();
          final metadata = jsonDecode(metadataString);
          
          _documents.add(PdfDocument(
            id: id,
            title: metadata['title'] ?? fileName,
            path: file.path,
            size: await File(file.path).length(),
            pageCount: metadata['pageCount'] ?? 0,
            lastOpened: DateTime.parse(metadata['lastOpened'] ?? DateTime.now().toIso8601String()),
            createdAt: DateTime.parse(metadata['createdAt'] ?? DateTime.now().toIso8601String()),
          ));
        } else {
          // 메타데이터 없는 경우 기본값으로 생성
          _documents.add(PdfDocument(
            id: id,
            title: fileName,
            path: file.path,
            size: await File(file.path).length(),
            pageCount: 0,
            lastOpened: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
      
      // 최근에 열어본 순으로 정렬
      _documents.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    } catch (e) {
      _error = '문서를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// PDF 문서 선택
  void selectDocument(String id) {
    _selectedDocument = _documents.firstWhere((doc) => doc.id == id);
    // 마지막 열람 시간 업데이트
    _selectedDocument = _selectedDocument!.copyWith(lastOpened: DateTime.now());
    _updateDocumentMetadata(_selectedDocument!);
    notifyListeners();
  }
  
  /// PDF 문서 추가 (파일 선택 다이얼로그 통해)
  Future<void> addDocumentFromPicker() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // 웹에서는 bytes로 처리
          if (file.bytes != null) {
            await _saveDocument(file.name, file.bytes!);
          }
        } else {
          // 모바일/데스크톱에서는 path로 처리
          if (file.path != null) {
            final fileBytes = await File(file.path!).readAsBytes();
            await _saveDocument(file.name, fileBytes);
          }
        }
      }
    } catch (e) {
      _error = '문서 추가 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// PDF 문서 저장
  Future<void> _saveDocument(String fileName, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${directory.path}/pdfs');
    
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    
    final id = const Uuid().v4();
    final filePath = '${documentsDir.path}/$id.pdf';
    final metadataPath = '${documentsDir.path}/$id.metadata';
    
    // PDF 파일 저장
    await File(filePath).writeAsBytes(bytes);
    
    // 메타데이터 생성 및 저장
    final document = PdfDocument(
      id: id,
      title: fileName,
      path: filePath,
      size: bytes.length,
      pageCount: 0, // TODO: PDF 페이지 수 계산 로직 추가
      lastOpened: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await _updateDocumentMetadata(document);
    
    _documents.add(document);
    _selectedDocument = document;
    notifyListeners();
  }
  
  /// 문서 메타데이터 업데이트
  Future<void> _updateDocumentMetadata(PdfDocument document) async {
    final metadataPath = document.path.replaceAll('.pdf', '.metadata');
    
    final metadata = {
      'title': document.title,
      'pageCount': document.pageCount,
      'lastOpened': document.lastOpened.toIso8601String(),
      'createdAt': document.createdAt.toIso8601String(),
    };
    
    await File(metadataPath).writeAsString(jsonEncode(metadata));
    
    // 문서 목록에서 해당 문서 업데이트
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index >= 0) {
      _documents[index] = document;
    }
  }
  
  /// 문서 삭제
  Future<void> deleteDocument(String id) async {
    try {
      final document = _documents.firstWhere((doc) => doc.id == id);
      
      // PDF 파일 삭제
      await File(document.path).delete();
      
      // 메타데이터 파일 삭제
      final metadataPath = document.path.replaceAll('.pdf', '.metadata');
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      
      // 목록에서 제거
      _documents.removeWhere((doc) => doc.id == id);
      
      // 선택된 문서가 삭제된 경우 null로 설정
      if (_selectedDocument?.id == id) {
        _selectedDocument = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = '문서 삭제 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }
} 