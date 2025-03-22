import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
// AppLocalizations은 아직 생성되지 않았으므로 주석 처리
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../view_models/pdf_viewer_view_model.dart';
import '../models/pdf_file_info.dart';
import '../widgets/pdf_viewer_controls.dart';
import '../widgets/pdf_thumbnails.dart';
import '../theme/app_theme.dart';

/// SfPdfViewerState 확장 클래스 - 최신 버전과의 호환성을 위해 추가
extension SfPdfViewerStateExtension on SfPdfViewerState {
  /// 텍스트 선택 지우기
  void clearTextSelection() {
    // 최신 버전의 API에서는 pdfViewerController를 사용
    if (pdfViewerController != null) {
      pdfViewerController.clearSelection();
    }
  }
  
  /// 텍스트 검색
  void searchText(String searchText, {bool caseSensitive = false, bool wholeWords = false}) {
    if (searchText.isEmpty || pdfViewerController == null) return;
    
    // 최신 버전의 API 사용
    pdfViewerController.searchText(
      searchText,
      searchOption: PdfTextSearchOption(
        caseSensitive: caseSensitive,
        wholeWords: wholeWords,
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final PdfFileInfo pdf;

  const PDFViewerScreen({required this.pdf, super.key});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  // UI 관련 컨트롤러만 로컬 상태로 유지
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  bool _showThumbnails = false;
  bool _showSearchBar = false;
  final ScrollController _thumbnailScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // PDF 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
      viewModel.loadPdf(widget.pdf);
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    
    return Consumer<PdfViewerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.pdf.name,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppTheme.primaryColor,
            actions: _buildAppBarActions(viewModel),
          ),
          body: _buildBody(viewModel),
          bottomNavigationBar: _buildBottomBar(viewModel),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(PdfViewerViewModel viewModel) {
    return [
      // 검색 아이콘
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          setState(() {
            _showSearchBar = !_showSearchBar;
          });
        },
      ),
      
      // 북마크 아이콘
      IconButton(
        icon: Icon(
          Icons.bookmark,
          color: viewModel.bookmarks.isEmpty ? Colors.white : Colors.yellow,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildBookmarksDialog(viewModel),
          );
        },
      ),
      
      // 썸네일 아이콘
      IconButton(
        icon: const Icon(Icons.photo_library, color: Colors.white),
        onPressed: () {
          setState(() {
            _showThumbnails = !_showThumbnails;
          });
        },
      ),
      
      // 설정 아이콘
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) => _handleMenuAction(value, viewModel),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'highlight',
            child: Row(
              children: [
                Icon(Icons.highlight),
                SizedBox(width: 8),
                Text('하이라이트 모드'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'summary',
            child: Row(
              children: [
                Icon(Icons.summarize),
                SizedBox(width: 8),
                Text('문서 요약'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 8),
                Text('공유'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildBody(PdfViewerViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF를 불러오는 중...'),
          ],
        ),
      );
    }

    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('PDF를 불러오는 중 오류가 발생했습니다: ${viewModel.errorMessage}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.loadPdf(widget.pdf), 
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 검색 바
        if (_showSearchBar) _buildSearchBar(),
        
        // PDF 뷰어 (메인 컨텐츠)
        Expanded(
          child: Row(
            children: [
              // 썸네일 사이드바
              if (_showThumbnails)
                SizedBox(
                  width: 120,
                  child: PdfThumbnails(
                    pdfData: viewModel.pdfData!,
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    onPageSelected: (page) => viewModel.goToPage(page),
                    controller: _thumbnailScrollController,
                  ),
                ),
              
              // PDF 뷰어
              Expanded(
                child: Stack(
                  children: [
                    // PDF 뷰어
                    SfPdfViewerTheme(
                      data: SfPdfViewerThemeData(
                        backgroundColor: Colors.white,
                      ),
                      child: SfPdfViewer.memory(
                        viewModel.pdfData!,
                        key: _pdfViewerKey,
                        controller: _pdfViewerController,
                        onPageChanged: (PdfPageChangedDetails details) {
                          viewModel.setCurrentPage(details.newPageNumber);
                        },
                        onZoomLevelChanged: (PdfZoomDetails details) {
                          viewModel.setZoomLevel(details.newZoomLevel);
                        },
                        enableDocumentLinkAnnotation: true,
                        enableTextSelection: true,
                        enableDoubleTapZooming: true,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        canShowPaginationDialog: true,
                      ),
                    ),
                    
                    // 하이라이트 버튼 (하이라이트 모드일 때 활성화)
                    if (viewModel.isHighlightMode)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          backgroundColor: AppTheme.accentColor,
                          onPressed: () {
                            // 하이라이트 추가 로직
                            _showAddHighlightDialog(viewModel);
                          },
                          child: const Icon(Icons.highlight),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '검색어를 입력하세요',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _pdfViewerKey.currentState?.clearTextSelection();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _pdfViewerKey.currentState?.searchText(value);
          }
        },
      ),
    );
  }

  Widget _buildBottomBar(PdfViewerViewModel viewModel) {
    return BottomAppBar(
      color: AppTheme.primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 이전 페이지 버튼
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: viewModel.currentPage > 1
                ? () => viewModel.previousPage()
                : null,
          ),
          
          // 페이지 표시
          GestureDetector(
            onTap: () => _showPageNavigationDialog(viewModel),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${viewModel.currentPage} / ${viewModel.totalPages}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 다음 페이지 버튼
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: viewModel.currentPage < viewModel.totalPages
                ? () => viewModel.nextPage()
                : null,
          ),
          
          // 확대 버튼
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: () => viewModel.zoomIn(),
          ),
          
          // 축소 버튼
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: () => viewModel.zoomOut(),
          ),
          
          // 북마크 추가/제거 버튼
          IconButton(
            icon: Icon(
              viewModel.isPageBookmarked(viewModel.currentPage)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              viewModel.toggleBookmark(viewModel.currentPage);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksDialog(PdfViewerViewModel viewModel) {
    return AlertDialog(
      title: const Text('북마크'),
      content: SizedBox(
        width: double.maxFinite,
        child: viewModel.bookmarks.isEmpty
            ? const Center(child: Text('북마크가 없습니다.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: viewModel.bookmarks.length,
                itemBuilder: (context, index) {
                  final page = viewModel.bookmarks[index];
                  return ListTile(
                    title: Text('페이지 $page'),
                    onTap: () {
                      // String -> int 변환
                      final pageNumber = int.tryParse(page.replaceAll('page_', '')) ?? 1;
                      viewModel.goToPage(pageNumber);
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // String -> int 변환 
                        final pageNumber = int.tryParse(page.replaceAll('page_', '')) ?? 1;
                        viewModel.toggleBookmark(pageNumber);
                        // 북마크가 없어지면 다이얼로그 닫기
                        if (viewModel.bookmarks.isEmpty) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _showPageNavigationDialog(PdfViewerViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 이동'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - ${viewModel.totalPages} 범위 내 페이지 번호 입력',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final pageNumber = int.tryParse(controller.text);
              if (pageNumber != null && 
                  pageNumber >= 1 && 
                  pageNumber <= viewModel.totalPages) {
                viewModel.goToPage(pageNumber);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('유효한 페이지 번호를 입력해주세요')),
                );
              }
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }

  void _showAddHighlightDialog(PdfViewerViewModel viewModel) {
    final TextEditingController textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('하이라이트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('현재 페이지에 하이라이트할 텍스트를 입력하세요:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '하이라이트할 텍스트',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                viewModel.addHighlight(
                  viewModel.currentPage, 
                  textController.text
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('하이라이트가 추가되었습니다')),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, PdfViewerViewModel viewModel) {
    switch (action) {
      case 'highlight':
        viewModel.toggleHighlightMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.isHighlightMode 
                  ? '하이라이트 모드가 활성화되었습니다' 
                  : '하이라이트 모드가 비활성화되었습니다'
            ),
          ),
        );
        break;
      case 'summary':
        _generateSummary(viewModel);
        break;
      case 'share':
        _sharePdf(viewModel);
        break;
    }
  }

  void _generateSummary(PdfViewerViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF 내용을 요약하는 중...'),
          ],
        ),
      ),
    );

    viewModel.generateSummary().then((_) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      // 요약 결과 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('문서 요약'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '문서 요약 결과:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    viewModel.summary?.content ?? '요약을 생성할 수 없습니다.',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '생성 모델: ${viewModel.summary?.apiModel}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '생성 시간: ${viewModel.summary?.createdAt.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요약 생성 중 오류가 발생했습니다: $error')),
      );
    });
  }

  void _sharePdf(PdfViewerViewModel viewModel) {
    // 공유 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF 공유 기능은 아직 준비 중입니다')),
    );
  }
} 