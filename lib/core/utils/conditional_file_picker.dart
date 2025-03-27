import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:flutter/services.dart';

/// 파일 피커 타입
enum FilePickerType {
  any,
  image,
  video,
  audio,
  media,
  custom
}

/// 파일 피커 결과
class FilePickerResult {
  final List<PlatformFile> files;
  
  FilePickerResult(this.files);
  
  bool get isSinglePick => files.length == 1;
}

/// 플랫폼 파일 정보
class PlatformFile {
  final String name;
  final String? path;
  final int size;
  final Uint8List? bytes;
  final String? extension;
  final String? uri;
  
  PlatformFile({
    required this.name,
    this.path,
    required this.size,
    this.bytes,
    this.extension,
    this.uri,
  });
  
  /// 파일이 유효한지 확인
  bool get isValid => size > 0 && (bytes != null || path != null);
  
  /// 파일 확장자가 PDF인지 확인
  bool get isPdf => extension?.toLowerCase() == 'pdf';
  
  /// 파일 크기가 허용 범위 내인지 확인 (기본 10MB)
  bool isSizeAllowed([int maxSize = 10 * 1024 * 1024]) => size <= maxSize;
}

/// 플랫폼에 따라 적절한 파일 선택 기능을 제공하는 클래스
class ConditionalFilePicker {
  static const MethodChannel _channel = MethodChannel('com.example.pdf_learner_v2/file_picker');
  
  /// 파일 선택 메서드
  static Future<FilePickerResult?> pickFiles({
    FilePickerType type = FilePickerType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = true,
    int maxFileSize = 10 * 1024 * 1024, // 10MB
  }) async {
    try {
      if (kIsWeb) {
        return await _pickFilesWeb(type, allowedExtensions, allowMultiple, maxFileSize);
      } else {
        return await _pickFilesNative(type, allowedExtensions, allowMultiple);
      }
    } catch (e) {
      debugPrint('파일 선택 오류: $e');
      return null;
    }
  }
  
  /// 웹 환경에서 파일 선택
  static Future<FilePickerResult?> _pickFilesWeb(
    FilePickerType type,
    List<String>? allowedExtensions,
    bool allowMultiple,
    int maxFileSize,
  ) async {
    try {
      final html.FileUploadInputElement input = html.FileUploadInputElement();
      
      // 허용할 파일 형식 설정
      String accept = '';
      if (type == FilePickerType.image) {
        accept = 'image/*';
      } else if (type == FilePickerType.video) {
        accept = 'video/*';
      } else if (type == FilePickerType.audio) {
        accept = 'audio/*';
      } else if (type == FilePickerType.custom && allowedExtensions != null) {
        accept = allowedExtensions.map((ext) => '.$ext').join(',');
      }
      
      input.accept = accept;
      input.multiple = allowMultiple;
      input.click();
      
      final files = await input.onChange.first.then((_) => input.files);
      if (files == null || files.isEmpty) return null;
      
      List<PlatformFile> platformFiles = [];
      
      for (var file in files) {
        // 파일 크기 체크
        if (file.size > maxFileSize) {
          debugPrint('파일 크기 초과: ${file.name} (${file.size} bytes)');
          continue;
        }
        
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        
        final data = await reader.onLoad.first;
        final bytes = (reader.result as Uint8List?);
        
        final name = file.name;
        final size = file.size;
        final extension = name.split('.').last;
        
        platformFiles.add(PlatformFile(
          name: name,
          size: size,
          bytes: bytes,
          extension: extension,
        ));
      }
      
      return FilePickerResult(platformFiles);
    } catch (e) {
      debugPrint('웹 파일 선택 오류: $e');
      return null;
    }
  }
  
  /// 네이티브 환경에서 파일 선택
  static Future<FilePickerResult?> _pickFilesNative(
    FilePickerType type,
    List<String>? allowedExtensions,
    bool allowMultiple,
  ) async {
    try {
      // 네이티브 플랫폼에 파일 선택 요청
      final result = await _channel.invokeMethod('pickFiles', {
        'type': type.toString(),
        'allowedExtensions': allowedExtensions,
        'allowMultiple': allowMultiple,
      });
      
      if (result == null) return null;
      
      // 결과를 PlatformFile 리스트로 변환
      final List<dynamic> files = result as List<dynamic>;
      final List<PlatformFile> platformFiles = [];
      
      for (var file in files) {
        final Map<String, dynamic> fileData = file as Map<String, dynamic>;
        
        platformFiles.add(PlatformFile(
          name: fileData['name'] as String,
          path: fileData['path'] as String?,
          size: fileData['size'] as int,
          extension: fileData['extension'] as String?,
          uri: fileData['uri'] as String?,
        ));
      }
      
      return FilePickerResult(platformFiles);
    } catch (e) {
      debugPrint('네이티브 파일 선택 오류: $e');
      return null;
    }
  }
  
  /// 디렉토리 경로 선택
  static Future<String?> getDirectoryPath() async {
    try {
      if (kIsWeb) {
        return null; // 웹에서는 디렉토리 선택을 지원하지 않음
      } else {
        // 네이티브 플랫폼에 디렉토리 선택 요청
        final result = await _channel.invokeMethod('getDirectoryPath', {});
        return result as String?;
      }
    } catch (e) {
      debugPrint('디렉토리 선택 오류: $e');
      return null;
    }
  }
}

/// 플랫폼 독립적인 파일 결과 클래스
class FileResult {
  final String name;
  final int size;
  final String? path;
  final List<int>? bytes;
  final String extension;
  
  const FileResult({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
    required this.extension,
  });
  
  /// 파일이 유효한지 확인
  bool get isValid => bytes != null && bytes!.isNotEmpty;
  
  /// 파일 확장자가 PDF인지 확인
  bool get isPdf => extension.toLowerCase() == 'pdf';
  
  /// 파일 생성 (네이티브 환경에서만 사용 가능)
  Future<File?> toFile() async {
    if (kIsWeb || path == null) return null;
    return File(path!);
  }
} 