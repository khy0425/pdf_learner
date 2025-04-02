import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 툴팁 위치 열거형
enum Position {
  /// 대상 위젯 위에 표시
  top,
  
  /// 대상 위젯 아래에 표시
  bottom,
  
  /// 대상 위젯 왼쪽에 표시
  left,
  
  /// 대상 위젯 오른쪽에 표시
  right,
  
  /// 대상 위젯 중앙에 표시
  center,
}

/// 튜토리얼 단계 정보 클래스
class TutorialStep {
  /// 단계 고유 ID
  final String id;
  
  /// 튜토리얼 제목
  final String title;
  
  /// 튜토리얼 설명
  final String description;
  
  /// 아이콘 (선택 사항)
  final IconData? icon;
  
  /// 툴팁 위치
  final Position position;
  
  /// 타겟 위젯 키 (선택 사항) - UniqueKey 사용으로 변경
  final Key? targetKey;
  
  /// 타겟 위젯 식별자 (선택 사항)
  final String? targetId;

  /// 생성자
  TutorialStep({
    String? id,
    required this.title,
    required this.description,
    this.icon,
    this.position = Position.bottom,
    this.targetKey,
    this.targetId,
  }) : id = id ?? const Uuid().v4();
}

/// 튜토리얼 제공자 클래스
class TutorialProvider extends ChangeNotifier {
  /// 튜토리얼 단계 목록
  final List<TutorialStep> _steps = [];
  
  /// 현재 단계 인덱스
  int _currentStep = 0;
  
  /// 튜토리얼 표시 여부
  bool _showTutorial = false;
  
  /// 첫 실행 여부
  bool _isFirstTime = false;
  
  /// 생성자
  TutorialProvider() {
    // 기본 튜토리얼 단계 초기화
    _initializeSteps();
    
    // 실행 이력 확인
    _checkFirstTimeRun();
  }
  
  /// 기본 튜토리얼 단계 초기화
  void _initializeSteps() {
    _steps.addAll([
      TutorialStep(
        title: '문서 관리',
        description: 'PDF 파일을 열고, 관리하고, 구성하세요.',
        icon: Icons.book,
        position: Position.bottom,
      ),
      TutorialStep(
        title: '검색 기능',
        description: '문서 내용을 검색하거나 문서 목록을 필터링하세요.',
        icon: Icons.search,
        position: Position.bottom,
      ),
      TutorialStep(
        title: 'AI 학습 도우미',
        description: 'AI가 문서를 분석하고 요약하며 퀴즈를 생성합니다.',
        icon: Icons.auto_awesome,
        position: Position.bottom,
      ),
      TutorialStep(
        title: '북마크와 노트',
        description: '중요한 부분을 북마크하고 노트를 추가하세요.',
        icon: Icons.bookmark,
        position: Position.bottom,
      ),
      TutorialStep(
        title: '시작하기',
        description: '이제 AI PDF 학습 도우미를 사용해보세요!',
        icon: Icons.check_circle,
        position: Position.center,
      ),
    ]);
  }
  
  /// 첫 실행 여부 확인
  void _checkFirstTimeRun() {
    // 실제 구현에서는 SharedPreferences 등을 사용하여 확인
    _isFirstTime = true;
  }
  
  /// 튜토리얼 표시
  void startTutorial() {
    _currentStep = 0;
    _showTutorial = true;
    notifyListeners();
  }
  
  /// 튜토리얼 중지
  void stopTutorial() {
    _showTutorial = false;
    notifyListeners();
  }
  
  /// 튜토리얼 완료 처리
  void completeTutorial() {
    _isFirstTime = false;
    _showTutorial = false;
    notifyListeners();
  }
  
  /// 다음 단계로 이동
  void nextStep() {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      notifyListeners();
    } else {
      completeTutorial();
    }
  }
  
  /// 이전 단계로 이동
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }
  
  /// 특정 단계로 이동
  void goToStep(int step) {
    if (step >= 0 && step < _steps.length) {
      _currentStep = step;
      notifyListeners();
    }
  }
  
  /// 현재 튜토리얼 단계 정보 반환
  TutorialStep? get currentTutorialStep => 
    _showTutorial && _steps.isNotEmpty ? _steps[_currentStep] : null;
  
  /// 현재 단계 인덱스 반환
  int get currentStep => _currentStep;
  
  /// 튜토리얼 표시 여부 반환
  bool get showTutorial => _showTutorial;
  
  /// 첫 실행 여부 반환
  bool get isFirstTime => _isFirstTime;
  
  /// 마지막 단계 여부 반환
  bool get isLastStep => _currentStep == _steps.length - 1;
} 