import 'package:flutter/foundation.dart';
import 'dart:io';

class PDFProvider extends ChangeNotifier {
  List<File> _pdfFiles = [];
  File? _currentPdf;

  List<File> get pdfFiles => _pdfFiles;
  File? get currentPdf => _currentPdf;

  void addPDF(File file) {
    _pdfFiles.add(file);
    notifyListeners();
  }

  void setCurrentPDF(File file) {
    _currentPdf = file;
    notifyListeners();
  }
} 