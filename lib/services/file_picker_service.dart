import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 파일 선택 결과
class FilePickerResult {
  /// 파일 경로 (네이티브 앱에서 사용)
  final String? path;
  
  /// 파일 이름
  final String name;
  
  /// 파일 바이트 (웹에서 사용)
  final Uint8List? bytes;
  
  /// 생성자
  FilePickerResult({
    this.path,
    required this.name,
    this.bytes,
  });
}

/// 파일 선택 관련 기능을 제공하는 서비스
class FilePickerService {
  /// PDF 파일 선택
  /// 
  /// [withData]를 true로 설정하면 웹에서 바이트 데이터를 포함합니다.
  /// 
  /// 반환값: 
  /// - 모바일: 선택한 파일의 파일 객체 또는 취소 시 null
  /// - 웹: [PlatformFile] 객체 또는 취소 시 null
  Future<dynamic> pickPdfFile({bool withData = false}) async {
    try {
      // 파일 선택기 옵션 설정
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb || withData,
      );
      
      // 선택 취소 시 null 반환
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      final file = result.files.first;
      
      // 웹에서는 PlatformFile 반환
      if (kIsWeb) {
        return file;
      }
      
      // 모바일에서는 File 객체 반환
      return File(file.path!);
    } catch (e) {
      debugPrint('파일 선택 중 오류 발생: $e');
      return null;
    }
  }
  
  /// 웹용 - 선택한 파일의 바이트 데이터 및 이름 추출
  FileDetails? getFileDetailsFromPlatformFile(PlatformFile file) {
    if (file.bytes == null) {
      return null;
    }
    
    return FileDetails(
      bytes: file.bytes!,
      name: file.name,
      size: file.size,
    );
  }
  
  /// 여러 PDF 파일 선택 
  Future<List<Map<String, dynamic>>?> pickMultiplePdfFiles() async {
    try {
      // 파일 피커 옵션 설정
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      
      // 사용자가 파일 선택을 취소한 경우
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      // 선택된 파일들의 정보를 리스트로 변환
      final files = <Map<String, dynamic>>[];
      
      for (final platformFile in result.files) {
        // 웹 환경과 모바일 환경 분기 처리
        if (kIsWeb) {
          // 웹에서는 바이트 데이터와 파일 이름 추가
          if (platformFile.bytes != null) {
            files.add({
              'isWeb': true,
              'bytes': platformFile.bytes!,
              'name': platformFile.name,
            });
          }
        } else {
          // 모바일에서는 File 객체 추가
          if (platformFile.path != null) {
            files.add({
              'isWeb': false,
              'file': File(platformFile.path!),
              'name': platformFile.name,
            });
          }
        }
      }
      
      return files.isNotEmpty ? files : null;
    } catch (e) {
      debugPrint('다중 파일 선택 중 오류 발생: $e');
      return null;
    }
  }

  /// PDF 파일 선택
  Future<FilePickerResult?> pickPdf() async {
    try {
      // FilePicker를 사용하여 PDF 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // 웹에서는 바이트 데이터 필요
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // 결과 객체 생성
      return FilePickerResult(
        path: file.path,
        name: file.name,
        bytes: file.bytes,
      );
    } catch (e) {
      debugPrint('파일 선택 중 오류 발생: $e');
      return null;
    }
  }
  
  /// 이미지 파일 선택
  Future<FilePickerResult?> pickImage() async {
    try {
      // FilePicker를 사용하여 이미지 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb, // 웹에서는 바이트 데이터 필요
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // 결과 객체 생성
      return FilePickerResult(
        path: file.path,
        name: file.name,
        bytes: file.bytes,
      );
    } catch (e) {
      debugPrint('이미지 파일 선택 중 오류 발생: $e');
      return null;
    }
  }
  
  /// 여러 파일 선택
  Future<List<FilePickerResult>> pickMultipleFiles() async {
    try {
      // FilePicker를 사용하여 여러 파일 선택
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb, // 웹에서는 바이트 데이터 필요
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // 각 파일에 대한 결과 객체 생성
      return result.files.map((file) {
        return FilePickerResult(
          path: file.path,
          name: file.name,
          bytes: file.bytes,
        );
      }).toList();
    } catch (e) {
      debugPrint('여러 파일 선택 중 오류 발생: $e');
      return [];
    }
  }
}

/// 파일 세부 정보 클래스
class FileDetails {
  final Uint8List bytes;
  final String name;
  final int size;
  
  FileDetails({
    required this.bytes,
    required this.name,
    required this.size,
  });
} 