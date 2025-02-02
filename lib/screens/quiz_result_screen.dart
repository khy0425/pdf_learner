import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import './quiz_screen.dart';  // 퀴즈 화면 import 추가

class QuizResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizzes;
  final List<int> userAnswers;
  final AIService aiService;

  const QuizResultScreen({
    Key? key,  // super.key 대신 Key? key 사용
    required this.quizzes,
    required this.userAnswers,
    required this.aiService,
  }) : super(key: key);  // 올바른 super 생성자 호출

  @override
  Widget build(BuildContext context) {
    final incorrectQuizzes = _getIncorrectQuizzes();
    final correctCount = userAnswers.asMap().entries
        .where((e) => e.value == quizzes[e.key]['answer'])
        .length;
    final score = (correctCount / quizzes.length * 100).round();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 결과'),
        actions: [
          if (incorrectQuizzes.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showStudyGuide(context),
              icon: const Icon(Icons.school),
              label: const Text('학습 가이드'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[  // 명시적으로 Widget 타입 지정
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$score점',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('$correctCount / ${quizzes.length} 문제 정답'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (incorrectQuizzes.isNotEmpty) ...[
              Text(
                '틀린 문제 분석',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incorrectQuizzes.length,
                itemBuilder: (context, index) {
                  final quiz = incorrectQuizzes[index];
                  final userAnswer = userAnswers[quizzes.indexOf(quiz)];
                  
                  return Card(
                    child: ListTile(
                      title: Text(quiz['question']),
                      subtitle: Text(
                        '선택: ${quiz['options'][userAnswer]}\n'
                        '정답: ${quiz['options'][quiz['answer']]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.analytics),
                        onPressed: () => _showMistakeAnalysis(
                          context,
                          quiz,
                          userAnswer,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _generateReviewQuizzes(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('복습 문제 생성'),
                ),
              ),
            ] else
              Center(  // else 뒤에 단일 위젯으로 변경
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 64,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '축하합니다!\n모든 문제를 맞추셨습니다!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMistakeAnalysis(
    BuildContext context,
    Map<String, dynamic> quiz,
    int userAnswer,
  ) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await aiService.generateMistakeAnalysis(quiz, userAnswer);
      
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('오답 분석'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('오답 선택 이유', style: Theme.of(context).textTheme.titleMedium),
                  Text(analysis['mistakeAnalysis']),
                  const SizedBox(height: 16),
                  Text('관련 개념', style: Theme.of(context).textTheme.titleMedium),
                  Text(analysis['conceptExplanation']),
                  const SizedBox(height: 16),
                  Text('학습 제안', style: Theme.of(context).textTheme.titleMedium),
                  ...analysis['studyTips'].map((tip) => Text('• $tip')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오답 분석 생성 실패: $e')),
        );
      }
    }
  }

  Future<void> _generateReviewQuizzes(BuildContext context) async {
    final incorrectQuizzes = _getIncorrectQuizzes();
    if (incorrectQuizzes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('틀린 문제가 없습니다!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reviewQuizzes = await aiService.generateReviewQuizzes(incorrectQuizzes);
      
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              quizzes: reviewQuizzes,
              isReviewQuiz: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복습 문제 생성 실패: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getIncorrectQuizzes() {
    return quizzes.asMap().entries.where(
      (e) => userAnswers[e.key] != e.value['answer']
    ).map((e) => e.value).toList();
  }

  Future<void> _showStudyGuide(BuildContext context) async {
    final incorrectQuizzes = _getIncorrectQuizzes();
    if (incorrectQuizzes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 문제를 맞추셨습니다! 축하합니다!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final studyGuide = await aiService.generateStudyGuide(incorrectQuizzes);
      
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('학습 가이드'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('취약 개념', style: Theme.of(context).textTheme.titleMedium),
                  Text(studyGuide['weakPoints'].join('\n')),
                  const SizedBox(height: 16),
                  Text('학습 계획', style: Theme.of(context).textTheme.titleMedium),
                  Text(studyGuide['studyPlan']),
                  const SizedBox(height: 16),
                  Text('추천 자료', style: Theme.of(context).textTheme.titleMedium),
                  ...studyGuide['recommendedResources'].map((resource) => Text('• $resource')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('학습 가이드 생성 실패: $e')),
        );
      }
    }
  }
} 