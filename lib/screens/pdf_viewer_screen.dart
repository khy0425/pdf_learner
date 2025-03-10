import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../providers/bookmark_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';  // 이 import가 있는지 확인
import './quiz_result_screen.dart';  // QuizResultScreen import 추가
import 'dart:math' show min;
import 'dart:math';  // Random 클래스를 위한 import 추가
import 'package:syncfusion_flutter_pdf/pdf.dart';  // PdfDocument import 추가
import 'dart:convert';  // base64Encode를 위한 import
import '../widgets/pdf_viewer_guide_overlay.dart';  // PDFViewerGuideOverlay import 추가
import '../providers/tutorial_provider.dart';  // TutorialProvider import 추가
import '../providers/pdf_provider.dart';  // PdfFileInfo 클래스를 위한 import 추가
import 'package:flutter/foundation.dart' show kIsWeb;

/// 단순하고 효율적인 PDF 뷰어 화면
class PDFViewerScreen extends StatefulWidget {
  final PdfFileInfo pdfFile;

  const PDFViewerScreen({required this.pdfFile, super.key});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // PDF 문서가 로드되었을 때 호출
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _isLoading = false;
      _totalPages = details.document.pages.count;
    });
  }
  
  // PDF 페이지가 변경되었을 때 호출
  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }
  
  // PDF 로드 실패 시 호출
  void _onDocumentLoadFailed(Exception exception) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = '문서를 로드하는 중 오류가 발생했습니다: ${exception.toString()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfFile.fileName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _pdfViewerController.searchText('Flutter');
            },
            tooltip: '검색',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('북마크 기능은 아직 구현 중입니다')),
              );
            },
            tooltip: '북마크',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showAIFeaturesDialog(context);
            },
            tooltip: 'AI 기능',
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF 뷰어
          _buildPdfViewer(),
          
          // 로딩 표시기
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('PDF 문서를 불러오는 중...'),
                ],
              ),
            ),
          
          // 오류 메시지
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            ),
            
          // 하단 페이지 표시기
          if (!_isLoading && !_hasError)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _hasError ? null : _buildFloatingActionButton(),
    );
  }
  
  Widget _buildPdfViewer() {
    // 웹 환경에서 URL로 PDF 로드
    if (kIsWeb && widget.pdfFile.isWeb) {
      if (widget.pdfFile.previewUrl != null) {
        return SfPdfViewer.network(
          widget.pdfFile.previewUrl!,
          controller: _pdfViewerController,
          onDocumentLoaded: _onDocumentLoaded,
          onPageChanged: _onPageChanged,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          canShowScrollHead: true,
        );
      } else if (widget.pdfFile.hasBytes) {
        return SfPdfViewer.memory(
          widget.pdfFile.bytes!,
          controller: _pdfViewerController,
          onDocumentLoaded: _onDocumentLoaded,
          onPageChanged: _onPageChanged,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          canShowScrollHead: true,
        );
      } else {
        // URL을 통해 PDF를 가져오는 방식
        return FutureBuilder<dynamic>(
          future: widget.pdfFile.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('PDF를 로드하는 중 오류가 발생했습니다: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              return SfPdfViewer.memory(
                snapshot.data,
                controller: _pdfViewerController,
                onDocumentLoaded: _onDocumentLoaded,
                onPageChanged: _onPageChanged,
                onDocumentLoadFailed: _onDocumentLoadFailed,
                canShowScrollHead: true,
              );
            } else {
              return const Center(child: Text('PDF를 찾을 수 없습니다'));
            }
          },
        );
      }
    }
    
    // 로컬 파일로 PDF 로드
    else if (!kIsWeb && widget.pdfFile.isLocal) {
      return SfPdfViewer.file(
        widget.pdfFile.file!,
        controller: _pdfViewerController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
        onDocumentLoadFailed: _onDocumentLoadFailed,
        canShowScrollHead: true,
      );
    }
    
    // 메모리에서 PDF 로드 (웹에서 선택한 파일)
    else if (widget.pdfFile.hasBytes) {
      return SfPdfViewer.memory(
        widget.pdfFile.bytes!,
        controller: _pdfViewerController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
        onDocumentLoadFailed: _onDocumentLoadFailed,
        canShowScrollHead: true,
      );
    }
    
    // 지원되지 않는 경우
    else {
      return const Center(
        child: Text('지원되지 않는 PDF 형식입니다'),
      );
    }
  }
  
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showAIFeaturesDialog(context);
      },
      icon: const Icon(Icons.smart_toy),
      label: const Text('AI 기능'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
  
  // AI 기능 다이얼로그
  void _showAIFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 기능'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFeatureButton(
              context,
              icon: Icons.summarize,
              text: '문서 요약',
              onPressed: () {
                Navigator.pop(context);
                _showSummaryLoading(context);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureButton(
              context,
              icon: Icons.quiz,
              text: '퀴즈 생성',
              onPressed: () {
                Navigator.pop(context);
                _showQuizLoading(context);
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureButton(
              context,
              icon: Icons.question_answer,
              text: '질문하기',
              onPressed: () {
                Navigator.pop(context);
                _showAskQuestion(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
  
  // 요약 로딩 화면 표시
  void _showSummaryLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI가 문서를 요약하는 중입니다...'),
          ],
        ),
      ),
    );
    
    // 임시: 3초 후 요약 결과 표시
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showSummaryResult(context); // 결과 다이얼로그 표시
    });
  }
  
  // 요약 결과 표시
  void _showSummaryResult(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 요약'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '이 PDF 문서는 PDF 표준에 대한 설명을 담고 있습니다. '
                'PDF는 Adobe Systems에서 개발한 문서 형식으로, 운영체제에 관계없이 동일한 형태로 문서를 표시할 수 있도록 합니다. '
                '주요 특징으로는 텍스트, 이미지, 벡터 그래픽 등을 포함할 수 있으며, 문서의 보안 기능과 압축 기능을 제공합니다.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '주요 내용:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• PDF 파일 구조 설명\n• 문서 압축 기술\n• 보안 기능 개요\n• 다양한 운영체제 호환성\n• PDF 렌더링 방식'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  // 퀴즈 로딩 화면 표시
  void _showQuizLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI가 퀴즈를 생성하는 중입니다...'),
          ],
        ),
      ),
    );
    
    // 임시: 3초 후 퀴즈 결과 표시
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showQuizResult(context); // 결과 다이얼로그 표시
    });
  }
  
  // 퀴즈 결과 표시
  void _showQuizResult(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 퀴즈'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '다음 질문에 답하세요:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. PDF 형식을 개발한 회사는?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildQuizOption('A. Microsoft'),
              _buildQuizOption('B. Adobe Systems', isCorrect: true),
              _buildQuizOption('C. Apple'),
              _buildQuizOption('D. IBM'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizOption(String text, {bool isCorrect = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : null,
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey,
          width: isCorrect ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isCorrect ? Colors.green : null,
          fontWeight: isCorrect ? FontWeight.bold : null,
        ),
      ),
    );
  }
  
  // 질문하기 다이얼로그
  void _showAskQuestion(BuildContext context) {
    final TextEditingController questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서에 질문하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PDF 문서와 관련된 질문을 입력하세요:'),
            const SizedBox(height: 16),
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                hintText: '예: PDF의 주요 특징은 무엇인가요?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final question = questionController.text.trim();
              if (question.isNotEmpty) {
                Navigator.pop(context);
                _showAnswerLoading(context, question);
              }
            },
            child: const Text('질문하기'),
          ),
        ],
      ),
    );
  }
  
  // 답변 로딩 화면 표시
  void _showAnswerLoading(BuildContext context, String question) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('질문: $question'),
            const SizedBox(height: 8),
            const Text('AI가 답변을 생성하는 중입니다...'),
          ],
        ),
      ),
    );
    
    // 임시: 3초 후 답변 결과 표시
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showAnswerResult(context, question); // 결과 다이얼로그 표시
    });
  }
  
  // 답변 결과 표시
  void _showAnswerResult(BuildContext context, String question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 답변'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '질문: $question',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF의 주요 특징은 다음과 같습니다:\n\n'
                '1. 플랫폼 독립성: 모든 운영체제에서 동일하게 보이는 문서 형식\n\n'
                '2. 벡터 그래픽 지원: 고품질의 이미지와 텍스트 표현 가능\n\n'
                '3. 폰트 내장: 문서에 사용된 폰트를 내장하여 어디서나 동일하게 표시\n\n'
                '4. 압축 기능: 문서 크기를 효율적으로 관리\n\n'
                '5. 보안 기능: 암호화, 권한 설정 등 다양한 보안 옵션 제공',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
} 