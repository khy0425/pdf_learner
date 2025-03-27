import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/result.dart';

/// 파일 관련 유틸리티 클래스
class FileUtils {
  /// PDF 파일 선택 다이얼로그 표시
  static Future<Result<XFile?>> pickPdfFile(BuildContext context) async {
    try {
      if (kIsWeb) {
        // 웹에서는 간단한 처리
        final result = await showDialog<Result<XFile?>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF 파일 기능 알림'),
            content: const Text('웹 환경에서는 로컬 PDF 파일 업로드가 제한되어 있습니다. 대신 URL을 통해 파일을 추가해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, Result.success(null)),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        
        return result ?? Result.success(null);
      } else {
        // 모바일에서는 커스텀 파일 선택 다이얼로그 표시
        return _pickPdfFileNative(context);
      }
    } catch (e) {
      return Result.failure(Exception('파일 선택 중 오류가 발생했습니다: $e'));
    }
  }
  
  /// 모바일에서 PDF 파일 선택 (XFile 반환)
  static Future<Result<XFile?>> _pickPdfFileNative(BuildContext context) async {
    try {
      // 모바일 전용 코드
      // 파일 선택 다이얼로그 구현
      final selectedFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF 파일을 선택하세요'),
          content: const Text('파일 선택 기능은 아직 구현되지 않았습니다'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      );
      
      return Result.success(selectedFile);
    } catch (e) {
      return Result.failure(Exception('네이티브 파일 선택 중 오류: $e'));
    }
  }
  
  /// 바이트를 사람이 읽을 수 있는 파일 크기 문자열로 변환합니다.
  static String getFileSizeString(int bytes) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    
    return ((bytes / math.pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
  
  /// URL에서 파일 다운로드
  static Future<Result<String>> downloadFile(String url, String filename) async {
    if (url.isEmpty || url.trim().isEmpty) {
      return Result.failure('다운로드할 URL이 비어 있습니다.');
    }

    try {
      // HTTP 요청으로 파일 다운로드
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        if (kIsWeb) {
          // 웹에서는 다운로드 제한 메시지 반환
          return Result.failure('브라우저 제한으로 인해 다운로드 완료 후 별도 저장이 필요합니다.');
        } else {
          // 모바일/데스크톱에서는 파일로 저장
          final directory = await getTemporaryDirectory();
          final filePath = path.join(directory.path, filename);
          
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          
          return Result.success(filePath);
        }
      } else {
        return Result.failure(
          '파일 다운로드 실패: HTTP 상태 코드 ${response.statusCode}',
        );
      }
    } catch (e) {
      return Result.failure('파일 다운로드 중 오류: $e');
    }
  }
  
  /// 디렉토리에서 PDF 파일만 필터링하여 가져오기
  static Future<List<FileSystemEntity>> getPdfFiles(String directory) async {
    try {
      if (kIsWeb) {
        // 웹에서는 빈 리스트 반환
        return [];
      } else {
        final dir = Directory(directory);
        
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          return [];
        }
        
        return dir
            .listSync()
            .where((entity) => 
                entity is File && 
                path.extension(entity.path).toLowerCase() == '.pdf')
            .toList();
      }
    } catch (e) {
      debugPrint('PDF 파일 검색 중 오류: $e');
      return [];
    }
  }
  
  /// 파일의 MIME 타입 가져오기
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }
  
  /// PDF 파일인지 확인
  static bool isPdfFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.pdf';
  }
  
  /// 파일 존재 여부 확인
  static Future<bool> fileExists(String filePath) async {
    if (kIsWeb) {
      return false;
    } else {
      return File(filePath).exists();
    }
  }
  
  /// 파일 크기 가져오기
  static Future<int> getFileSize(String filePath) async {
    if (kIsWeb) {
      return 0;
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    }
  }
} 