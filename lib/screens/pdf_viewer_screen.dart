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
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/pdf_file_info.dart';

class PDFViewerScreen extends StatefulWidget {
  final PdfFileInfo pdfFile;

  const PDFViewerScreen({required this.pdfFile, super.key});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  // PDF 뷰어 화면에 필요한 상태 변수들
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
  List<Map<String, dynamic>>? _outlineData;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final ScrollController _thumbnailScrollController = ScrollController();
  final List<String> _highlightedSentences = [];
  bool _showHighlights = true;
  final Color _highlightColor = Colors.yellow.withOpacity(0.3);
  bool _isLoading = false;
  List<Map<String, dynamic>> _bookmarks = [];  // PdfBookmark를 Map으로 변경
  bool _showBookmarks = false;
  
  // PDF 데이터 관련 상태
  bool _isPdfMemoryLoaded = false;
  Uint8List? _loadedBytes; // 메모리에 로드된 PDF 바이트 데이터
  bool _hasError = false;
  String _errorMessage = "";

  // 확대/축소 관련 상수 수정
  static const double _minZoomLevel = 0.05;   // 최소 5%까지 축소 가능
  static const double _maxZoomLevel = 5.0;    // 최대 500%까지 확대 가능
  static const double _zoomStep = 0.05;       // 더 작은 단위로 조절 가능

  // GlobalKey 추가
  final GlobalKey _menuBookKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _quizKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadOutline();
    _loadBookmarks();
    
