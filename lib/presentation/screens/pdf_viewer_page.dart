import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pdf_viewer_viewmodel.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../widgets/bookmark_dialog.dart';
import 'package:http/http.dart' as http;
import '../../core/localization/app_localizations.dart';
import '../../services/pdf/pdf_service.dart';
import '../../data/datasources/pdf_local_datasource.dart';
import '../widgets/pdf_viewer_guide_overlay.dart';
import '../widgets/bookmark_list.dart';
import '../widgets/guide_overlay_widget.dart';

class PDFViewerPage extends StatefulWidget {
  final PDFDocument? document;
  final String? documentId;
  final int initialPage;
  
  const PDFViewerPage({
    Key? key,
    this.document,
    this.documentId,
    this.initialPage = 0,
  }) : super(key: key);
  
  /// 라우트에서 인자 추출
  static PDFViewerPage fromArguments(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return const PDFViewerPage();
    }
    
    return PDFViewerPage(
      document: args['pdfDocument'] as PDFDocument?,
      documentId: args['documentId'] as String?,
      initialPage: args['initialPage'] as int? ?? 0,
    );
  }

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> with TickerProviderStateMixin {
  late PdfViewerController _pdfViewerController;
  bool _isFullScreen = false;
  bool _isBookmarksVisible = false;
  int _currentPage = 0;
  late PDFViewerViewModel _viewModel;
  bool _isLoading = false;
  final TextEditingController _searchTextController = TextEditingController();
  
  // UniqueKey 사용 - 고유한 식별자로 GlobalKey를 완전히 대체
  final _pdfViewerKey = UniqueKey();
  
  // 일반 버튼은 ValueKey 사용 (GlobalKey 대신)
  final _menuButtonKey = ValueKey('menu_button');
  final _searchButtonKey = ValueKey('search_button');
  final _summaryButtonKey = ValueKey('summary_button');
  final _quizButtonKey = ValueKey('quiz_button');
  final _helpButtonKey = ValueKey('help_button');
  
  bool _showToc = false;
  bool _showSearch = false;
  bool _showSummary = false;
  bool _showQuiz = false;
  bool _showHelp = false;
  
  double _pdfViewerHeight = 0;
  double _pdfViewerWidth = 0;
  
  late PdfInteractionMode _interactionMode;
  
  // 오버레이 엔트리 관리
  OverlayEntry? _overlayEntry;
  
  // 가이드 표시 여부
  bool _showGuide = false;
  
  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    
    // ViewModel 초기화
    final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final pdfRepository = Provider.of<PDFRepository>(context, listen: false);
    final pdfService = Provider.of<PDFService>(context, listen: false);
    final pdfLocalDataSource = Provider.of<PDFLocalDataSource>(context, listen: false);
    
    _viewModel = PDFViewerViewModel(
      pdfRepository: pdfRepository,
      pdfViewModel: pdfViewModel, 
      authViewModel: authViewModel,
      pdfService: pdfService,
      localDataSource: pdfLocalDataSource,
      initialDocument: widget.document,
      documentId: widget.documentId,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 위젯 초기 페이지 설정: widget.initialPage와 _viewModel.currentPage 중 우선순위 결정
      int targetPage = widget.initialPage > 0 ? widget.initialPage : _viewModel.currentPage;
      
      if (targetPage > 0) {
        _pdfViewerController.jumpToPage(targetPage);
      }
      
      // 초기 설정 후 가이드 표시 여부 확인
      final shouldShowGuide = true; // 실제로는 저장된 설정에 따라 결정
      
      if (shouldShowGuide && mounted) {
        _showGuideOverlay();
      }
    });
  }
  
  @override
  void dispose() {
    // 뷰어가 닫힐 때 현재 페이지 저장
    _viewModel.saveCurrentPage(_viewModel.currentPage);
    _pdfViewerController.dispose();
    _searchTextController.dispose();
    // 오버레이 제거
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<PDFViewerViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(viewModel.document?.title ?? '문서'),
              actions: [
                // 검색 버튼
                IconButton(
                  key: _searchButtonKey,
                  icon: const Icon(Icons.search),
                  tooltip: '검색',
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                    });
                  },
                ),
                
                // 요약 버튼
                IconButton(
                  key: _summaryButtonKey,
                  icon: const Icon(Icons.summarize),
                  tooltip: 'AI 요약',
                  onPressed: () {
                    // AI 요약 기능 로직
                  },
                ),
                
                // 퀴즈 버튼
                IconButton(
                  key: _quizButtonKey,
                  icon: const Icon(Icons.quiz),
                  tooltip: '퀴즈 생성',
                  onPressed: () {
                    // 퀴즈 생성 로직
                  },
                ),
                
                // 도움말 버튼
                IconButton(
                  key: _helpButtonKey,
                  icon: const Icon(Icons.help_outline),
                  tooltip: '도움말',
                  onPressed: _onHelpButtonPressed,
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SfPdfViewer.file(
                        File(viewModel.document!.filePath),
                        key: _pdfViewerKey,
                        controller: _pdfViewerController,
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          if (viewModel.currentPage > 0) {
                            _pdfViewerController.jumpToPage(viewModel.currentPage);
                          }
                          
                          if (viewModel.document != null && 
                              details.document.pages.count != viewModel.document!.pageCount) {
                            final updatedDocument = viewModel.document!.copyWith(
                              pageCount: details.document.pages.count,
                            );
                            Provider.of<PDFViewModel>(context, listen: false).updateDocument(updatedDocument);
                          }
                        },
                        enableDoubleTapZooming: true,
                        enableTextSelection: true,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        canShowPaginationDialog: true,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        interactionMode: PdfInteractionMode.selection,
                      ),
                    ),
                  ],
                ),
                // 검색 패널 표시 (조건부)
                if (_showSearch) _buildSearchPanel(),
                
                // 책갈피 패널 표시 (조건부)
                if (viewModel.isBookmarksVisible) _buildBookmarkPanel(),
                
                // 화면 중앙 메시지 표시 (조건부)
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              key: _menuButtonKey,
              child: const Icon(Icons.menu_book),
              onPressed: () {
                // ... 목차 기능 ...
              },
            ),
          );
        },
      ),
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
  
  // PDF 뷰어 왼쪽 컨트롤러에 사용할 버튼 위젯 - GlobalKey 제거
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color ?? Theme.of(context).iconTheme.color,
          tooltip: tooltip,
        ),
      ),
    );
  }

  // AI 기능 카드 위젯
  Widget _buildAIFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String usageLeft,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isLocked ? Colors.grey.shade400 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLocked ? Colors.grey.shade400 : Colors.grey.shade800,
                        inherit: true,
                      ),
                    ),
                  ),
                  if (isLocked)
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isLocked ? Colors.grey.shade400 : Colors.grey.shade600,
                  inherit: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용 가능: $usageLeft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey.shade400 : Colors.grey.shade700,
                      inherit: true,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isLocked ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 혜택 아이템 위젯
  Widget _buildRewardItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: const Color(0xFF388E3C),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(inherit: true),
          ),
        ],
      ),
    );
  }
  
  // 즐겨찾기 토글 처리
  void _toggleFavorite(BuildContext context) async {
    final viewModel = Provider.of<PDFViewerViewModel>(context, listen: false);
    
    if (!viewModel.hasAuthUser) {
      _showLoginRequiredDialog(context, '즐겨찾기');
      return;
    }
    
    final result = await viewModel.toggleFavorite();
    
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.document?.isFavorite ?? false
                  ? '즐겨찾기에서 제거되었습니다.'
                  : '즐겨찾기에 추가되었습니다.',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
  
  // 북마크 추가
  void _addBookmark(BuildContext context) async {
    final viewModel = Provider.of<PDFViewerViewModel>(context, listen: false);
    
    if (!viewModel.hasAuthUser) {
      _showLoginRequiredDialog(context, '북마크');
      return;
    }
    
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => BookmarkDialog(
        titleController: titleController,
        noteController: noteController,
      ),
    );
    
    if (result != null) {
      // 현재 선택된 텍스트 가져오기
      // SyncFusion의 API가 변경되었거나 없는 경우 빈 문자열 사용
      String selectedText = '';
      
      try {
        // 향후 SyncFusion에서 API 제공시 사용
        // selectedText = _pdfViewerController.getSelectedText() ?? '';
      } catch (e) {
        debugPrint('선택된 텍스트 가져오기 오류: $e');
      }
      
      final bookmarkResult = await viewModel.addBookmark(
        title: result['title'] ?? '',
        note: result['note'] ?? '',
        selectedText: selectedText,
      );
      
      bookmarkResult.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('북마크가 저장되었습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('북마크 저장 실패: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }
  
  // 로그인 필요 다이얼로그 표시
  void _showLoginRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그인 필요'),
        content: Text('$feature 기능을 사용하려면 로그인이 필요합니다.'),
        actions: [
          TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
            child: Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 로그인 페이지로 이동
              Navigator.of(context).pushNamed('/login');
            },
            child: Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  // 기능 사용 안내 스낵바 표시
  void _showFeatureUsageSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능을 사용합니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // 게스트 모드 광고 시청 안내 다이얼로그
  void _showGuestModeAdDialog(BuildContext context) {
    final viewModel = Provider.of<PDFViewerViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI 기능 사용량 충전'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('광고를 시청하여 AI 기능 사용량을 충전할 수 있습니다.'),
            SizedBox(height: 12),
            Text('충전 시 다음 혜택이 제공됩니다:'),
            SizedBox(height: 8),
            _buildRewardItem('문서 요약 1회'),
            _buildRewardItem('PDF와 대화 1회'),
            _buildRewardItem('퀴즈 생성 1회'),
            _buildRewardItem('마인드맵 생성 1회'),
            SizedBox(height: 16),
            Text(
              '* 프리미엄 구독 시 모든 AI 기능을 무제한으로 사용할 수 있습니다.',
                          style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('취소'),
                      ),
                      ElevatedButton.icon(
            icon: Icon(Icons.videocam),
            label: Text('광고 시청하기'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          
              // 광고 시청 로직 & 보상 지급
              viewModel.rewardAfterAd();
                          
              // 광고 시청 완료 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('AI 기능 사용량이 충전되었습니다!'),
                  backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424242),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
        ],
      ),
    );
  }

  // 검색 기능 구현
  Widget _buildSearchPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchTextController,
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _searchText(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _searchTextController.clear();
                      _pdfViewerKey.currentState?.clearTextSelection();
                    });
                  },
                  tooltip: '검색 닫기',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('이전'),
                  onPressed: () {
                    _pdfViewerKey.currentState?.searchText(
                      _searchTextController.text,
                      searchOption: TextSearchOption.previous,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('다음'),
                  onPressed: () {
                    _pdfViewerKey.currentState?.searchText(
                      _searchTextController.text,
                      searchOption: TextSearchOption.next,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchText(String text) {
    if (text.isEmpty) return;
    
    _pdfViewerKey.currentState?.searchText(
      text,
      searchOption: TextSearchOption.caseSensitive,
    );
  }

  // 북마크 패널 구현
  Widget _buildBookmarkPanel() {
    return Consumer<PDFViewerViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          width: 300,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '북마크',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          inherit: true,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // 상태 업데이트는 다음 프레임에서 진행
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            viewModel.setBookmarksVisible(false);
                          }
                        });
                      },
                      tooltip: '북마크 패널 닫기',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // 북마크 목록
              Expanded(
                child: BookmarkList(
                  bookmarks: viewModel.bookmarks,
                  isLoading: viewModel.isBookmarksLoading,
                  onBookmarkTap: (bookmark) {
                    // 해당 페이지로 이동
                    _pdfViewerController.jumpToPage(bookmark.pageNumber);
                    // 선택된 텍스트 하이라이트 (syncfusion API가 지원하면)
                  },
                  onEditTap: (bookmark) {
                    _showEditBookmarkDialog(context, bookmark);
                  },
                  onDeleteTap: (bookmark) {
                    _showDeleteBookmarkDialog(context, bookmark);
                  },
                ),
              ),
              
              // 하단 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('새 북마크 추가', style: TextStyle(inherit: true)),
                  onPressed: () {
                    _addBookmark(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
  
  // 북마크 수정 다이얼로그
  void _showEditBookmarkDialog(BuildContext context, PDFBookmark bookmark) {
    final titleController = TextEditingController(text: bookmark.title);
    final noteController = TextEditingController(text: bookmark.note);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '북마크 제목 입력',
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  hintText: '메모 입력 (선택사항)',
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('제목을 입력해주세요.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              
              final viewModel = Provider.of<PDFViewerViewModel>(context, listen: false);
              final result = await viewModel.updateBookmark(
                bookmarkId: bookmark.id,
                title: titleController.text.trim(),
                note: noteController.text.trim(),
              );
              
              result.when(
                success: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('북마크가 수정되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                failure: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('북마크 수정 실패: $error'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  // 북마크 삭제 확인 다이얼로그
  void _showDeleteBookmarkDialog(BuildContext context, PDFBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 삭제'),
        content: Text('\'${bookmark.title}\' 북마크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final viewModel = Provider.of<PDFViewerViewModel>(context, listen: false);
              final result = await viewModel.removeBookmark(bookmark.id);
              
              result.when(
                success: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('북마크가 삭제되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                failure: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('북마크 삭제 실패: $error'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 오버레이를 통한 가이드 표시 메소드
  void _showGuideOverlay() {
    // 현재 컨텍스트의 오버레이 상태 가져오기
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;
    
    // 화면 크기 정보
    final screenSize = MediaQuery.of(context).size;
    
    // AppBar와 화면 상단의 안전 영역 계산
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = appBarHeight + statusBarHeight;
    
    // 버튼 위치는 AppBar 안에 있는 아이콘 버튼들의 위치를 추정
    final appBarButtonWidth = 48.0; // 일반적인 IconButton 너비
    final appBarCenterY = topPadding - (appBarHeight / 2);
    
    // 앱의 주요 영역에 대한 상대적 위치 계산 (추정치)
    Map<String, Offset> buttonPositions = {
      'menu': Offset(screenSize.width - 40, screenSize.height - 40), // FloatingActionButton 위치 (우측 하단)
      'search': Offset(screenSize.width - (appBarButtonWidth * 4), appBarCenterY), // AppBar에서 오른쪽에서 4번째 버튼
      'summary': Offset(screenSize.width - (appBarButtonWidth * 3), appBarCenterY), // AppBar에서 오른쪽에서 3번째 버튼
      'quiz': Offset(screenSize.width - (appBarButtonWidth * 2), appBarCenterY), // AppBar에서 오른쪽에서 2번째 버튼
      'help': Offset(screenSize.width - (appBarButtonWidth * 1), appBarCenterY), // AppBar에서 맨 오른쪽 버튼
    };
    
    // 가이드 단계 정보 생성
    List<GuideStepInfo> steps = [
      GuideStepInfo(
        id: 'menu',
        title: '목차 기능',
        description: 'PDF 문서의 목차를 확인하고 원하는 페이지로 이동할 수 있습니다.',
        icon: Icons.menu_book,
      ),
      GuideStepInfo(
        id: 'search',
        title: '검색 기능',
        description: '문서 내에서 특정 키워드를 검색할 수 있습니다.',
        icon: Icons.search,
      ),
      GuideStepInfo(
        id: 'summary',
        title: 'AI 요약 기능',
        description: 'AI가 문서의 주요 내용을 요약해 줍니다.',
        icon: Icons.summarize,
      ),
      GuideStepInfo(
        id: 'quiz',
        title: 'AI 퀴즈 생성 기능',
        description: 'AI가 문서 내용을 기반으로 퀴즈를 생성합니다.',
        icon: Icons.quiz,
      ),
      GuideStepInfo(
        id: 'help',
        title: '도움말',
        description: '문서 뷰어 사용법과 기능에 대한 도움말을 확인할 수 있습니다.',
        icon: Icons.help_outline,
      ),
    ];
    
    // 오버레이 엔트리 생성
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GuideOverlayWidget(
          screenSize: screenSize,
          buttonPositions: buttonPositions,
          steps: steps,
          onFinish: () {
            // 오버레이 제거
            _overlayEntry?.remove();
            _overlayEntry = null;
            
            // 가이드 표시 상태 저장
            _saveGuideShownStatus();
          },
        );
      },
    );
    
    // 오버레이 삽입
    overlayState.insert(_overlayEntry!);
  }
  
  // 도움말 버튼 클릭 이벤트 처리
  void _onHelpButtonPressed() {
    // 가이드 오버레이 표시
    _showGuideOverlay();
  }
  
  // 가이드 표시 상태 저장 (SharedPreferences 활용)
  void _saveGuideShownStatus() async {
    try {
      // 향후 구현: SharedPreferences를 사용하여 가이드 표시 여부 저장
      debugPrint('가이드 완료 상태 저장');
      
      // 다음에는 가이드를 자동으로 표시하지 않도록 저장하는 코드 추가
      // 예: SharedPreferences.getInstance().then((prefs) => prefs.setBool('guide_shown', true));
    } catch (e) {
      debugPrint('가이드 상태 저장 오류: $e');
    }
  }

  // AI 기능 사용 처리
  void _handleAIFeatureUsage({
    required BuildContext context, 
    required String featureName,
    required bool canUse,
    required VoidCallback useFeature,
  }) {
    // 다음 프레임에서 처리 (빌드 중 setState 호출 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (Provider.of<PDFViewerViewModel>(context, listen: false).isGuestMode) {
          if (canUse) {
            useFeature();
            _showFeatureUsageSnackBar(context, featureName);
            // 기능 구현 (향후 추가)
          } else {
            _showGuestModeAdDialog(context);
          }
        } else {
          _showFeatureUsageSnackBar(context, featureName);
          // 기능 구현 (향후 추가)
        }
      }
    });
  }

  // AI 기능 패널 구성
  Widget _buildAIFeaturesPanel(BuildContext context) {
    return Consumer<PDFViewerViewModel>(
      builder: (context, viewModel, child) {
        final authViewModel = viewModel.authViewModel;
        
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI 기능 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade50,
                child: Text(
                  'AI 도우미',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    inherit: true,
                  ),
                ),
              ),
              
              // AI 기능 목록
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAIFeatureCard(
                        icon: Icons.summarize,
                        title: '문서 요약',
                        description: '현재 문서의 내용을 AI로 요약합니다.',
                        usageLeft: authViewModel.isGuestMode ? '${authViewModel.summarizeUsageCount}회 남음' : '무제한',
                        onTap: () {
                          _handleAIFeatureUsage(
                            context: context,
                            featureName: '문서 요약',
                            canUse: authViewModel.canUseSummarize,
                            useFeature: () => viewModel.useSummarize(),
                          );
                        },
                      ),
                      _buildAIFeatureCard(
                        icon: Icons.chat,
                        title: 'PDF와 대화',
                        description: '문서 내용에 대해 질문하고 답변을 받습니다.',
                        usageLeft: authViewModel.isGuestMode ? '${authViewModel.chatUsageCount}회 남음' : '무제한',
                        onTap: () {
                          _handleAIFeatureUsage(
                            context: context,
                            featureName: 'PDF와 대화',
                            canUse: authViewModel.canUseChat,
                            useFeature: () => viewModel.useChat(),
                          );
                        },
                      ),
                      _buildAIFeatureCard(
                        icon: Icons.quiz,
                        title: '퀴즈 생성',
                        description: '문서 내용 기반으로 학습용 퀴즈를 생성합니다.',
                        usageLeft: authViewModel.isGuestMode 
                          ? (authViewModel.quizUsageCount > 0 ? '${authViewModel.quizUsageCount}회 남음' : '광고 시청 필요') 
                          : '무제한',
                        isLocked: authViewModel.isGuestMode && authViewModel.quizUsageCount == 0,
                        onTap: () {
                          _handleAIFeatureUsage(
                            context: context,
                            featureName: '퀴즈 생성',
                            canUse: authViewModel.canUseQuiz,
                            useFeature: () => viewModel.useQuiz(),
                          );
                        },
                      ),
                      _buildAIFeatureCard(
                        icon: Icons.account_tree,
                        title: '마인드맵 생성',
                        description: '문서 내용을 시각적 마인드맵으로 변환합니다.',
                        usageLeft: authViewModel.isGuestMode 
                          ? (authViewModel.mindmapUsageCount > 0 ? '${authViewModel.mindmapUsageCount}회 남음' : '광고 시청 필요') 
                          : '무제한',
                        isLocked: authViewModel.isGuestMode && authViewModel.mindmapUsageCount == 0,
                        onTap: () {
                          _handleAIFeatureUsage(
                            context: context,
                            featureName: '마인드맵 생성',
                            canUse: authViewModel.canUseMindmap,
                            useFeature: () => viewModel.useMindmap(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // 하단 광고 시청 버튼 (미회원 모드인 경우)
              if (authViewModel.isGuestMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text(
                      '광고 시청으로 AI 사용량 충전',
                      style: TextStyle(inherit: true),
                    ),
                    onPressed: () {
                      _showGuestModeAdDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
} 