import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_document.dart';
import '../models/quiz_model.dart';
import '../services/auth_service.dart';
import '../services/quiz_service.dart';
import 'quiz_session_page.dart';

class QuizGenerationPage extends StatefulWidget {
  final PDFDocument document;
  final int questionCount;
  final List<int>? pageNumbers;
  
  const QuizGenerationPage({
    Key? key,
    required this.document,
    required this.questionCount,
    this.pageNumbers,
  }) : super(key: key);
  
  @override
  _QuizGenerationPageState createState() => _QuizGenerationPageState();
}

class _QuizGenerationPageState extends State<QuizGenerationPage> {
  bool _isLoading = true;
  String? _errorMessage;
  double _progress = 0.0;
  List<QuizQuestion>? _questions;
  
  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }
  
  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.0;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 유료 회원 확인
      if (!authService.isPremiumUser) {
        setState(() {
          _errorMessage = '퀴즈 생성은 유료 회원만 이용할 수 있는 기능입니다.';
          _isLoading = false;
        });
        return;
      }
      
      // 퀴즈 서비스 생성
      final quizService = QuizService(authService);
      
      // 진행률 업데이트 시뮬레이션
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _progress = i / 10;
        });
      }
      
      // 퀴즈 생성
      if (widget.pageNumbers != null && widget.pageNumbers!.isNotEmpty) {
        // 특정 페이지에서 퀴즈 생성
        _questions = await quizService.generateQuizFromPages(
          widget.document,
          widget.pageNumbers!,
          questionCount: widget.questionCount,
        );
      } else {
        // 전체 문서에서 퀴즈 생성
        _questions = await quizService.generateQuizFromPdf(
          widget.document,
          questionCount: widget.questionCount,
        );
      }
      
      // 퀴즈 세션 생성 및 페이지 이동
      if (_questions != null && _questions!.isNotEmpty && mounted) {
        final quizSession = QuizSession(
          title: widget.pageNumbers != null 
              ? '${widget.document.title} (페이지 ${widget.pageNumbers!.join(", ")})'
              : widget.document.title,
          documentId: widget.document.id,
          documentTitle: widget.document.title,
          questions: _questions!,
        );
        
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QuizSessionPage(quizSession: quizSession),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = '퀴즈 생성에 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '퀴즈 생성 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 생성 중...'),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('PDF 문서에서 퀴즈를 생성하고 있습니다...'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(value: _progress),
                  ),
                  const SizedBox(height: 8),
                  Text('${(_progress * 100).toInt()}%'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('퀴즈 생성 실패'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _generateQuiz,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
      ),
    );
  }
} 