    // PDF 로딩 시도
    _tryLoadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialProvider>(
      builder: (context, tutorialProvider, _) {
        return Stack(
          children: [
            Shortcuts(
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
                  appBar: _buildAppBar(),
                  body: Stack(
        children: [
                      Row(
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
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.outlineVariant,
                                            width: isCurrentPage ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          color: isCurrentPage
                                              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                              : null,
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 0.7,
                                          child: Container(
                                            color: Theme.of(context).colorScheme.surface,
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: isCurrentPage
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.onSurface,
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
                                // PdfFileInfo의 isWeb 또는 isLocal 속성에 따라 다른 SfPdfViewer 사용
                                _isPdfMemoryLoaded && _loadedBytes != null
                                ? SfPdfViewer.memory(
                                    _loadedBytes!,
                  controller: _pdfViewerController,
                                    key: _pdfViewerKey,
                                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 성공! 페이지 수: ${details.document.pages.count}');
                                      }
                                    },
                                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 실패: ${details.error}, ${details.description}');
                                      }
                                      if (mounted) {
                                        setState(() {
                                          _hasError = true;
                                          _errorMessage = "PDF 문서를 로드할 수 없습니다: ${details.description}";
                                        });
                                      }
                                    },
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
                                  )
                                : widget.pdfFile.hasBytes
                                ? SfPdfViewer.memory(
                                    widget.pdfFile.bytes!,
                                    controller: _pdfViewerController,
                                    key: _pdfViewerKey,
                                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 성공! 페이지 수: ${details.document.pages.count}');
                                      }
                                    },
                                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 실패: ${details.error}, ${details.description}');
                                      }
                                      if (mounted) {
                                        setState(() {
                                          _hasError = true;
                                          _errorMessage = "PDF 문서를 로드할 수 없습니다: ${details.description}";
                                        });
                                      }
                                    },
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
                                  )
                                : widget.pdfFile.isWeb && widget.pdfFile.url != null
                                ? SfPdfViewer.network(
                                    widget.pdfFile.url!,
                                    controller: _pdfViewerController,
                                    key: _pdfViewerKey,
                                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 성공! 페이지 수: ${details.document.pages.count}');
                                      }
                                    },
                                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 실패: ${details.error}, ${details.description}');
                                      }
                                      if (mounted) {
                                        setState(() {
                                          _hasError = true;
                                          _errorMessage = "PDF 문서를 로드할 수 없습니다: ${details.description}";
                                        });
                                      }
                                    },
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
                                  )
                                : widget.pdfFile.isLocal && widget.pdfFile.file != null
                                ? SfPdfViewer.file(
                                    widget.pdfFile.file!,
                                    controller: _pdfViewerController,
                                    key: _pdfViewerKey,
                                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 성공! 페이지 수: ${details.document.pages.count}');
                                      }
                                    },
                                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                      if (kDebugMode) {
                                        print('[PDFViewer] PDF 문서 로드 실패: ${details.error}, ${details.description}');
                                      }
                                      if (mounted) {
                                        setState(() {
                                          _hasError = true;
                                          _errorMessage = "PDF 문서를 로드할 수 없습니다: ${details.description}";
                                        });
                                      }
                                    },
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
                                  )
                                : Container( // PDF를 로드할 수 없는 경우 에러 메시지 표시
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                                        SizedBox(height: 16),
                                        Text(
                                          'PDF를 표시할 수 없습니다', 
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          margin: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey.shade100,
                                          ),
                                          child: Text(
                                            '파일 정보가 유효하지 않습니다. 다시 PDF를 선택해주세요.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('돌아가기'),
                                        ),
                                      ],
                                    ),
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
                                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 4,
          ),
        ],
      ),
                                      child: Text(
                                        '페이지: $_currentPage',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                    ),
            ),
          ),
        ],
      ),
                          ),
                        ],
                      ),
                      _buildLoadingOverlay(),  // 로딩 오버레이 추가
                    ],
                  ),
                  floatingActionButton: FloatingActionButton(
                    key: _helpKey,  // GlobalKey 추가
                    onPressed: _showGuide,
                    tooltip: 'PDF 학습 도우미',
                    child: const Icon(Icons.help_outline),
                  ),
                ),
              ),
            ),
            
            // PDF 뷰어 가이드 오버레이
            if (!tutorialProvider.isPdfViewerGuideShown)
              PDFViewerGuideOverlay(
                menuBookKey: _menuBookKey,
                searchKey: _searchKey,
                summaryKey: _summaryKey,
                quizKey: _quizKey,
                helpKey: _helpKey,
              ),
          ],
        );
      },
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

  Future<void> _showFullSummary(BuildContext context) async {
    try {
      // API 사용량 체크
      if (!await _aiService.checkUsageLimit()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일일 사용량을 초과했습니다. 내일 다시 시도해주세요.')),
        );
        return;
      }

      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI가 문서를 분석중입니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  StreamBuilder<int>(
                    stream: Stream.periodic(
                      const Duration(seconds: 1),
                      (count) => count,
                    ),
                    builder: (context, snapshot) {
                      final tips = [
                        '긴 문서는 시간이 더 걸릴 수 있습니다...',
                        'AI가 내용을 이해하고 있습니다...',
                        '핵심 내용을 추출하고 있습니다...',
                        '요약을 생성하고 있습니다...',
                      ];
                      final index = (snapshot.data ?? 0) % tips.length;
                      return Text(
                        tips[index],
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 텍스트 추출 및 요약 생성
      final text = await _pdfService.extractText(
        widget.pdfFile,
        onProgress: (current, total) {
          // 진행 상황 처리
        },
      );

      if (!mounted) return;
      
      final summary = await _aiService.generateSummary(text);

      // 사용량 증가
      await _aiService.incrementUsage();

      if (!mounted) return;
      Navigator.pop(context);  // 로딩 다이얼로그 닫기

      // 결과 표시
      showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) => _SummaryDialog(summary: summary ?? '요약을 생성할 수 없습니다.'),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요약 생성 실패: $e')),
      );
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
                      widget.pdfFile.localPath ?? widget.pdfFile.id,
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
          final bookmarks = bookmarkProvider.getBookmarksForFile(widget.pdfFile.localPath ?? widget.pdfFile.id);
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
                                      widget.pdfFile.localPath ?? widget.pdfFile.id,
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
              icon: Icon(
                _showSearchBar ? Icons.close : Icons.search,
                color: _showSearchBar ? Theme.of(context).colorScheme.primary : null,
              ),
              tooltip: '검색 (Ctrl + F)',
              onPressed: () => setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _pdfViewerController.clearSelection();
                }
              }),
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

  // 확대/축소 버튼 그룹 수정
  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out),
          tooltip: '축소 (Ctrl + -)',
          onPressed: () => _changeZoomLevel(-_zoomStep),
        ),
        PopupMenuButton<double>(
          tooltip: '배율 선택',
          initialValue: _zoomLevel,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0.05, child: Text('5%')),
            const PopupMenuItem(value: 0.1, child: Text('10%')),
            const PopupMenuItem(value: 0.25, child: Text('25%')),
            const PopupMenuItem(value: 0.5, child: Text('50%')),
            const PopupMenuItem(value: 0.75, child: Text('75%')),
            const PopupMenuItem(value: 1.0, child: Text('100%')),
            const PopupMenuItem(value: 1.5, child: Text('150%')),
            const PopupMenuItem(value: 2.0, child: Text('200%')),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.fullscreen),
                  SizedBox(width: 8),
                  Text('페이지 맞춤'),
                ],
              ),
              onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitToPage();
              }),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.fit_screen),
                  SizedBox(width: 8),
                  Text('너비 맞춤'),
                ],
              ),
              onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitToWidth();
              }),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.height),
                  SizedBox(width: 8),
                  Text('높이 맞춤'),
                ],
              ),
              onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitToHeight();
              }),
            ),
          ],
          onSelected: (value) {
            setState(() {
              _zoomLevel = value;
              _pdfViewerController.zoomLevel = value;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in),
          tooltip: '확대 (Ctrl + +)',
          onPressed: () => _changeZoomLevel(_zoomStep),
        ),
      ],
    );
  }

  // 확대/축소 레벨 변경 메서드
  void _changeZoomLevel(double delta) {
    final newZoomLevel = (_zoomLevel + delta).clamp(_minZoomLevel, _maxZoomLevel);
    if (newZoomLevel != _zoomLevel) {
      setState(() {
        _zoomLevel = newZoomLevel;
        _pdfViewerController.zoomLevel = _zoomLevel;
      });
    }
  }

  // 페이지 맞춤 기능 개선
  void _fitToPage() {
    setState(() {
      _pdfViewerController.zoomLevel = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewerWidth = _pdfViewerKey.currentContext?.size?.width ?? 0;
        final viewerHeight = _pdfViewerKey.currentContext?.size?.height ?? 0;
        if (viewerWidth > 0 && viewerHeight > 0) {
          // 여백을 고려하여 실제 사용 가능한 영역 계산
          final availableWidth = viewerWidth * 0.95;
          final availableHeight = viewerHeight * 0.95;
          
          // 페이지 비율을 고려하여 최적의 줌 레벨 계산
          final widthZoom = availableWidth / (viewerWidth / _zoomLevel);
          final heightZoom = availableHeight / (viewerHeight / _zoomLevel);
          
          final zoomLevel = min(widthZoom, heightZoom);
          _pdfViewerController.zoomLevel = zoomLevel;
          setState(() => _zoomLevel = zoomLevel);
        }
      });
    });
  }

  // 너비 맞춤 기능 수정
  void _fitToWidth() {
    setState(() {
      _pdfViewerController.zoomLevel = 1.0;  // 먼저 기본값으로 리셋
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 너비에 맞추기
        final viewerWidth = _pdfViewerKey.currentContext?.size?.width ?? 0;
        if (viewerWidth > 0) {
          final zoomLevel = _calculateFitToWidthZoom();
          _pdfViewerController.zoomLevel = zoomLevel;
          setState(() => _zoomLevel = zoomLevel);
        }
      });
    });
  }

  // 너비 맞춤 줌 레벨 계산
  double _calculateFitToWidthZoom() {
    final viewerWidth = _pdfViewerKey.currentContext?.size?.width ?? 0;
    if (viewerWidth == 0) return 1.0;

    // 현재 페이지의 크기 정보를 가져옴
    final pdfViewerState = _pdfViewerKey.currentState;
    if (pdfViewerState == null) return 1.0;

    // 페이지 너비를 추정
    final pageWidth = viewerWidth / _zoomLevel;  // 현재 줌 레벨로 역산
    return (viewerWidth / pageWidth) * 0.95; // 여백을 위해 95%로 조정
  }

  // 높이 맞춤 기능 추가
  void _fitToHeight() {
    setState(() {
      _pdfViewerController.zoomLevel = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewerHeight = _pdfViewerKey.currentContext?.size?.height ?? 0;
        if (viewerHeight > 0) {
          final zoomLevel = _calculateFitToHeightZoom();
          _pdfViewerController.zoomLevel = zoomLevel;
          setState(() => _zoomLevel = zoomLevel);
        }
      });
    });
  }

  // 높이 맞춤 줌 레벨 계산
  double _calculateFitToHeightZoom() {
    final viewerHeight = _pdfViewerKey.currentContext?.size?.height ?? 0;
    if (viewerHeight == 0) return 1.0;

    // A4 비율 기준으로 페이지 높이 추정
    const pageAspectRatio = 1.414;  // A4 종이 비율
    final pageHeight = viewerHeight / _zoomLevel;
    
    return (viewerHeight / pageHeight) * 0.95;  // 여백을 위해 95%로 조정
  }

  // AppBar actions 수정
  List<Widget> _buildActions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return [
      _buildZoomControls(),  // 확대/축소 컨트롤 그룹
      const SizedBox(width: 8),
      
      // 검색 버튼
      IconButton(
        icon: Icon(
          _showSearchBar ? Icons.close : Icons.search,
          color: _showSearchBar ? colorScheme.primary : null,
        ),
        tooltip: '검색 (Ctrl + F)',
        onPressed: () => setState(() {
          _showSearchBar = !_showSearchBar;
          if (!_showSearchBar) {
            _pdfViewerController.clearSelection();
          }
        }),
      ),

      // 북마크 버튼
      Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, _) {
          final isBookmarked = bookmarkProvider.isPageBookmarked(
            widget.pdfFile.localPath ?? widget.pdfFile.id,
            _currentPage,
          );
          return IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? colorScheme.primary : null,
            ),
            tooltip: '북마크 (Ctrl + B)',
            onPressed: () => _toggleBookmark(context),
          );
        },
      ),

      // AI 기능 그룹
      PopupMenuButton<String>(
        tooltip: 'AI 기능',
        icon: Icon(Icons.auto_awesome, color: colorScheme.primary),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'highlight',
            child: Row(
              children: [
                Icon(Icons.highlight),
                SizedBox(width: 8),
                Text('핵심 문장 하이라이트'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'quiz',
            child: Row(
              children: [
                Icon(Icons.quiz),
                SizedBox(width: 8),
                Text('AI 퀴즈 생성'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'summary',
            child: Row(
              children: [
                Icon(Icons.summarize),
                SizedBox(width: 8),
                Text('내용 요약'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'highlight':
              _extractAndHighlightKeySentences();
              break;
            case 'quiz':
              _showQuizDialog();
              break;
            case 'summary':
              _showSummaryDialog(context);
              break;
          }
        },
      ),

      // 더보기 메뉴
      PopupMenuButton<String>(
        tooltip: '더보기',
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'bookmarks',
            child: Row(
              children: [
                Icon(Icons.bookmarks),
                SizedBox(width: 8),
                Text('북마크 목록'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'text',
            child: Row(
              children: [
                Icon(Icons.text_snippet),
                SizedBox(width: 8),
                Text('텍스트 추출'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'bookmarks':
              _showBookmarksList();
              break;
            case 'text':
              _showExtractedText(context);
              break;
          }
        },
      ),
    ];
  }

  // 북마크 토글 기능
  void _toggleBookmark(BuildContext context) {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final filePath = widget.pdfFile.localPath ?? widget.pdfFile.id;
    
    if (bookmarkProvider.isPageBookmarked(filePath, _currentPage)) {
      // 북마크 제거
      final bookmark = bookmarkProvider
          .getBookmarksForFile(filePath)
          .firstWhere((b) => b.pageNumber == _currentPage);
      bookmarkProvider.removeBookmark(filePath, bookmark);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크가 제거되었습니다')),
      );
    } else {
      // 북마크 추가 다이얼로그
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('북마크 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '북마크 제목을 입력하세요',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
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
                bookmarkProvider.addBookmark(
                  filePath,
                  BookmarkItem(
                    pageNumber: _currentPage,
                    title: '페이지 $_currentPage',
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('북마크가 추가되었습니다')),
                );
              },
              child: const Text('추가'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _extractAndHighlightKeySentences() async {
    setState(() => _isLoading = true);
    
    try {
      final text = await _extractTextFromCurrentPage();
      final sentences = await _aiService.extractKeySentences(text);
      
      if (!mounted) return;
      setState(() {
        _highlightedSentences.clear();
        _highlightedSentences.addAll(sentences);
        _isLoading = false;
      });

      // 결과 다이얼로그를 슬라이드 애니메이션으로 표시
      showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, 
                         color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('핵심 문장',
                           style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sentences.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200 + (index * 100)),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow.shade100),
                          ),
                          child: Text(
                            sentences[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('핵심 문장 추출 실패: $e')),
      );
    }
  }

  // 현재 페이지의 텍스트 추출
  Future<String> _extractTextFromCurrentPage() async {
    try {
      return await _pdfService.extractPage(
        widget.pdfFile,
        _currentPage,
      );
    } catch (e) {
      print('텍스트 추출 중 오류: $e');
      rethrow;
    }
  }

  // 퀴즈 생성 및 표시 메서드 수정
  Future<void> _showQuizDialog() async {
    try {
      // 페이지 수에 따른 퀴즈 수 계산
      final totalPages = _pdfViewerController.pageCount;
      final quizCount = _calculateQuizCount(totalPages);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _LoadingOverlay(
          message: 'AI가 $quizCount개의 퀴즈를 생성하고 있습니다...',
        ),
      );

      // 선택된 페이지들의 텍스트 추출
      final selectedPages = _selectPagesForQuiz(totalPages, quizCount);
      final pageTexts = await Future.wait(
        selectedPages.map((pageNum) => _pdfService.extractPage(widget.pdfFile, pageNum))
      );
      final combinedText = pageTexts.join('\n\n');

      // 퀴즈 생성 요청
      final quizList = await _aiService.generateQuiz(
        combinedText,
      );

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => _QuizDialog(
          quizList: quizList,
          pageNumbers: selectedPages, // 각 퀴즈가 어느 페이지에서 출제되었는지 표시
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀴즈 생성 실패: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 페이지 수에 따른 퀴즈 수 계산
  int _calculateQuizCount(int totalPages) {
    if (totalPages <= 5) {
      return 3;  // 5페이지 이하: 3문제
    } else if (totalPages <= 10) {
      return 5;  // 6-10페이지: 5문제
    } else if (totalPages <= 20) {
      return 7;  // 11-20페이지: 7문제
    } else if (totalPages <= 50) {
      return 10; // 21-50페이지: 10문제
    } else {
      return 15; // 50페이지 초과: 15문제
    }
  }

  // 퀴즈를 출제할 페이지 선택
  List<int> _selectPagesForQuiz(int totalPages, int quizCount) {
    final selectedPages = <int>[];
    final random = Random();  // Random 인스턴스 생성
    
    // 첫 페이지와 마지막 페이지는 항상 포함
    selectedPages.add(1);
    if (totalPages > 1) {
      selectedPages.add(totalPages);
    }

    // 나머지 페이지는 균등하게 분포되도록 선택
    if (quizCount > 2) {
      final remainingCount = quizCount - 2;
      final interval = (totalPages - 2) / (remainingCount + 1);
      
      for (int i = 1; i <= remainingCount; i++) {
        final basePageNum = (interval * i).round();
        // 약간의 랜덤성 추가 (±1 페이지)
        final pageNum = basePageNum + random.nextInt(3) - 1;
        final normalizedPageNum = pageNum.clamp(2, totalPages - 1);
        
        if (!selectedPages.contains(normalizedPageNum)) {
          selectedPages.add(normalizedPageNum);
        }
      }
    }

    selectedPages.sort();
    return selectedPages;
  }

  // 로딩 상태 오버레이
  Widget _buildLoadingOverlay() {
    if (!_isLoading && !_hasError) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'PDF 로딩 중...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
                if (_hasError) ...[
                  Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PDF 로드 오류',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _tryLoadPdf(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // PDF 로딩 시도
  Future<void> _tryLoadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = "";
      });
      
      if (kDebugMode) {
        print('[PDFViewer] PDF 로딩 시도 - 파일명: ${widget.pdfFile.fileName}');
        print('[PDFViewer] PDF 유형 - isWeb: ${widget.pdfFile.isWeb}, isLocal: ${widget.pdfFile.isLocal}, hasBytes: ${widget.pdfFile.hasBytes}');
      }
      
      // 이미 바이트 데이터가 있는 경우 먼저 사용
      if (widget.pdfFile.hasBytes) {
        setState(() {
          _loadedBytes = widget.pdfFile.bytes;
          _isPdfMemoryLoaded = true;
        });
        if (kDebugMode) {
          print('[PDFViewer] PDF 파일이 이미 바이트 데이터를 가지고 있습니다: ${_loadedBytes?.length} 바이트');
        }
      } 
      // 없는 경우 readAsBytes()로 로드 시도
      else {
        try {
          if (kDebugMode) {
            print('[PDFViewer] 바이트 데이터 로드 시도 중...');
          }
          
          final bytes = await widget.pdfFile.readAsBytes();
          
          if (mounted) {
            setState(() {
              _loadedBytes = bytes;
              _isPdfMemoryLoaded = true;
            });
            
            if (kDebugMode) {
              print('[PDFViewer] PDF 바이트 데이터 로드 성공: ${bytes.length} 바이트');
            }
          }
        } catch (readError) {
          if (kDebugMode) {
            print('[PDFViewer] PDF 바이트 데이터 로드 실패: $readError');
          }
          
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = "PDF 데이터를 로드할 수 없습니다: $readError";
            });
          }
        }
      }
      
      // 500ms 후에 로딩 상태 종료
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "PDF 로딩 중 오류가 발생했습니다: $e";
        });
        
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 로딩 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bytes = await widget.pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final bookmarkList = <Map<String, dynamic>>[];
      
      if (document.bookmarks != null) {
        for (int i = 0; i < document.bookmarks!.count; i++) {
          final bookmark = document.bookmarks![i];
          if (bookmark != null) {
            // 페이지 번호 직접 사용
            bookmarkList.add({
              'title': bookmark.title ?? '제목 없음',
              'pageIndex': i + 1,  // 기본 페이지 번호 사용
            });

            // 하위 북마크 처리
            for (int j = 0; j < bookmark.count; j++) {
              final subBookmark = bookmark[j];
              if (subBookmark != null) {
                bookmarkList.add({
                  'title': '  ${subBookmark.title ?? '제목 없음'}',
                  'pageIndex': j + 1,  // 하위 북마크의 페이지 번호
                });
              }
            }
          }
        }
      }

      setState(() {
        _bookmarks = bookmarkList;
      });

      document.dispose();
    } catch (e) {
      print('목차 로딩 실패: $e');
      setState(() {
        _bookmarks = [];
      });
    }
  }

  Widget _buildBookmarkList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _showBookmarks ? 280 : 0,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              title: const Text('목차'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showBookmarks = false),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = _bookmarks[index];
                  return ListTile(
                    title: Text(bookmark['title']),
                    onTap: () {
                      _pdfViewerController.jumpToPage(bookmark['pageIndex']);
                      setState(() => _showBookmarks = false);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar에 목차 버튼 추가
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('PDF 학습'),
          actions: [
        // 목차 버튼
        IconButton(
          key: _menuBookKey,  // GlobalKey 추가
          icon: const Icon(Icons.menu_book),
          tooltip: '목차',
          onPressed: () => setState(() => _showBookmarks = !_showBookmarks),
        ),
        // 검색 버튼
        IconButton(
          key: _searchKey,  // GlobalKey 추가
          icon: const Icon(Icons.search),
          tooltip: '검색',
          onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
        ),
        // AI 요약 버튼
        IconButton(
          key: _summaryKey,  // GlobalKey 추가
          icon: const Icon(Icons.summarize),
          tooltip: 'AI 요약',
          onPressed: () => _showSummaryDialog(context),
        ),
        // 퀴즈 생성 버튼
        IconButton(
          key: _quizKey,  // GlobalKey 추가
          icon: const Icon(Icons.quiz),
          tooltip: '퀴즈 생성',
          onPressed: () => _showQuizDialog(),
        ),
      ],
    );
  }

  // 도우미 버튼 클릭 시 가이드 표시
  void _showGuide() {
    context.read<TutorialProvider>().resetPDFViewerGuide();
  }

  Future<void> _showSummaryDialog(BuildContext context) async {
    try {
      // 현재 페이지의 텍스트 추출
      final currentPageText = await _pdfService.extractPage(
        widget.pdfFile,
        _currentPage,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LoadingOverlay(
          message: 'AI가 내용을 요약하고 있습니다...',
        ),
      );

      // AI 요약 생성
      final summary = await _aiService.generateSummary(currentPageText);
      
      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      // 요약 결과 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_currentPage}페이지 요약'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주요 내용:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(summary ?? '요약을 생성할 수 없습니다.'),
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
    } catch (e) {
      if (!mounted) return;
      
      // 에러가 발생한 경우 로딩 다이얼로그가 떠있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('요약 생성 실패: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
      builder: (context, scrollController) {
        return Container(
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
                            ClipboardData(text: widget.pages[currentPage - 1]),
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
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index + 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        widget.pages[index],
                        style: const TextStyle(height: 1.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

// 세련된 로딩 위젯 추가
class _LoadingOverlay extends StatelessWidget {
  final String? message;

  const _LoadingOverlay({
    this.message = 'AI가 PDF를 분석하고 있습니다',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '잠시만 기다려주세요...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 요약 결과를 보여주는 위젯
class _SummaryDialog extends StatelessWidget {
  final String summary;
  
  const _SummaryDialog({
    Key? key,
    required this.summary,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 요약 결과',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 퀴즈 다이얼로그 위젯
class _QuizDialog extends StatefulWidget {
  final List<Map<String, dynamic>> quizList;
  final List<int> pageNumbers;  // 각 퀴즈의 출제 페이지 번호

  const _QuizDialog({
    required this.quizList,
    required this.pageNumbers,
  });

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  int _currentQuizIndex = 0;
  late List<int?> _userAnswers;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.quizList.length, null);
  }

  @override
  Widget build(BuildContext context) {
    // 퀴즈 리스트가 비어있는 경우 처리
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
    
    // 옵션이 없는 경우 처리
    if (options.isEmpty) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('퀴즈 옵션을 불러올 수 없습니다.'),
        ),
      );
    }

    final correctAnswer = currentQuiz['answer'] as int? ?? 0;
    final userAnswer = _userAnswers[_currentQuizIndex];
    final hasAnswered = userAnswer != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              currentQuiz['question'] as String? ?? '문제를 불러올 수 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (final entry in options.asMap().entries)
              _buildQuizOption(
                entry.key,
                entry.value,
                userAnswer == entry.key,
                hasAnswered,
                hasAnswered && entry.key == correctAnswer,
                hasAnswered && userAnswer == entry.key && entry.key != correctAnswer,
              ),
            if (_showExplanation && hasAnswered) ...[
              const SizedBox(height: 16),
              Container(
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
              ),
            ],
            const SizedBox(height: 24),
            Row(
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
            ),
          ],
        ),
      ),
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
          aiService: AIService(),
        ),
      ),
    );
  }

  // 퀴즈 옵션 관련 코드 수정
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
                        : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            title: Text(
              option,
              style: TextStyle(
                color: hasAnswered
                    ? isCorrect
                        ? Colors.green
                        : isWrong
                            ? Colors.red
                            : null
                    : isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    hasAnswered
                        ? isCorrect
                            ? Icons.check_circle
                            : Icons.cancel
                        : Icons.radio_button_checked,
                    color: hasAnswered
                        ? isCorrect
                            ? Colors.green
                            : Colors.red
                        : Theme.of(context).colorScheme.primary,
                  )
                : hasAnswered
                    ? null
                    : const Icon(Icons.radio_button_unchecked),
          ),
        ),
      ),
    );
  }
} 