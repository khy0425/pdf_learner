import 'dart:io';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

class FileUtils {
  static Future<String> getApplicationDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> getThumbnailDirectory() async {
    final appDir = await getApplicationDirectory();
    final thumbnailDir = Directory(path.join(appDir, AppConstants.thumbnailDirectory));
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    return thumbnailDir.path;
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static bool isPDFFile(String filePath) {
    return getFileExtension(filePath) == '.pdf';
  }

  static String generateThumbnailPath(String documentId) {
    return path.join(AppConstants.thumbnailDirectory, '$documentId.jpg');
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> createDirectoryIfNotExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 