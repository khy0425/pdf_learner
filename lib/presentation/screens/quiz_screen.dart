import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final bool isReviewQuiz;

  const QuizScreen({
    Key? key,
    required this.quizzes,
    this.isReviewQuiz = false,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  late List<int?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quizzes.length, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReviewQuiz ? '복습 퀴즈' : '퀴즈'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildQuizContent(),
      ),
    );
  }

  Widget _buildQuizContent() {
    final quiz = widget.quizzes[_currentIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '문제 ${_currentIndex + 1}/${widget.quizzes.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          quiz['question'],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        ...List.generate(
          (quiz['options'] as List).length,
          (index) => _buildOptionTile(quiz, index),
        ),
      ],
    );
  }

  Widget _buildOptionTile(Map<String, dynamic> quiz, int index) {
    return RadioListTile<int>(
      value: index,
      groupValue: _answers[_currentIndex],
      title: Text(quiz['options'][index]),
      onChanged: (value) {
        setState(() {
          _answers[_currentIndex] = value;
        });
      },
    );
  }
} 