import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import 'quiz_result_page.dart';

class QuizSessionPage extends StatefulWidget {
  final QuizSession quizSession;
  
  const QuizSessionPage({
    Key? key,
    required this.quizSession,
  }) : super(key: key);
  
  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late PageController _pageController;
  late QuizSession _quizSession;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _quizSession = widget.quizSession;
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _answerQuestion(int questionIndex, int selectedAnswerIndex) {
    setState(() {
      // 질문의 답변 업데이트
      _quizSession.questions[questionIndex].selectedAnswerIndex = selectedAnswerIndex;
    });
  }
  
  void _nextQuestion() {
    if (_currentIndex < _quizSession.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showResults();
    }
  }
  
  void _previousQuestion() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _showResults() {
    // 퀴즈 결과 페이지로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultPage(quizSession: _quizSession),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quizSession.title),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all),
            label: const Text('결과 보기'),
            onPressed: _showResults,
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행 상태 표시
          LinearProgressIndicator(
            value: _quizSession.answeredQuestions / _quizSession.totalQuestions,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '문제 ${_currentIndex + 1} / ${_quizSession.totalQuestions}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '답변 완료: ${_quizSession.answeredQuestions}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // 문제와 선택지
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _quizSession.questions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final question = _quizSession.questions[index];
                return _buildQuestionCard(question, index);
              },
            ),
          ),
          
          // 이전/다음 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('이전'),
                  onPressed: _currentIndex > 0 ? _previousQuestion : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                  onPressed: _nextQuestion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionCard(QuizQuestion question, int questionIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                question.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 선택지 목록
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            itemBuilder: (context, optionIndex) {
              // 문제가 답변되었는지 확인
              final isSelected = question.selectedAnswerIndex == optionIndex;
              final isAnswered = question.selectedAnswerIndex != null;
              
              // 답변 후에만 정답 표시
              final isCorrect = isAnswered && optionIndex == question.correctAnswerIndex;
              final isIncorrect = isAnswered && isSelected && !isCorrect;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected 
                    ? (isCorrect ? Colors.green.shade100 : (isIncorrect ? Colors.red.shade100 : Colors.blue.shade100))
                    : (isAnswered && isCorrect ? Colors.green.shade100 : null),
                child: ListTile(
                  leading: isSelected 
                      ? (isCorrect ? const Icon(Icons.check_circle, color: Colors.green) 
                                  : (isIncorrect ? const Icon(Icons.cancel, color: Colors.red) 
                                                : const Icon(Icons.radio_button_checked, color: Colors.blue)))
                      : (isAnswered && isCorrect
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade700)),
                  title: Text(question.options[optionIndex]),
                  onTap: isAnswered 
                      ? null 
                      : () => _answerQuestion(questionIndex, optionIndex),
                ),
              );
            },
          ),
          
          // 답변 완료 후 피드백 표시
          if (question.selectedAnswerIndex != null) ...[
            const SizedBox(height: 16),
            Card(
              color: question.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      question.isCorrect ? Icons.check_circle : Icons.info,
                      color: question.isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.isCorrect
                            ? '정답입니다!'
                            : '오답입니다. 정답은: ${question.options[question.correctAnswerIndex]}',
                        style: TextStyle(
                          color: question.isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 