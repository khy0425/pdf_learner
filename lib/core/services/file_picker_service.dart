import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

@singleton
class FilePickerService {
  /// PDF 파일 선택
  Future<File?> pickPDFFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
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
      print('PDF 파일 선택 실패: $e');
      return null;
    }
  }

  /// 여러 PDF 파일 선택
  Future<List<File>> pickMultiplePDFFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
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
      print('PDF 파일 다중 선택 실패: $e');
      return [];
    }
  }

  /// 파일 저장 위치 선택
  Future<String?> getSaveLocation() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    } catch (e) {
      print('저장 위치 선택 실패: $e');
      return null;
    }
  }
} 