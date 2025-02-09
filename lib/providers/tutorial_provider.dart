import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  static const String _tutorialShownKey = 'tutorial_shown';
  static const String _lastShownDateKey = 'tutorial_last_shown_date';
  static const String _pdfViewerGuideShownKey = 'pdf_viewer_guide_shown';
  bool _isFirstTime = true;
  bool _isPdfViewerGuideShown = false;

  bool get isFirstTime => _isFirstTime;
  bool get isPdfViewerGuideShown => _isPdfViewerGuideShown;

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
} 