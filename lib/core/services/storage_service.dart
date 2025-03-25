import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@injectable
class StorageService {
  final SharedPreferences _prefs;
  static const String _lastOpenedPageKey = 'last_opened_page_';
  static const String _lastOpenedDocumentKey = 'last_opened_document';
  static const String _themeKey = 'theme';
  static const String _languageKey = 'language';
  static const String _fontSizeKey = 'font_size';
  static const String _lineHeightKey = 'line_height';

  StorageService(this._prefs);

  // PDF 관련 메서드
  Future<int?> getLastOpenedPage(String filePath) async {
    return _prefs.getInt('$_lastOpenedPageKey$filePath');
  }

  Future<void> setLastOpenedPage(String filePath, int page) async {
    await _prefs.setInt('$_lastOpenedPageKey$filePath', page);
  }

  Future<String?> getLastOpenedDocument() async {
    return _prefs.getString(_lastOpenedDocumentKey);
  }

  Future<void> setLastOpenedDocument(String documentId) async {
    await _prefs.setString(_lastOpenedDocumentKey, documentId);
  }

  // 설정 관련 메서드
  Future<String> getTheme() async {
    return _prefs.getString(_themeKey) ?? 'light';
  }

  Future<void> setTheme(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  Future<String> getLanguage() async {
    return _prefs.getString(_languageKey) ?? 'ko';
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  Future<double> getFontSize() async {
    return _prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  Future<double> getLineHeight() async {
    return _prefs.getDouble(_lineHeightKey) ?? 1.5;
  }

  Future<void> setLineHeight(double height) async {
    await _prefs.setDouble(_lineHeightKey, height);
  }

  // 파일 관련 메서드
  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> getPDFPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/pdfs/$fileName';
  }

  Future<void> createPDFDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${directory.path}/pdfs');
    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }
  }

  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> copyFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    final destinationFile = File(destinationPath);
    await sourceFile.copy(destinationPath);
  }

  Future<void> moveFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    await sourceFile.rename(destinationPath);
  }

  // 캐시 관련 메서드
  Future<void> clearCache() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${directory.path}/cache');
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    await clearCache();
  }
} 