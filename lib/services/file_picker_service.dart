import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../core/utils/conditional_file_picker.dart';

@singleton
class FilePickerService {
  /// PDF 파일 선택
  Future<File?> pickPDFFile() async {
    try {
      final result = await ConditionalFilePicker.pickFiles(
        type: FilePickerType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('PDF 파일 선택 실패: $e');
      return null;
    }
  }

  /// 여러 PDF 파일 선택
  Future<List<File>> pickMultiplePDFFiles() async {
    try {
      final result = await ConditionalFilePicker.pickFiles(
        type: FilePickerType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('PDF 파일 다중 선택 실패: $e');
      return [];
    }
  }

  /// 파일 저장 위치 선택
  Future<String?> getSaveLocation() async {
    try {
      final result = await ConditionalFilePicker.getDirectoryPath();
      return result;
    } catch (e) {
      debugPrint('저장 위치 선택 실패: $e');
      return null;
    }
  }
} 