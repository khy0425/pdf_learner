import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_model.dart';
import '../view_models/pdf_view_model.dart';
import '../view_models/auth_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/pdf_provider.dart';
import '../services/auth_service.dart';
import '../services/api_key_service.dart';
import '../models/pdf_file_info.dart';

/// PDF 학습 앱의 홈 화면을 위한 ViewModel
/// MVVM 패턴에 따라 View(HomePage)와 Model 사이의 중개자 역할을 함
class HomeViewModel extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // API 키 상태 관련
  bool _isCheckingApiKey = true;
  bool _hasValidApiKey = false;
  bool _isPremiumUser = false;
  String? _maskedApiKey;
  
  // 사용자 정보 관련
  User? _currentUser;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  
  bool get isCheckingApiKey => _isCheckingApiKey;
  bool get hasValidApiKey => _hasValidApiKey;
  bool get isPremiumUser => _isPremiumUser;
  String? get maskedApiKey => _maskedApiKey;
  
  User? get currentUser => _currentUser;
  
  // Setters
  set isInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }
  
  HomeViewModel() {
    // 현재 로그인된 사용자 정보 가져오기
    _currentUser = FirebaseAuth.instance.currentUser;
  }
  
  /// PDF 파일 목록 로드
  Future<void> loadPDFs(BuildContext context) async {
    try {
      _setLoading(true);
      _clearError();
      
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 로그인된 사용자만 로드
      if (authService.isLoggedIn) {
        final userId = authService.user!.uid;
        await pdfProvider.loadSavedPDFs(context);
        
        // 클라우드 PDF도 로드
        await pdfProvider.loadCloudPDFs();
      } else {
        // 로그인되지 않은 경우, 임시 저장된 PDF만 표시
        await pdfProvider.loadSavedPDFs(context);
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 파일 선택
  Future<void> pickPDF(BuildContext context) async {
    try {
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      
      // 로그인 상태 확인
      final authService = Provider.of<AuthService>(context, listen: false);
      final String userId = authService.isLoggedIn ? authService.user!.uid : 'guest_user';
      
      // 게스트 모드인 경우 이미 3개 이상의 PDF가 있는지 확인
      if (userId == 'guest_user' && pdfProvider.pdfFiles.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('비로그인 사용자는 최대 3개까지 PDF를 추가할 수 있습니다. 더 많은 PDF를 관리하려면 로그인하세요.'),
            action: SnackBarAction(
              label: '로그인',
              onPressed: () => Navigator.pushNamed(context, '/auth'),
            ),
          ),
        );
        return;
      }
      
      // PDF 선택 다이얼로그 표시
      _showPdfPickerDialog(context, userId);
    } catch (e) {
      _setError('PDF 선택 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 선택 다이얼로그
  void _showPdfPickerDialog(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('파일에서 업로드'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadPdfFromFile(context, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('URL에서 업로드'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadPdfFromUrl(context, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 파일에서 PDF 업로드
  Future<void> _uploadPdfFromFile(BuildContext context, String userId) async {
    try {
      _setLoading(true);
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      
      // 파일 선택 다이얼로그 표시
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          await pdfProvider.pickAndAddPdf(context, filePath: filePath);
        }
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }
  
  /// URL에서 PDF 업로드
  Future<void> _uploadPdfFromUrl(BuildContext context, String userId) async {
    try {
      // URL 입력을 위한 컨트롤러
      final urlController = TextEditingController();
      
      // URL 입력 다이얼로그
      final url = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('URL에서 PDF 업로드'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'PDF URL을 입력하세요',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, urlController.text.trim()),
              child: const Text('업로드'),
            ),
          ],
        ),
      );
      
      if (url != null && url.isNotEmpty) {
        _setLoading(true);
        final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
        await pdfProvider.pickAndAddPdf(context, url: url);
        _setLoading(false);
      }
    } catch (e) {
      _setError('URL에서 PDF 업로드 중 오류가 발생했습니다: $e');
    }
  }
  
  /// PDF 파일 삭제
  Future<void> deletePDF(BuildContext context, PDFProvider pdfProvider, PdfFileInfo pdfFile) async {
    try {
      // 삭제 확인 다이얼로그
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF 삭제'),
          content: Text('${pdfFile.fileName}을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      
      if (shouldDelete == true) {
        _setLoading(true);
        await pdfProvider.deletePDF(pdfFile, context);
        _setLoading(false);
      }
    } catch (e) {
      _setError('PDF 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  /// API 키 상태 확인
  Future<void> checkApiKeyStatus(BuildContext context) async {
    try {
      _isCheckingApiKey = true;
      notifyListeners();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _hasValidApiKey = false;
        _isPremiumUser = false;
        _maskedApiKey = null;
        _isCheckingApiKey = false;
        notifyListeners();
        return;
      }
      
      final apiKeyService = Provider.of<ApiKeyService>(context, listen: false);
      
      // 프리미엄 사용자 여부 확인
      _isPremiumUser = await apiKeyService.isPremiumUser(user.uid);
      
      // API 키 확인
      final apiKey = await apiKeyService.getApiKey(user.uid);
      _hasValidApiKey = apiKey != null && apiKey.isNotEmpty && await apiKeyService.isValidApiKey(apiKey);
      
      if (apiKey != null && apiKey.isNotEmpty) {
        _maskedApiKey = apiKeyService.maskApiKey(apiKey);
      } else {
        _maskedApiKey = null;
      }
      
      _isCheckingApiKey = false;
      notifyListeners();
    } catch (e) {
      debugPrint('API 키 상태 확인 중 오류: $e');
      _isCheckingApiKey = false;
      _hasValidApiKey = false;
      notifyListeners();
    }
  }
  
  /// 사용자 이니셜 가져오기
  String getUserInitial(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    } else if (user.email != null && user.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return '?';
  }
  
  /// 사용자 표시 이름 가져오기
  String getUserDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    } else if (user.email != null && user.email!.isNotEmpty) {
      final emailParts = user.email!.split('@');
      return emailParts[0];
    }
    return '사용자';
  }
  
  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 오류 설정
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
  
  /// 오류 초기화
  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
} 