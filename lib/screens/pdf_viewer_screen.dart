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

class PDFViewerScreen extends StatefulWidget {
  final File pdfFile;

  const PDFViewerScreen({required this.pdfFile, super.key});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _showThumbnails = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  double _zoomLevel = 1.0;
  final PDFService _pdfService = PDFService();
  final AIService _aiService = AIService();
  bool _showOutline = false;
  List<Map<String, dynamic>>? _outlineData;  // 목차 데이터를 Map으로 저장
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final ScrollController _thumbnailScrollController = ScrollController();  // 썸네일 스크롤 컨트롤러 추가

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO): 
            const ShowOutlineIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): 
            const ShowBookmarksIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): 
            const ShowSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal): 
            const ZoomInIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus): 
            const ZoomOutIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ShowOutlineIntent: CallbackAction<ShowOutlineIntent>(
            onInvoke: (intent) => _showOutlineDialog(),
          ),
          ShowBookmarksIntent: CallbackAction<ShowBookmarksIntent>(
            onInvoke: (intent) => _showBookmarksList(),
          ),
          ShowSearchIntent: CallbackAction<ShowSearchIntent>(
            onInvoke: (intent) => setState(() => _showSearchBar = !_showSearchBar),
          ),
          ZoomInIntent: CallbackAction<ZoomInIntent>(
            onInvoke: (intent) => setState(() {
              _zoomLevel = _zoomLevel + 0.25;
              _pdfViewerController.zoomLevel = _zoomLevel;
            }),
          ),
          ZoomOutIntent: CallbackAction<ZoomOutIntent>(
            onInvoke: (intent) => setState(() {
              _zoomLevel = _zoomLevel - 0.25;
              _pdfViewerController.zoomLevel = _zoomLevel;
            }),
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.pdfFile.path.split('/').last),
            actions: [
              // 검색 버튼
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _pdfViewerController.clearSelection();
                    }
                  });
                },
              ),
              // 썸네일 버튼
              IconButton(
                icon: Icon(
                  Icons.view_list,
                  color: _showThumbnails ? colorScheme.primary : null,
                ),
                onPressed: () {
                  setState(() {
                    _showThumbnails = !_showThumbnails;
                  });
                },
              ),
              // 줌 컨트롤
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _zoomLevel = _zoomLevel + 0.25;
                    _pdfViewerController.zoomLevel = _zoomLevel;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _zoomLevel = _zoomLevel - 0.25;
                    _pdfViewerController.zoomLevel = _zoomLevel;
                  });
                },
              ),
              // 북마크 버튼
              IconButton(
                icon: Consumer<BookmarkProvider>(
                  builder: (context, bookmarkProvider, child) {
                    final isBookmarked = bookmarkProvider.isPageBookmarked(
                      widget.pdfFile.path,
                      _currentPage,
                    );
                    return Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? colorScheme.primary : null,
                    );
                  },
                ),
                onPressed: () => _showAddBookmarkDialog(),
              ),
              // 목차 버튼
              IconButton(
                icon: Icon(
                  Icons.list,
                  color: _showOutline ? colorScheme.primary : null,
                ),
                onPressed: () => _showOutlineDialog(),
              ),
            ],
            bottom: _showSearchBar
                ? _buildSearchBar()
                : null,
          ),
          body: Row(
            children: [
              if (_showThumbnails)
                SizedBox(
                  width: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      controller: _thumbnailScrollController,
                      itemCount: _pdfViewerController.pageCount,
                      itemBuilder: (context, index) {
                        final isCurrentPage = _currentPage == index + 1;
                        return GestureDetector(
                          onTap: () => _pdfViewerController.jumpToPage(index + 1),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isCurrentPage
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                                width: isCurrentPage ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isCurrentPage
                                  ? colorScheme.primaryContainer.withOpacity(0.3)
                                  : null,
                            ),
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: Container(
                                color: colorScheme.surface,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isCurrentPage
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isCurrentPage
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: isCurrentPage ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    SfPdfViewer.file(
                      widget.pdfFile,
                      controller: _pdfViewerController,
                      key: _pdfViewerKey,
                      onPageChanged: (PdfPageChangedDetails details) {
                        if (_currentPage != details.newPageNumber) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                          // 페이지 변경 시 썸네일 스크롤 조정
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToCurrentThumbnail();
                          });
                        }
                      },
                    ),
                    // 페이지 표시기
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '페이지: $_currentPage',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _searchResult.clear();
    _thumbnailScrollController.dispose();  // 컨트롤러 해제
    super.dispose();
  }

  Future<void> _showExtractedText(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 페이지별 텍스트 추출
      final pages = await _pdfService.extractPages(widget.pdfFile);
      
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ExtractedTextView(pages: pages),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('텍스트 추출 실패: $e')),
      );
    }
  }

  Future<void> _showSummary(BuildContext context, String text) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI가 내용을 요약하고 있습니다...'),
            ],
          ),
        ),
      );

      final summary = await _aiService.generateSummary(text);
      
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.9,
            minChildSize: 0.25,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 요약',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(summary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요약 생성 실패: $e')),
        );
      }
    }
  }

  // 북마크 추가 다이얼로그
  Future<void> _showAddBookmarkDialog() async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '북마크 제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '메모 (선택사항)',
                hintText: '메모를 입력하세요',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final bookmark = BookmarkItem(
                  pageNumber: _currentPage,
                  title: titleController.text,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                context.read<BookmarkProvider>().addBookmark(
                      widget.pdfFile.path,
                      bookmark,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  // 북마크 목록 보기
  void _showBookmarksList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          final bookmarks = bookmarkProvider.getBookmarksForFile(widget.pdfFile.path);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '북마크',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return ListTile(
                        title: Text(bookmark.title),
                        subtitle: bookmark.note != null
                            ? Text(bookmark.note!)
                            : null,
                        trailing: Text('${bookmark.pageNumber}페이지'),
                        onTap: () {
                          _pdfViewerController.jumpToPage(bookmark.pageNumber);
                          Navigator.pop(context);
                        },
                        onLongPress: () {
                          // 북마크 삭제 확인 다이얼로그
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('북마크 삭제'),
                              content: const Text('이 북마크를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    bookmarkProvider.removeBookmark(
                                      widget.pdfFile.path,
                                      bookmark,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadOutline() async {
    final pdfViewerState = _pdfViewerKey.currentState;
    if (pdfViewerState != null) {
      // 목차 데이터를 직접 구성
      _outlineData = [
        // 예시 데이터
        {'title': '챕터 1', 'level': 0, 'pageNumber': 1},
        {'title': '섹션 1.1', 'level': 1, 'pageNumber': 2},
        // ... 실제 PDF에서 목차를 파싱하여 추가
      ];
      setState(() {});
    }
  }

  void _showOutlineDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '목차',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (_outlineData == null || _outlineData!.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('목차가 없습니다'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _outlineData!.length,
                  itemBuilder: (context, index) {
                    final item = _outlineData![index];
                    return InkWell(
                      onTap: () {
                        _pdfViewerController.jumpToPage(item['pageNumber'] as int);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.0 * (item['level'] as int).toDouble(),
                          top: 8,
                          bottom: 8,
                        ),
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: (16 - (item['level'] as int)).toDouble(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // AppBar bottom에 들어갈 검색바 위젯
  PreferredSize _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchResult.hasResult) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: () {
                            if (_searchResult.hasResult) {
                              _searchResult.previousInstance();
                            }
                          },
                          tooltip: '이전 결과',
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: () {
                            if (_searchResult.hasResult) {
                              _searchResult.nextInstance();
                            }
                          },
                          tooltip: '다음 결과',
                        ),
                      ],
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _searchResult.clear();
                          },
                          tooltip: '지우기',
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                ),
                onSubmitted: _performSearch,  // Enter 키로 검색
                autofocus: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _performSearch(_searchController.text),  // 검색 버튼
              tooltip: '검색',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showSearchBar = false;
                  _searchController.clear();
                  _searchResult.clear();
                });
              },
              tooltip: '검색 닫기',
            ),
          ],
        ),
      ),
    );
  }

  // 검색 실행 메서드
  void _performSearch(String searchText) async {
    if (searchText.isEmpty) {
      setState(() {
        _searchResult.clear();
      });
      return;
    }

    try {
      // 기본 검색 사용
      final result = await _pdfViewerController.searchText(searchText);
      setState(() {
        _searchResult = result;
        if (_searchResult.hasResult) {
          _searchResult.nextInstance();
        } else {
          // 검색 결과가 없을 때 사용자에게 알림
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('검색 결과가 없습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('검색 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // 썸네일 스크롤 위치 조정 메서드 수정
  void _scrollToCurrentThumbnail() {
    if (!_showThumbnails) return;

    try {
      // 1. 썸네일 항목의 크기 계산
      const double thumbnailAspectRatio = 0.7;
      const double thumbnailWidth = 200.0;
      const double thumbnailHeight = thumbnailWidth * thumbnailAspectRatio;
      const double verticalMargin = 8.0 * 2;
      const double itemHeight = thumbnailHeight + verticalMargin;

      // 2. 현재 보이는 영역과 전체 크기 계산
      final double maxScroll = _thumbnailScrollController.position.maxScrollExtent;
      final int totalPages = _pdfViewerController.pageCount;
      
      // 3. 전체 페이지에서 현재 페이지의 상대적 위치 계산 (0.0 ~ 1.0)
      final double pageProgress = (_currentPage - 1) / (totalPages - 1);
      
      // 4. 전체 스크롤 범위에 현재 페이지의 상대적 위치 적용
      final double scrollTo = maxScroll * pageProgress;

      // 5. 스크롤 애니메이션 실행
      if ((_thumbnailScrollController.offset - scrollTo).abs() > 1.0) {
        _thumbnailScrollController.animateTo(
          scrollTo,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      // 에러 처리는 유지하되 로그 출력 제거
    }
  }
}

class _ExtractedTextView extends StatefulWidget {
  final List<String> pages;

  const _ExtractedTextView({required this.pages});

  @override
  State<_ExtractedTextView> createState() => _ExtractedTextViewState();
}

class _ExtractedTextViewState extends State<_ExtractedTextView> {
  late int currentPage;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentPage = 1;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.25,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '페이지 $currentPage / ${widget.pages.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.pages[currentPage - 1])
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('텍스트가 복사되었습니다')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentPage > 1
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentPage < widget.pages.length
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index + 1;
                  });
                },
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(widget.pages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Intent 클래스들 추가
class ShowOutlineIntent extends Intent {
  const ShowOutlineIntent();
}

class ShowBookmarksIntent extends Intent {
  const ShowBookmarksIntent();
}

class ShowSearchIntent extends Intent {
  const ShowSearchIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
} 