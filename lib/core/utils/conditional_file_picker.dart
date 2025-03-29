import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

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

/// 웹 환경과 모바일 환경에서 다르게 동작하는 파일 선택기
class ConditionalFilePicker {
  static const MethodChannel _channel = MethodChannel('com.example.pdf_learner_v2/file_picker');
  
  /// FilePickerType을 file_picker.FileType으로 변환
  static file_picker.FileType _convertFileType(FilePickerType type) {
    switch (type) {
      case FilePickerType.any:
        return file_picker.FileType.any;
      case FilePickerType.image:
        return file_picker.FileType.image;
      case FilePickerType.video:
        return file_picker.FileType.video;
      case FilePickerType.audio:
        return file_picker.FileType.audio;
      case FilePickerType.media:
        return file_picker.FileType.media;
      case FilePickerType.custom:
        return file_picker.FileType.custom;
      default:
        return file_picker.FileType.any;
    }
  }
  
  /// 단일 파일 선택
  static Future<file_picker.FilePickerResult?> pickFile({
    String dialogTitle = '파일 선택',
    FilePickerType type = FilePickerType.any,
    List<String>? allowedExtensions,
  }) async {
    return await file_picker.FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: _convertFileType(type),
      allowedExtensions: type == FilePickerType.custom ? allowedExtensions : null,
      allowMultiple: false,
    );
  }
  
  /// 다중 파일 선택
  static Future<file_picker.FilePickerResult?> pickFiles({
    String dialogTitle = '파일 선택',
    FilePickerType type = FilePickerType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    return await file_picker.FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: _convertFileType(type),
      allowedExtensions: type == FilePickerType.custom ? allowedExtensions : null,
      allowMultiple: kIsWeb ? allowMultiple : false,  // 웹에서는 여러 파일 허용, 모바일에서는 단일 파일
    );
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