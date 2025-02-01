import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFProvider extends ChangeNotifier {
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
      final fileName = file.path.split('/').last;
      final savedFile = await file.copy('${appDir.path}/$fileName');
      
      _pdfFiles.add(savedFile);
      _currentPdf = savedFile;
      
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
          .where((file) => file.path.endsWith('.pdf'))
          .map((file) => File(file.path))
          .toList();
          
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 