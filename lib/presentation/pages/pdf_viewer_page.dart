import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_view_model.dart';
import '../../domain/models/pdf_document.dart';

class PDFViewerPage extends StatefulWidget {
  final PDFDocument document;
  
  const PDFViewerPage({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfViewerController _pdfViewerController;
  bool _isFullScreen = false;
  bool _isBookmarksVisible = false;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _currentPage = widget.document.currentPage;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPage > 0) {
        _pdfViewerController.jumpToPage(_currentPage);
      }
    });
  }
  
  @override
  void dispose() {
    _saveReadingProgress();
    super.dispose();
  }
  
  void _saveReadingProgress() {
    final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
    final updatedDocument = widget.document.copyWith(
      currentPage: _currentPage,
      readingProgress: _currentPage / widget.document.pageCount,
    );
    pdfViewModel.updateDocument(updatedDocument);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PDFViewModel, AuthViewModel>(
      builder: (context, pdfViewModel, authViewModel, child) {
        return Scaffold(
          appBar: _isFullScreen 
            ? null 
            : PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // 뒤로가기 버튼
                        _buildViewerButton(
                          icon: Icons.arrow_back_rounded, 
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 12),
                        // 문서 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.document.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${_currentPage}/${widget.document.pageCount} 페이지',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _currentPage / widget.document.pageCount,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        const Color(0xFF3D6AFF),
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 액션 버튼들
                        _buildViewerButton(
                          icon: widget.document.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.document.isFavorite
                              ? Colors.red
                              : Colors.grey.shade700,
                          onTap: () {
                            if (authViewModel.isGuestMode) {
                              _showGuestRestrictionDialog();
                            } else {
                              pdfViewModel.toggleFavorite(widget.document.id);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildViewerButton(
                          icon: Icons.bookmark_border_rounded,
                          onTap: () {
                            if (authViewModel.isGuestMode) {
                              _showGuestRestrictionDialog();
                            } else {
                              setState(() {
                                _isBookmarksVisible = !_isBookmarksVisible;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildViewerButton(
                          icon: Icons.fullscreen_rounded,
                          onTap: () {
                            setState(() {
                              _isFullScreen = true;
                            });
                          },
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          body: Column(
            children: [
              // PDF 뷰어
              Expanded(
                child: Stack(
                  children: [
                    // PDF 뷰어
                    SfPdfViewer.file(
                      File(widget.document.filePath),
                      controller: _pdfViewerController,
                      onPageChanged: (PdfPageChangedDetails details) {
                        setState(() {
                          _currentPage = details.newPageNumber;
                        });
                      },
                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                        // 문서 로드 완료 시 초기 페이지로 이동
                        if (widget.document.currentPage > 0) {
                          _pdfViewerController.jumpToPage(widget.document.currentPage);
                        }
                      },
                    ),
                    
                    // 전체 화면 모드 종료 버튼
                    if (_isFullScreen)
                      Positioned(
                        top: 36,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen_exit,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFullScreen = false;
                              });
                            },
                          ),
                        ),
                      ),
                    
                    // 게스트 모드 안내 (진행 중 안내 표시)
                    if (authViewModel.isGuestMode && _currentPage > widget.document.pageCount * 0.2)
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5D5FEF),
                                Color(0xFF3D6AFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3D6AFF).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '체험 모드 제한',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '총 ${widget.document.pageCount}페이지 중 ${(widget.document.pageCount * 0.3).toInt()}페이지까지만 볼 수 있습니다',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _showGuestRestrictionDialog();
                                },
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    color: Color(0xFF3D6AFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // UPDF 스타일의 뷰어 버튼
  Widget _buildViewerButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary 
            ? const LinearGradient(
                colors: [
                  Color(0xFF5D5FEF),
                  Color(0xFF3D6AFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isPrimary 
                ? const Color(0xFF3D6AFF).withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
            blurRadius: isPrimary ? 8 : 4,
            offset: isPrimary ? const Offset(0, 2) : const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isPrimary 
              ? Colors.white 
              : color ?? Colors.grey.shade700,
        ),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
  
  void _showGuestRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5D5FEF),
                    Color(0xFF3D6AFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '체험 모드 안내',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3D6AFF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3D6AFF).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFF3D6AFF),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      '프리미엄 기능을 사용하려면 회원가입이 필요합니다',
                      style: TextStyle(
                        color: Color(0xFF3D6AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '체험 모드 제한 기능:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.book, '전체 문서 읽기 (30%만 제공)', true),
            _buildFeatureItem(Icons.bookmark, '북마크 생성 및 관리', false),
            _buildFeatureItem(Icons.note_add, '노트 작성 기능', false),
            _buildFeatureItem(Icons.cloud_upload, '클라우드 동기화', false),
            _buildFeatureItem(Icons.psychology, 'AI 요약 및 분석', false),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: const Color(0xFF3D6AFF),
            ),
            child: const Text('회원가입'),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: available 
                  ? const Color(0xFF3D6AFF).withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              size: 18, 
              color: available 
                  ? const Color(0xFF3D6AFF)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: available
                    ? Colors.grey.shade800
                    : Colors.grey.shade500,
              ),
            ),
          ),
          if (available)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF3D6AFF),
              size: 18,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3D6AFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '프리미엄',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D6AFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 