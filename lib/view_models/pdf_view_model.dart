import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pdf_model.dart';
import '../models/user_model.dart';
import '../repositories/pdf_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_key_service.dart';
import '../services/pdf_service.dart';

/// PDF 관련 비즈니스 로직을 담당하는 ViewModel 클래스
class PdfViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final UserRepository _userRepository;
  final ApiKeyService _apiKeyService;
  final PdfService _pdfService;
  
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
    PdfService? pdfService,
  }) : _pdfRepository = pdfRepository ?? PdfRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _apiKeyService = apiKeyService ?? ApiKeyService(),
       _pdfService = pdfService ?? PdfService();
  
  /// 사용자의 PDF 목록 로드
  Future<void> loadPdfs(String userId) async {
    try {
      _setLoading(true);
      
      final pdfs = await _pdfRepository.getPdfs(userId);
      _pdfs = pdfs;
      
      debugPrint('PDF 목록 로드 완료: ${_pdfs.length}개');
      notifyListeners();
    } catch (e) {
      debugPrint('PDF 목록 로드 오류: $e');
      _setError('PDF 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 선택
  void selectPdf(PdfModel pdf) {
    _selectedPdf = pdf;
    notifyListeners();
  }
  
  /// PDF 선택 해제
  void unselectPdf() {
    _selectedPdf = null;
    notifyListeners();
  }
  
  /// PDF 데이터 가져오기
  Future<Uint8List?> getPdfData(String pdfId) async {
    try {
      _setLoading(true);
      
      final pdfData = await _pdfRepository.getPdfData(pdfId);
      if (pdfData == null) {
        throw Exception('PDF 데이터를 찾을 수 없습니다.');
      }
      
      return pdfData;
    } catch (e) {
      debugPrint('PDF 데이터 가져오기 오류: $e');
      _setError('PDF 데이터를 가져오는 중 오류가 발생했습니다.');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 파일에서 PDF 업로드
  Future<void> uploadPdfFromFile(File file, String userId) async {
    try {
      _setLoading(true);
      
      // 사용자 정보 확인
      final user = await _userRepository.getUser(userId);
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }
      
      // PDF 파일 크기 확인
      final fileSize = await file.length();
      if (fileSize > user.maxPdfSize) {
        throw Exception('PDF 파일 크기가 너무 큽니다. 최대 ${user.maxPdfSize ~/ (1024 * 1024)}MB까지 업로드할 수 있습니다.');
      }
      
      // PDF 일일 업로드 수 확인
      final todayPdfs = await _pdfRepository.getTodayPdfs(userId);
      if (todayPdfs.length >= user.maxPdfsPerDay) {
        throw Exception('일일 PDF 업로드 한도에 도달했습니다. 내일 다시 시도해주세요.');
      }
      
      // PDF 총 업로드 수 확인
      if (_pdfs.length >= user.maxPdfsTotal) {
        throw Exception('총 PDF 업로드 한도에 도달했습니다. 일부 PDF를 삭제한 후 다시 시도해주세요.');
      }
      
      // PDF 파일 처리
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      // PDF 정보 추출
      final pdfInfo = await _pdfService.extractPdfInfo(bytes);
      
      // PDF 페이지 수 확인
      if (pdfInfo.pageCount > user.maxPdfPages) {
        throw Exception('PDF 페이지 수가 너무 많습니다. 최대 ${user.maxPdfPages}페이지까지 업로드할 수 있습니다.');
      }
      
      // PDF 텍스트 길이 확인
      if (pdfInfo.textLength > user.maxPdfTextLength) {
        throw Exception('PDF 텍스트 길이가 너무 깁니다.');
      }
      
      // PDF 저장
      final pdf = PdfModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: fileName,
        size: fileSize,
        pageCount: pdfInfo.pageCount,
        textLength: pdfInfo.textLength,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        accessCount: 0,
      );
      
      await _pdfRepository.savePdf(pdf, bytes);
      
      // 사용자 사용량 업데이트
      await _userRepository.updateUsage(userId);
      
      // PDF 목록 다시 로드
      await loadPdfs(userId);
    } catch (e) {
      debugPrint('PDF 업로드 오류: $e');
      _setError('PDF 업로드에 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// URL에서 PDF 업로드
  Future<void> uploadPdfFromUrl(String url, String userId) async {
    try {
      _setLoading(true);
      
      // PDF 다운로드
      final bytes = await _pdfService.downloadPdfFromUrl(url);
      
      // 임시 파일 생성
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(bytes);
      
      // 파일에서 PDF 업로드
      await uploadPdfFromFile(tempFile, userId);
      
      // 임시 파일 삭제
      await tempFile.delete();
    } catch (e) {
      debugPrint('URL에서 PDF 업로드 오류: $e');
      _setError('URL에서 PDF 다운로드에 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 삭제
  Future<void> deletePdf(String pdfId, String userId) async {
    try {
      _setLoading(true);
      
      await _pdfRepository.deletePdf(pdfId);
      
      if (_selectedPdf?.id == pdfId) {
        _selectedPdf = null;
      }
      
      // PDF 목록 다시 로드
      await loadPdfs(userId);
    } catch (e) {
      debugPrint('PDF 삭제 오류: $e');
      _setError('PDF 삭제에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// PDF 내용 분석
  Future<String> analyzePdfContent(String pdfId, String userId) async {
    try {
      _setLoading(true);
      
      // API 키 확인
      final apiKey = await _apiKeyService.getApiKey(userId);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API 키가 설정되지 않았습니다. 설정 메뉴에서 API 키를 설정해주세요.');
      }
      
      // PDF 데이터 가져오기
      final pdfData = await _pdfRepository.getPdfData(pdfId);
      if (pdfData == null) {
        throw Exception('PDF 데이터를 찾을 수 없습니다.');
      }
      
      // PDF 텍스트 추출
      final text = await _pdfService.extractTextFromPdf(pdfData);
      
      // AI 분석 수행
      final analysis = await _pdfService.analyzeTextWithAI(text, apiKey);
      
      // PDF 접근 횟수 업데이트
      await _pdfRepository.updatePdfAccess(pdfId);
      
      // 선택된 PDF 업데이트
      if (_selectedPdf?.id == pdfId) {
        _selectedPdf = _selectedPdf!.copyWith(
          accessCount: _selectedPdf!.accessCount + 1,
          lastAccessedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return analysis;
    } catch (e) {
      debugPrint('PDF 내용 분석 오류: $e');
      _setError('PDF 내용 분석에 실패했습니다: ${e.toString()}');
      return '';
    } finally {
      _setLoading(false);
    }
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 