import 'package:uuid/uuid.dart';

/// 퀴즈 문제 모델
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  bool isAnswered;
  int? selectedAnswerIndex;
  
  QuizQuestion({
    String? id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.isAnswered = false,
    this.selectedAnswerIndex,
  }) : id = id ?? const Uuid().v4();
  
  bool get isCorrect => isAnswered && selectedAnswerIndex == correctAnswerIndex;
  
  QuizQuestion answer(int index) {
    return QuizQuestion(
      id: id,
      question: question,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      isAnswered: true,
      selectedAnswerIndex: index,
    );
  }
  
  QuizQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isAnswered,
    int? selectedAnswerIndex,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      selectedAnswerIndex: selectedAnswerIndex ?? this.selectedAnswerIndex,
    );
  }
}

/// 퀴즈 세션 모델
class QuizSession {
  final String id;
  final String title;
  final String documentId;
  final String documentTitle;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  
  QuizSession({
    String? id,
    required this.title,
    required this.documentId,
    required this.documentTitle,
    required this.questions,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  int get totalQuestions => questions.length;
  int get answeredQuestions => questions.where((q) => q.isAnswered).length;
  int get correctAnswers => questions.where((q) => q.isCorrect).length;
  double get score => totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0;
  bool get isCompleted => answeredQuestions == totalQuestions;
  
  QuizSession answerQuestion(String questionId, int selectedIndex) {
    final List<QuizQuestion> updatedQuestions = questions.map((q) {
      if (q.id == questionId) {
        return q.answer(selectedIndex);
      }
      return q;
    }).toList();
    
    return QuizSession(
      id: id,
      title: title,
      documentId: documentId,
      documentTitle: documentTitle,
      questions: updatedQuestions,
      createdAt: createdAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'documentId': documentId,
      'documentTitle': documentTitle,
      'questions': questions.map((q) => {
        'id': q.id,
        'question': q.question,
        'options': q.options,
        'correctAnswerIndex': q.correctAnswerIndex,
        'isAnswered': q.isAnswered,
        'selectedAnswerIndex': q.selectedAnswerIndex,
      }).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  factory QuizSession.fromMap(Map<String, dynamic> map) {
    return QuizSession(
      id: map['id'],
      title: map['title'],
      documentId: map['documentId'],
      documentTitle: map['documentTitle'],
      questions: (map['questions'] as List).map((q) => QuizQuestion(
        id: q['id'],
        question: q['question'],
        options: List<String>.from(q['options']),
        correctAnswerIndex: q['correctAnswerIndex'],
        isAnswered: q['isAnswered'],
        selectedAnswerIndex: q['selectedAnswerIndex'],
      )).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
} 