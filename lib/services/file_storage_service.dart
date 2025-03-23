import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) './web_path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document.dart';
import 'dart:convert';

/// 파일 스토리지 서비스
/// 파일의 저장, 로드, 삭제 등 파일 관련 작업 처리
class FileStorageService {
  static const String _documentsKey = 'pdf_documents';

  /// 앱 내부 저장소 경로 가져오기
  Future<String?> get _localPath async {
    try {
      if (kIsWeb) {
        // 웹에서는 임시 경로 반환
        return 'web_storage';
      } else {
        // 모바일에서는 앱 문서 디렉토리 사용
        final directory = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${directory.path}/pdfs');
        
        // PDF 디렉토리가 없으면 생성
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }
        
        return pdfDir.path;
      }
    } catch (e) {
      debugPrint('저장소 경로 가져오기 실패: $e');
      return null;
    }
  }

  /// URL에서 파일 저장
  Future<String?> saveFileFromUrl(String url, String fileName) async {
    if (kIsWeb) {
      // 웹에서는 URL 그대로 반환
      return url;
    }
    
    try {
      // 앱 문서 디렉토리 가져오기
      final documentsDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(documentsDir.path, 'pdfs', fileName);
      
      // 디렉토리 생성
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      return filePath;
    } catch (e) {
      debugPrint('파일 저장 중 오류 발생: $e');
      return null;
    }
  }

  /// 로컬 파일 저장 (앱 내부 저장소로 복사)
  Future<String?> saveFile(File sourceFile, String fileName) async {
    if (kIsWeb) {
      // 웹에서는 작동하지 않음
      return null;
    }
    
    try {
      // 앱 문서 디렉토리 가져오기
      final documentsDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(documentsDir.path, 'pdfs', fileName);
      
      // 디렉토리 생성
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 파일 복사
      await sourceFile.copy(filePath);
      
      return filePath;
    } catch (e) {
      debugPrint('파일 저장 중 오류 발생: $e');
      return null;
    }
  }

  /// 바이트 데이터를 파일로 저장
  Future<String?> saveBytesToFile(Uint8List bytes, String fileName) async {
    try {
      final basePath = await _localPath;
      if (basePath == null) return null;
      
      if (kIsWeb) {
        // 웹에서는 임시 경로 반환 (실제로는 IndexedDB 등 사용)
        return 'web_storage/$fileName';
      } else {
        // 모바일에서는 파일로 저장
        final filePath = path.join(basePath, fileName);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('바이트 데이터 저장 중 오류: $e');
      return null;
    }
  }

  /// 파일 삭제
  Future<bool> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 임시 구현
        return true;
      } else {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('파일 삭제 중 오류: $e');
      return false;
    }
  }

  /// 파일 존재 여부 확인
  Future<bool> fileExists(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 임시 구현
        return true;
      } else {
        final file = File(filePath);
        return await file.exists();
      }
    } catch (e) {
      debugPrint('파일 존재 확인 중 오류: $e');
      return false;
    }
  }

  /// 파일 읽기
  Future<Uint8List?> readFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 URL에서 파일 읽기 (구현 필요)
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        return null;
      } else {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
        return null;
      }
    } catch (e) {
      debugPrint('파일 읽기 중 오류: $e');
      return null;
    }
  }

  /// 바이트 배열을 파일로 저장
  Future<String?> savePdfBytes(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // 웹에서는 작동하지 않음 - 임시 URL 반환
      return 'memory://$fileName';
    }
    
    try {
      // 앱 문서 디렉토리 가져오기
      final documentsDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(documentsDir.path, 'pdfs', fileName);
      
      // 디렉토리 생성
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 파일 쓰기
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      debugPrint('바이트 배열 저장 중 오류 발생: $e');
      return null;
    }
  }

  /// 저장된 문서 목록 가져오기
  Future<List<PDFDocument>> getDocuments() async {
    try {
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지에서 문서 목록을 가져오는 대신 
        // 빈 목록 반환
        return [];
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? documentsJson = prefs.getString(_documentsKey);
      
      if (documentsJson == null || documentsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(documentsJson);
      return jsonList.map((json) => PDFDocument.fromJson(json)).toList();
    } catch (e) {
      debugPrint('문서 목록 가져오기 중 오류 발생: $e');
      return [];
    }
  }
  
  /// 문서 목록 저장
  Future<bool> saveDocuments(List<PDFDocument> documents) async {
    try {
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지 저장 생략
        return true;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String documentsJson = jsonEncode(documents.map((doc) => doc.toJson()).toList());
      
      return await prefs.setString(_documentsKey, documentsJson);
    } catch (e) {
      debugPrint('문서 목록 저장 중 오류 발생: $e');
      return false;
    }
  }
} 