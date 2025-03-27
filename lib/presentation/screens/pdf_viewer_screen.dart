import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/models/pdf_document.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_theme.dart';

/// PDF 문서 뷰어 화면
class PdfViewerScreen extends StatefulWidget {
  /// 표시할 PDF 문서
  final PDFDocument document;
  
  /// PDF 바이트 데이터
  final Uint8List? pdfBytes;
  
  /// 생성자
  const PdfViewerScreen({
    Key? key,
    required this.document,
    required this.pdfBytes,
  }) : super(key: key);
  
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  /// PDF 제어 컨트롤러
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  /// 현재 페이지
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _currentPage = widget.document.currentPage;
  }
  
  @override
  void dispose() {
    if (mounted) {
      try {
        _saveLastReadPage();
      } catch (e) {
        debugPrint('마지막 페이지 저장 오류: $e');
      }
    }
    super.dispose();
  }
  
  /// 마지막으로 읽은 페이지 저장
  Future<void> _saveLastReadPage() async {
    if (!mounted) return;
    
    try {
      final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
      await pdfViewModel.saveLastReadPage(widget.document.id, _currentPage);
    } catch (e) {
      debugPrint('마지막 페이지 저장 오류: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 반응형 디자인을 위한 화면 크기 체크
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200; // 넓은 화면에서만 3단 레이아웃 사용
    
    // 뷰모델 접근
    final pdfViewModel = Provider.of<PDFViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: 북마크 추가 기능 구현
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 미회원 만료 정보 배너
          if (pdfViewModel.isGuestUser)
            _buildGuestExpirationBanner(pdfViewModel, authViewModel),
          
          // 메인 콘텐츠
          Expanded(
            child: widget.pdfBytes == null
                ? _buildErrorWidget()
                : isWideScreen
                    ? _buildWideScreenLayout() // 넓은 화면에서는 3단 레이아웃
                    : _buildNarrowScreenLayout(), // 좁은 화면에서는 기존 레이아웃
          ),
        ],
      ),
    );
  }
  
  /// 미회원 만료 정보 배너
  Widget _buildGuestExpirationBanner(PDFViewModel pdfViewModel, AuthViewModel authViewModel) {
    final expirationDays = pdfViewModel.getCurrentDocumentExpirationDays();
    final isExpired = pdfViewModel.isCurrentDocumentExpired();
    
    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Colors.red.shade100,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '이 문서는 만료되었습니다. 회원가입 후 문서를 영구적으로 저장하세요.',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                // TODO: 회원가입 화면 이동 구현
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('회원가입'),
            ),
          ],
        ),
      );
    } else if (expirationDays != null && expirationDays <= 2) {
      // 만료 예정 배너
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '이 문서는 $expirationDays일 후에 삭제됩니다. 회원가입하여 문서를 영구적으로 저장하세요.',
                style: TextStyle(color: Colors.amber.shade800),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                // TODO: 회원가입 화면 이동 구현
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('회원가입'),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // 만료가 멀었거나 회원인 경우 표시하지 않음
    }
  }
  
  /// 에러 화면 위젯
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('PDF 데이터를 로드할 수 없습니다.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }
  
  /// 넓은 화면용 3단 레이아웃
  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // 왼쪽: 페이지네이션 패널 (전체 너비의 15%)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.15,
          child: _buildPaginationPanel(),
        ),
        
        // 중앙: PDF 뷰어 (전체 너비의 55%)
        Expanded(
          flex: 55,
          child: _buildPdfViewer(),
        ),
        
        // 오른쪽: 기능 패널 (전체 너비의 30%)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.30,
          child: _buildFeaturesPanel(),
        ),
      ],
    );
  }
  
  /// 좁은 화면용 레이아웃
  Widget _buildNarrowScreenLayout() {
    return Column(
      children: [
        // PDF 뷰어
        Expanded(child: _buildPdfViewer()),
        
        // 하단 제어 도구 모음
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: () {
                  _pdfViewerController.firstPage();
                },
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () {
                  _pdfViewerController.previousPage();
                },
              ),
              Text(
                '$_currentPage / ${widget.document.pageCount > 0 ? widget.document.pageCount : "?"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () {
                  _pdfViewerController.nextPage();
                },
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: () {
                  _pdfViewerController.lastPage();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// PDF 뷰어 위젯
  Widget _buildPdfViewer() {
    return SfPdfViewer.memory(
      widget.pdfBytes!,
      controller: _pdfViewerController,
      pageSpacing: 4,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      canShowPaginationDialog: true,
      enableDocumentLinkAnnotation: true,
      enableHyperlinkNavigation: true,
      initialPageNumber: _currentPage,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }
  
  /// 페이지네이션 패널 위젯
  Widget _buildPaginationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            color: Colors.blue.shade100,
            child: const Text(
              '페이지',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.document.pageCount,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                // 페이지 번호는 1부터 시작
                final pageNumber = index + 1;
                final isSelected = pageNumber == _currentPage;
                
                return GestureDetector(
                  onTap: () {
                    _pdfViewerController.jumpToPage(pageNumber);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNumber',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// 기능 패널 위젯
  Widget _buildFeaturesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // 탭 바
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.summarize), text: "요약"),
                Tab(icon: Icon(Icons.quiz), text: "퀴즈"),
                Tab(icon: Icon(Icons.bubble_chart), text: "마인드맵"),
                Tab(icon: Icon(Icons.chat), text: "AI 채팅"),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            // 탭 뷰
            Expanded(
              child: TabBarView(
                children: [
                  _buildSummaryTab(),
                  _buildQuizTab(),
                  _buildMindMapTab(),
                  _buildAIChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 요약 탭 위젯
  Widget _buildSummaryTab() {
    return const Center(
      child: Text('요약 기능은 개발 중입니다.'),
    );
  }
  
  /// 퀴즈 탭 위젯
  Widget _buildQuizTab() {
    return const Center(
      child: Text('퀴즈 기능은 개발 중입니다.'),
    );
  }
  
  /// 마인드맵 탭 위젯
  Widget _buildMindMapTab() {
    return const Center(
      child: Text('마인드맵 기능은 개발 중입니다.'),
    );
  }
  
  /// AI 채팅 탭 위젯
  Widget _buildAIChatTab() {
    return const Center(
      child: Text('AI 채팅 기능은 개발 중입니다.'),
    );
  }
} 