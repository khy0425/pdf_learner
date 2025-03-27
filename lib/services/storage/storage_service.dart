import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

/// 스토리지 서비스 인터페이스
abstract class StorageService {
  /// 파일 저장
  Future<bool> saveFile(String path, List<int> bytes);
  
  /// 파일 삭제
  Future<bool> deleteFile(String path);
  
  /// 파일 존재 여부 확인
  Future<bool> fileExists(String path);
  
  /// 파일 크기 조회
  Future<int> getFileSize(String path);
  
  /// 파일 읽기
  Future<Uint8List?> readFile(String path);
  
  /// 캐시 정리
  Future<bool> clearCache();
  
  /// 임시 파일 경로 생성
  Future<String> getTempFilePath(String fileName);
  
  /// 앱 문서 디렉토리 경로 조회
  Future<String> getDocumentsPath();
  
  /// 스토리지 사용량 조회
  Future<int> getStorageUsage();
}

/// Firebase Storage 기반 스토리지 서비스 구현체
@Injectable(as: StorageService)
class FirebaseStorageServiceImpl implements StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  @override
  Future<bool> saveFile(String path, List<int> bytes) async {
    try {
      if (path.startsWith('gs://') || path.startsWith('http')) {
        // Firebase Storage 경로인 경우
        final ref = _storage.refFromURL(path);
        await ref.putData(Uint8List.fromList(bytes));
      } else {
        // 로컬 파일 경로인 경우
        final file = File(path);
        await file.writeAsBytes(bytes);
      }
      return true;
    } catch (e) {
      debugPrint('파일 저장 오류: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteFile(String path) async {
    try {
      if (path.startsWith('gs://') || path.startsWith('http')) {
        // Firebase Storage 경로인 경우
        final ref = _storage.refFromURL(path);
        await ref.delete();
      } else {
        // 로컬 파일 경로인 경우
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      return true;
    } catch (e) {
      debugPrint('파일 삭제 오류: $e');
      return false;
    }
  }
  
  @override
  Future<bool> fileExists(String path) async {
    try {
      if (path.startsWith('gs://') || path.startsWith('http')) {
        // Firebase Storage 경로인 경우
        try {
          final ref = _storage.refFromURL(path);
          await ref.getDownloadURL();
          return true;
        } catch (_) {
          return false;
        }
      } else {
        // 로컬 파일 경로인 경우
        final file = File(path);
        return await file.exists();
      }
    } catch (e) {
      debugPrint('파일 존재 확인 오류: $e');
      return false;
    }
  }
  
  @override
  Future<int> getFileSize(String path) async {
    try {
      if (path.startsWith('gs://') || path.startsWith('http')) {
        // Firebase Storage 경로인 경우
        final ref = _storage.refFromURL(path);
        final metadata = await ref.getMetadata();
        return metadata.size ?? 0;
      } else {
        // 로컬 파일 경로인 경우
        final file = File(path);
        if (await file.exists()) {
          return await file.length();
        }
      }
      return 0;
    } catch (e) {
      debugPrint('파일 크기 조회 오류: $e');
      return 0;
    }
  }
  
  @override
  Future<Uint8List?> readFile(String path) async {
    try {
      if (path.startsWith('gs://') || path.startsWith('http')) {
        // Firebase Storage 경로인 경우
        final ref = _storage.refFromURL(path);
        final data = await ref.getData();
        return data;
      } else {
        // 로컬 파일 경로인 경우
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      debugPrint('파일 읽기 오류: $e');
      return null;
    }
  }
  
  @override
  Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('캐시 정리 오류: $e');
      return false;
    }
  }
  
  @override
  Future<String> getTempFilePath(String fileName) async {
    if (kIsWeb) {
      // 웹 환경에서는 임시 경로를 메모리 URL로 표현
      return 'memory://temp/$fileName';
    }
    
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$fileName';
  }
  
  @override
  Future<String> getDocumentsPath() async {
    if (kIsWeb) {
      // 웹 환경에서는 문서 경로를 메모리 URL로 표현
      return 'memory://documents';
    }
    
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir.path;
  }
  
  @override
  Future<int> getStorageUsage() async {
    try {
      int totalSize = 0;
      
      // 앱 문서 디렉토리 크기 계산
      final docsDir = await getApplicationDocumentsDirectory();
      totalSize += await _calculateDirSize(docsDir);
      
      // 임시 디렉토리 크기 계산
      final tempDir = await getTemporaryDirectory();
      totalSize += await _calculateDirSize(tempDir);
      
      return totalSize;
    } catch (e) {
      debugPrint('스토리지 사용량 조회 오류: $e');
      return 0;
    }
  }
  
  // 디렉토리 크기 계산 헬퍼 메서드
  Future<int> _calculateDirSize(Directory dir) async {
    int totalSize = 0;
    
    if (await dir.exists()) {
      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      } catch (e) {
        debugPrint('디렉토리 크기 계산 오류: $e');
      }
    }
    
    return totalSize;
  }
}

/// 로컬 스토리지 서비스 구현
class LocalStorageServiceImpl implements StorageService {
  @override
  Future<bool> saveFile(String path, List<int> bytes) async {
    try {
      // 로컬 스토리지 구현
      final file = File(path);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('파일 저장 실패: $e');
      return false;
    }
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    try {
      // 로컬 스토리지 구현
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('파일 읽기 실패: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      // 로컬 스토리지 구현
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('파일 삭제 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      // 로컬 스토리지 구현
      final file = File(path);
      return await file.exists();
    } catch (e) {
      debugPrint('파일 존재 확인 실패: $e');
      return false;
    }
  }

  @override
  Future<int> getFileSize(String path) async {
    try {
      // 로컬 스토리지 구현
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('파일 크기 확인 실패: $e');
      return 0;
    }
  }

  @override
  Future<bool> clearCache() async {
    try {
      // 로컬 스토리지 구현
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('캐시 정리 실패: $e');
      return false;
    }
  }
  
  @override
  Future<String> getTempFilePath(String fileName) async {
    if (kIsWeb) {
      // 웹 환경에서는 임시 경로를 메모리 URL로 표현
      return 'memory://temp/$fileName';
    }
    
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$fileName';
  }
  
  @override
  Future<String> getDocumentsPath() async {
    if (kIsWeb) {
      // 웹 환경에서는 문서 경로를 메모리 URL로 표현
      return 'memory://documents';
    }
    
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir.path;
  }
  
  @override
  Future<int> getStorageUsage() async {
    try {
      int totalSize = 0;
      
      // 앱 문서 디렉토리 크기 계산
      final docsDir = await getApplicationDocumentsDirectory();
      final dirExists = await Directory(docsDir.path).exists();
      if (dirExists) {
        await for (final entity in Directory(docsDir.path).list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('스토리지 사용량 조회 실패: $e');
      return 0;
    }
  }
} 