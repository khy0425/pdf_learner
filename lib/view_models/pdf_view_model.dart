import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/pdf_model.dart';
import '../models/user_model.dart';
import '../repositories/pdf_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_key_service.dart';

/// PDF 관련 비즈니스 로직을 담당하는 ViewModel 클래스
class PdfViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final UserRepository _userRepository;
  final ApiKeyService _apiKeyService;
  
  List<PdfModel> _pdfs = [];
  PdfModel? _selectedPdf;
  bool _isLoading = false;
  String? _error;
  
  /// 현재 사용자의 PDF 목록
  List<PdfModel> get pdfs => _pdfs;
  
  /// 현재 선택된 PDF
  PdfModel? get selectedPdf => _selectedPdf;
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 오류 메시지
  String? get error => _error;
  
  PdfViewModel({
    PdfRepository? pdfRepository,
    UserRepository? userRepository,
    ApiKeyService? apiKeyService,
  }) : _pdfRepository = pdfRepository ?? PdfRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _apiKeyService = apiKeyService ?? ApiKeyService();
  
  /// 사용자의 PDF 목록 로드
  Future<void> loadPdfs(String userId) async {
    try {
      _setLoading(true);
      
      final pdfs = await _pdfRepository.getPdfs(userId);
      _pdfs = pdfs;
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 선택
  void selectPdf(PdfModel pdf) {
    _selectedPdf = pdf;
    notifyListeners();
  }
  
  /// PDF 데이터 가져오기
  Future<Uint8List?> getPdfData(String pdfId) async {
    try {
      final pdf = _pdfs.firstWhere((pdf) => pdf.id == pdfId);
      
      if (pdf.url != null) {
        // URL에서 PDF 데이터 가져오기
        final response = await http.get(Uri.parse(pdf.url!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('PDF 다운로드 실패: ${response.statusCode}');
        }
      } else if (pdf.localPath != null) {
        // 로컬 파일에서 PDF 데이터 가져오기
        final file = File(pdf.localPath!);
        return await file.readAsBytes();
      } else {
        throw Exception('PDF 데이터를 찾을 수 없습니다');
      }
    } catch (e) {
      _setError('PDF 데이터를 가져오는 중 오류가 발생했습니다: $e');
      return null;
    }
  }
  
  /// 파일에서 PDF 업로드
  Future<void> uploadPdfFromFile(File file, String userId) async {
    try {
      _setLoading(true);
      
      final pdfModel = await _pdfRepository.uploadPdfFromFile(file, userId);
      _pdfs.add(pdfModel);
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }
  
  /// URL에서 PDF 업로드
  Future<void> uploadPdfFromUrl(String url, String userId) async {
    try {
      _setLoading(true);
      
      final pdfModel = await _pdfRepository.uploadPdfFromUrl(url, userId);
      _pdfs.add(pdfModel);
      
      _setLoading(false);
    } catch (e) {
      _setError('URL에서 PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      _setLoading(true);
      
      await _pdfRepository.deletePdf(pdfId, userId);
      _pdfs.removeWhere((pdf) => pdf.id == pdfId);
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }
} 