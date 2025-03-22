import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import '../services/auth_service.dart';
import 'quiz_session_page.dart';

class QuizResultPage extends StatelessWidget {
  final QuizSession quizSession;
  
  const QuizResultPage({
    Key? key,
    required this.quizSession,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 결과'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // 점수 카드
            _buildScoreCard(context),
            const SizedBox(height: 24),
            
            // 정답/오답 통계
            _buildStatistics(context),
            const SizedBox(height: 32),
            
            // 문제별 결과 리스트
            const Text(
              '문제별 결과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...quizSession.questions.map((question) => _buildQuestionResult(question)),
            const SizedBox(height: 32),
            
            // 저장 및 공유 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('저장하기'),
                      onPressed: authService.isPremiumUser
                          ? () => _saveQuizResult(context)
                          : () => _showPremiumDialog(context),
                    );
                  },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('공유하기'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('공유 기능은 곧 추가될 예정입니다'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('다시 풀기'),
              onPressed: () {
                // 문제 초기화 후 다시 풀기
                final resetQuizSession = QuizSession(
                  id: quizSession.id,
                  title: quizSession.title,
                  documentId: quizSession.documentId,
                  documentTitle: quizSession.documentTitle,
                  questions: quizSession.questions.map((q) => QuizQuestion(
                    id: q.id,
                    question: q.question,
                    options: q.options,
                    correctAnswerIndex: q.correctAnswerIndex,
                  )).toList(),
                  createdAt: DateTime.now(),
                );
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => QuizSessionPage(quizSession: resetQuizSession),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreCard(BuildContext context) {
    // 결과에 따른 색상과 메시지 결정
    final score = quizSession.score;
    Color scoreColor;
    String message;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      message = '훌륭합니다!';
    } else if (score >= 60) {
      scoreColor = Colors.amber;
      message = '잘 하셨습니다!';
    } else {
      scoreColor = Colors.red;
      message = '더 노력해보세요!';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              quizSession.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatistics(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          context,
          '전체 문제',
          quizSession.totalQuestions.toString(),
          Icons.question_answer,
          Colors.blue,
        ),
        _buildStatItem(
          context,
          '정답',
          quizSession.correctAnswers.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatItem(
          context,
          '오답',
          (quizSession.answeredQuestions - quizSession.correctAnswers).toString(),
          Icons.cancel,
          Colors.red,
        ),
      ],
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionResult(QuizQuestion question) {
    final isCorrect = question.isCorrect;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? '정답' : '오답',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '정답: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: question.options[question.correctAnswerIndex],
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            if (!isCorrect) ...[
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '선택한 답변: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: question.options[question.selectedAnswerIndex!],
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _saveQuizResult(BuildContext context) {
    // 실제로는 Firebase 등에 저장하는 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('퀴즈 결과가 저장되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('유료 회원 전용 기능'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              '퀴즈 결과 저장은 유료 회원만 이용할 수 있는 기능입니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/premium');
            },
            child: const Text('구독하기'),
          ),
        ],
      ),
    );
  }
} 