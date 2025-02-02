import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class PDFProvider with ChangeNotifier {
  List<File> _pdfFiles = [];
  File? _currentPdf;
  bool _isLoading = false;

  List<File> get pdfFiles => _pdfFiles;
  File? get currentPdf => _currentPdf;
  bool get isLoading => _isLoading;

  Future<void> addPDF(File file) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 앱 문서 디렉토리에 PDF 파일 복사
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(file.path); // 파일 이름만 추출
      final savedFile = await file.copy(path.join(appDir.path, fileName)); // 경로 올바르게 결합
      
      _pdfFiles.add(savedFile);
      _currentPdf = savedFile;
      
    } catch (e) {
      debugPrint('PDF 파일 추가 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentPDF(File file) {
    _currentPdf = file;
    notifyListeners();
  }

  // 저장된 PDF 파일들 로드
  Future<void> loadSavedPDFs() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();
      _pdfFiles = files
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .map((file) => File(file.path))
          .toList();
          
    } catch (e) {
      debugPrint('PDF 파일 로드 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePDF(File file) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await file.delete();
      _pdfFiles.remove(file);
      
      if (_currentPdf == file) {
        _currentPdf = null;
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      await addPDF(file);
    }
  }
} 