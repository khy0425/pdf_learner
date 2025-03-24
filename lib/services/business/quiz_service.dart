import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pdf_document.dart';
import '../models/quiz_model.dart';
import 'auth_service.dart';

class QuizService {
  final AuthService _authService;
  final String _apiUrl = 'https://api.example.com/generate-quiz'; // 실제 API 주소로 변경 필요
  
  QuizService(this._authService);
  
  /// PDF 문서에서 퀴즈 생성
  Future<List<QuizQuestion>> generateQuizFromPdf(PDFDocument document, {int questionCount = 5}) async {
    // 유료 회원 확인
    if (!_authService.isPremiumUser) {
      throw Exception('퀴즈 생성은 유료 회원만 이용할 수 있는 기능입니다.');
    }
    
    try {
      // 여기서는 실제 API 호출을 가정합니다.
      // 실제로는 PDF 내용을 추출하고 특정 API를 호출하여 퀴즈를 생성해야 합니다.
      // 이 예제에서는 더미 데이터를 반환합니다.
      
      if (kIsWeb) {
        // 웹 환경에서는 PDF URL이 필요합니다.
        if (document.url == null || document.url!.isEmpty) {
          throw Exception('퀴즈 생성을 위해 Firebase Storage URL이 필요합니다.');
        }
        
        // API 호출 (여기서는 가상으로 처리)
        await Future.delayed(const Duration(seconds: 2)); // API 호출 시뮬레이션
        
        // 더미 데이터 생성
        return _generateDummyQuestions(document.title, questionCount);
      } else {
        // 네이티브 환경에서는 파일 경로 사용
        final file = File(document.filePath);
        if (!file.existsSync()) {
          throw Exception('파일을 찾을 수 없습니다.');
        }
        
        // API 호출 (여기서는 가상으로 처리)
        await Future.delayed(const Duration(seconds: 2)); // API 호출 시뮬레이션
        
        // 더미 데이터 생성
        return _generateDummyQuestions(document.title, questionCount);
      }
    } catch (e) {
      debugPrint('퀴즈 생성 중 오류: $e');
      rethrow;
    }
  }
  
  /// 페이지 범위에서 퀴즈 생성
  Future<List<QuizQuestion>> generateQuizFromPages(
    PDFDocument document, 
    List<int> pageNumbers, 
    {int questionCount = 5}
  ) async {
    // 유료 회원 확인
    if (!_authService.isPremiumUser) {
      throw Exception('퀴즈 생성은 유료 회원만 이용할 수 있는 기능입니다.');
    }
    
    try {
      // API 호출 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));
      
      // 더미 데이터 생성
      return _generateDummyQuestions(
        '${document.title} (페이지 ${pageNumbers.join(', ')})', 
        questionCount
      );
    } catch (e) {
      debugPrint('퀴즈 생성 중 오류: $e');
      rethrow;
    }
  }
  
  /// 테스트용 더미 퀴즈 문제 생성
  List<QuizQuestion> _generateDummyQuestions(String topic, int count) {
    final questions = <QuizQuestion>[];
    
    final dummyQuestions = [
      {
        'question': '$topic의 주요 특징은 무엇인가요?',
        'options': [
          '데이터 분석 기능',
          '사용자 인터페이스',
          '보안 기능',
          '클라우드 연동'
        ],
        'correctAnswer': 1
      },
      {
        'question': '$topic에서 가장 중요한 개념은?',
        'options': [
          '데이터 구조',
          '알고리즘',
          '사용자 경험',
          '시스템 아키텍처'
        ],
        'correctAnswer': 3
      },
      {
        'question': '$topic의 역사적 배경은?',
        'options': [
          '1990년대 초반',
          '2000년대 중반',
          '2010년 이후',
          '1980년대 후반'
        ],
        'correctAnswer': 2
      },
      {
        'question': '$topic을 활용한 첫 번째 애플리케이션은?',
        'options': [
          '검색 엔진',
          '소셜 미디어',
          '문서 관리 시스템',
          '온라인 쇼핑몰'
        ],
        'correctAnswer': 2
      },
      {
        'question': '$topic의 미래 발전 방향은?',
        'options': [
          '인공지능 통합',
          '블록체인 기술 접목',
          '모바일 최적화',
          '가상현실 지원'
        ],
        'correctAnswer': 0
      },
      {
        'question': '$topic을 사용하는 주요 기업은?',
        'options': [
          'Google',
          'Microsoft',
          'Amazon',
          'Apple'
        ],
        'correctAnswer': 1
      },
      {
        'question': '$topic의 주요 경쟁 기술은?',
        'options': [
          'AI 기반 시스템',
          '웹 프레임워크',
          '클라우드 서비스',
          '모바일 플랫폼'
        ],
        'correctAnswer': 2
      },
    ];
    
    // 랜덤하게 문제 선택
    final random = Random();
    final selectedIndices = <int>{};
    
    while (selectedIndices.length < count && selectedIndices.length < dummyQuestions.length) {
      final index = random.nextInt(dummyQuestions.length);
      selectedIndices.add(index);
    }
    
    for (final index in selectedIndices) {
      final q = dummyQuestions[index];
      questions.add(
        QuizQuestion(
          question: q['question'] as String,
          options: List<String>.from(q['options'] as List),
          correctAnswerIndex: q['correctAnswer'] as int,
        ),
      );
    }
    
    return questions;
  }
} 