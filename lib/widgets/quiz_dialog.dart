import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../screens/quiz_result_screen.dart';

class QuizDialog extends StatefulWidget {
  final List<Map<String, dynamic>> quizList;
  final List<int> pageNumbers;
  final AIService aiService;

  const QuizDialog({
    required this.quizList,
    required this.pageNumbers,
    required this.aiService,
    Key? key,
  }) : super(key: key);

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  int _currentQuizIndex = 0;
  late List<int?> _userAnswers;
  bool _showExplanation = false;

  // 현재 사용자의 답변을 가져오는 getter
  int? get userAnswer => _userAnswers[_currentQuizIndex];

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.quizList.length, null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizList.isEmpty || widget.pageNumbers.isEmpty) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('퀴즈를 생성할 수 없습니다.'),
        ),
      );
    }

    final currentQuiz = widget.quizList[_currentQuizIndex];
    final options = (currentQuiz['options'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    
    if (options.isEmpty) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('퀴즈 옵션을 불러올 수 없습니다.'),
        ),
      );
    }

    final correctAnswer = currentQuiz['answer'] as int? ?? 0;
    final hasAnswered = userAnswer != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuizHeader(context),
            const SizedBox(height: 16),
            Column(
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = userAnswer == index;
                final isCorrect = hasAnswered && index == correctAnswer;
                final isWrong = hasAnswered && userAnswer == index && index != correctAnswer;
                
                return _buildQuizOption(
                  index,
                  option,
                  isSelected,
                  hasAnswered,
                  isCorrect,
                  isWrong,
                );
              }).toList(),
            ),
            if (_showExplanation && hasAnswered) 
              _buildExplanation(context, currentQuiz),
            const SizedBox(height: 24),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentQuizIndex < widget.pageNumbers.length)
          Text(
            '페이지 ${widget.pageNumbers[_currentQuizIndex]}의 문제',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          widget.quizList[_currentQuizIndex]['question'] as String? ?? 
              '문제를 불러올 수 없습니다.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildQuizOption(
    int index,
    String option,
    bool isSelected,
    bool hasAnswered,
    bool isCorrect,
    bool isWrong,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : isWrong
                ? Colors.red.withOpacity(0.1)
                : null,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: hasAnswered
              ? null
              : () {
                  setState(() {
                    _userAnswers[_currentQuizIndex] = index;
                    _showExplanation = true;
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isCorrect
                    ? Colors.green
                    : isWrong
                        ? Colors.red
                        : Colors.transparent,
              ),
            ),
            leading: Radio<int>(
              value: index,
              groupValue: userAnswer,
              onChanged: hasAnswered
                  ? null
                  : (int? value) {
                      if (value != null) {
                        setState(() {
                          _userAnswers[_currentQuizIndex] = value;
                          _showExplanation = true;
                        });
                      }
                    },
            ),
            title: Text(
              option,
              style: TextStyle(
                color: hasAnswered
                    ? (isCorrect
                        ? Colors.green
                        : (isWrong ? Colors.red : null))
                    : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildExplanation(BuildContext context, Map<String, dynamic> currentQuiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설명',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(currentQuiz['explanation'] as String? ?? '설명이 없습니다.'),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentQuizIndex > 0)
          TextButton(
            onPressed: _previousQuiz,
            child: const Text('이전'),
          )
        else
          const SizedBox(width: 80),
        Text(
          '${_currentQuizIndex + 1} / ${widget.quizList.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_currentQuizIndex < widget.quizList.length - 1)
          TextButton(
            onPressed: _nextQuiz,
            child: const Text('다음'),
          )
        else
          TextButton(
            onPressed: _finishQuiz,
            child: const Text('완료'),
          ),
      ],
    );
  }

  // 이전 퀴즈로 이동
  void _previousQuiz() {
    setState(() {
      _currentQuizIndex--;
      _showExplanation = _userAnswers[_currentQuizIndex] != null;
    });
  }

  // 다음 퀴즈로 이동
  void _nextQuiz() {
    setState(() {
      _currentQuizIndex++;
      _showExplanation = _userAnswers[_currentQuizIndex] != null;
    });
  }

  // 퀴즈 완료
  void _finishQuiz() {
    Navigator.pop(context);
    if (_isQuizCompleted()) {
      _showQuizResult(context);
    }
  }

  // 모든 문제를 풀었는지 확인
  bool _isQuizCompleted() {
    return _userAnswers.every((answer) => answer != null);
  }

  // 퀴즈 결과 화면으로 이동
  void _showQuizResult(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          quizzes: widget.quizList,
          userAnswers: _userAnswers.cast<int>(),
          aiService: widget.aiService,
        ),
      ),
    );
  }
} 