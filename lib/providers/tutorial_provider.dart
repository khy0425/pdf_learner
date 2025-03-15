import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class TutorialStep {
  final String title; // 튜토리얼 제목
  final String description; // 튜토리얼 설명
  final GlobalKey targetKey; // 가리킬 위젯의 키
  final Position position; // 툴팁 위치
  final IconData? icon; // 관련 아이콘
  
  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.position = Position.bottom,
    this.icon,
  });
}

// 툴팁 위치 정의
enum Position {
  top,
  bottom,
  left,
  right,
  center,
}

class TutorialProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  static const String _tutorialShownKey = 'tutorial_shown';
  static const String _lastShownDateKey = 'tutorial_last_shown_date';
  static const String _pdfViewerGuideShownKey = 'pdf_viewer_guide_shown';
  bool _isFirstTime = true;
  bool _isPdfViewerGuideShown = false;
  bool _showTutorial = false;
  int _currentStep = 0;
  List<TutorialStep> _tutorialSteps = [];
  bool _isInitialized = false;
  
  // 튜토리얼을 이미 봤는지 여부
  bool _hasSeenTutorial = false;
  
  bool get isFirstTime => _isFirstTime;
  bool get isPdfViewerGuideShown => _isPdfViewerGuideShown;
  bool get showTutorial => _showTutorial;
  int get currentStep => _currentStep;
  bool get hasSeenTutorial => _hasSeenTutorial;
  bool get isLastStep => _currentStep >= _tutorialSteps.length - 1;
  TutorialStep? get currentTutorialStep => 
      _tutorialSteps.isNotEmpty && _currentStep < _tutorialSteps.length 
          ? _tutorialSteps[_currentStep] 
          : null;

  TutorialProvider() {
    _loadTutorialState();
    _loadPDFViewerGuideState();
  }

  Future<void> _loadTutorialState() async {
    _prefs = await SharedPreferences.getInstance();
    final tutorialShown = _prefs?.getBool(_tutorialShownKey) ?? false;
    final lastShownDate = _prefs?.getString(_lastShownDateKey);

    if (!tutorialShown) {
      _isFirstTime = true;
    } else if (lastShownDate != null) {
      final lastDate = DateTime.parse(lastShownDate);
      final today = DateTime.now();
      _isFirstTime = !isSameDay(lastDate, today);
    }
    notifyListeners();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> completeTutorial({bool skipForToday = false}) async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    if (skipForToday) {
      await _prefs?.setString(_lastShownDateKey, DateTime.now().toIso8601String());
    } else {
      await _prefs?.setBool(_tutorialShownKey, true);
    }
    _isFirstTime = false;
    notifyListeners();
  }

  Future<void> completePDFViewerGuide() async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    await _prefs?.setBool(_pdfViewerGuideShownKey, true);
    _isPdfViewerGuideShown = true;
    notifyListeners();
  }

  Future<void> _loadPDFViewerGuideState() async {
    _prefs = await SharedPreferences.getInstance();
    _isPdfViewerGuideShown = _prefs?.getBool(_pdfViewerGuideShownKey) ?? false;
    print('PDF 뷰어 가이드 상태: $_isPdfViewerGuideShown');
    notifyListeners();
  }

  // 가이드 다시 보기를 위한 리셋 함수
  Future<void> resetPDFViewerGuide() async {
    _isPdfViewerGuideShown = false;
    await _prefs?.setBool(_pdfViewerGuideShownKey, false);
    notifyListeners();
  }

  // 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadHasSeenTutorial();
    _isInitialized = true;
    
    // 앱 첫 실행 시 자동으로 튜토리얼 시작
    if (!_hasSeenTutorial) {
      // 약간 지연시켜 UI가 완전히 로드된 후 시작
      Future.delayed(const Duration(milliseconds: 500), () {
        startTutorial();
      });
    }
  }
  
  // 튜토리얼 본 상태 저장
  Future<void> _saveHasSeenTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_tutorial', true);
      _hasSeenTutorial = true;
    } catch (e) {
      debugPrint('튜토리얼 상태 저장 오류: $e');
    }
  }
  
  // 튜토리얼 볼 섬 저장 상태 로드
  Future<void> _loadHasSeenTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;
      debugPrint('튜토리얼 상태 로드: $_hasSeenTutorial');
      notifyListeners();
    } catch (e) {
      debugPrint('튜토리얼 상태 로드 오류: $e');
      _hasSeenTutorial = false;
      notifyListeners();
    }
  }
  
  // 튜토리얼 단계 설정
  void setTutorialSteps(List<TutorialStep> steps) {
    _tutorialSteps = steps;
    notifyListeners();
  }
  
  // 튜토리얼 시작
  void startTutorial() {
    _showTutorial = true;
    _currentStep = 0;
    notifyListeners();
  }
  
  // 튜토리얼 중지
  void stopTutorial() {
    _showTutorial = false;
    _currentStep = 0;
    _saveHasSeenTutorial(); // 튜토리얼을 봤음을 저장
    notifyListeners();
  }
  
  // 다음 단계로 이동
  void nextStep() {
    if (_currentStep < _tutorialSteps.length - 1) {
      _currentStep++;
      notifyListeners();
    } else {
      stopTutorial();
    }
  }
  
  // 이전 단계로 이동
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }
  
  // 튜토리얼 본 이력 초기화 (개발용)
  Future<void> resetTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_tutorial', false);
      _hasSeenTutorial = false;
      notifyListeners();
    } catch (e) {
      debugPrint('튜토리얼 상태 초기화 오류: $e');
    }
  }
} 