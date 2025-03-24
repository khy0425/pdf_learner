import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../widgets/platform_ad_widget.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
// dart:html는 웹에서만 임포트
import 'dart:html' if (dart.library.io) '../views/web_stub_html.dart' as html;
// ui 네임스페이스도 조건부로 임포트
import 'dart:ui' as ui;
import '../models/pdf_document.dart';
import '../models/pdf_bookmark.dart';
import '../services/subscription_service.dart';
import '../viewmodels/pdf_viewer_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:pdf_learner_v2/widgets/app_bar_widget.dart' hide PDFSearchAppBar;
import 'package:pdf_learner_v2/theme/app_theme.dart';
import 'dart:js_util' as js_util;
import '../viewmodels/ai_summary_viewmodel.dart';
import '../views/ai_summary_page.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';
import '../models/ai_summary.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/pdf_viewer/toolbar_widget.dart';
import '../widgets/pdf_viewer/bottom_bar_widget.dart';
import '../widgets/pdf_viewer/error_widget.dart';
import '../widgets/pdf_viewer/loading_widget.dart';
import '../widgets/pdf_viewer/web_pdf_viewer_widget.dart';
import '../widgets/pdf_viewer/native_pdf_viewer_widget.dart';
import '../widgets/pdf_viewer/pdf_viewer_dialogs.dart';
import '../repositories/pdf_repository.dart';
import '../widgets/pdf_viewer/pdf_viewer.dart';

/// PDF 문서 뷰어 페이지
class PdfViewerPage extends StatefulWidget {
  final String documentId;
  final String? filePath;
  final String? title;
  final bool showAds;
  final bool showRewardButton;
  final PDFDocument? document;
  
  const PdfViewerPage({
    Key? key,
    required this.documentId,
    this.filePath,
    this.title,
    this.showAds = true,
    this.showRewardButton = false,
    this.document,
  }) : super(key: key);
  
  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isFullScreen = false;
  bool _isSearching = false;
  bool _isBottomBarVisible = true;
  
  @override
  void initState() {
    super.initState();
    
    // 전체 화면 모드로 설정
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // 화면 방향 고정 해제 (가로, 세로 모두 허용)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // 웹 환경에서 메시지 리스너 설정
    if (kIsWeb) {
      html.window.addEventListener('message', _handlePdfMessage);
    }
    
    // 항상 바를 표시하도록 설정
    _isFullScreen = false;
    _isBottomBarVisible = true;
  }
  
  @override
  void dispose() {
    // 리소스 정리
    if (kIsWeb) {
      html.window.removeEventListener('message', _handlePdfMessage);
      
      // PDF 컨테이너 제거
      final docIdHash = widget.documentId.hashCode.abs().toString();
      final containerId = 'pdf-container-$docIdHash';
      html.Element? container = html.document.getElementById(containerId);
      if (container != null) {
        container.remove();
      }
    }
    
    // 전체 화면 모드 해제
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 화면 방향 초기화 (세로 방향만 허용)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 화면별 ViewModel 생성 및 초기화
    return ChangeNotifierProvider<PdfViewerViewModel>(
      create: (context) {
        final viewModel = PdfViewerViewModel(
          context.read<PDFRepository>()
        );
        // 나중에가 아니라 즉시 초기화
        viewModel.initWithDocumentId(widget.documentId);
        return viewModel;
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: SafeArea(
              // 전체 화면 모드에서는 SafeArea 무시 - 항상 SafeArea 적용하도록 수정
              left: true,
              top: true,
              right: true,
              bottom: true,
              child: Consumer<PdfViewerViewModel>(
                builder: (context, viewModel, child) => Stack(
                  children: [
                    // PDF 뷰어 또는 에러 메시지
                    if (viewModel.pdfLoadError)
                      PDFErrorWidget(
                        errorMessage: viewModel.errorMessage ?? '알 수 없는 오류',
                        onRetry: () => viewModel.loadDocument(),
                      )
                    else if (kIsWeb)
                      WebPdfViewerWidget(
                        documentId: widget.documentId,
                        viewModel: viewModel,
                        onMessageHandler: _handlePdfMessage,
                        sendPdfMessage: _sendPdfMessage,
                      )
                    else if (!kIsWeb && viewModel.localPath != null)
                      NativePdfViewerWidget(
                        filePath: viewModel.localPath!,
                        viewModel: viewModel,
                      ),
                    
                    // 전체 화면 로딩 상태 표시 (로드 초기 단계)
                    if ((viewModel.isLoading) && 
                        (!viewModel.isViewRegistered || !kIsWeb))
                      const PDFFullScreenLoadingWidget(),
                    
                    // 하단 제어바 - 항상 표시되도록 수정
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: widget.showAds ? 50 : 0, // 광고가 표시될 때 위치 조정
                      child: _buildBottomBar(),
                    ),
                      
                    // 배너 광고
                    if (widget.showAds)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBannerAd(),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
  
  /// PDF 메시지 처리
  void _handlePdfMessage(html.Event event) {
    // 현재 컨텍스트에서 ViewModel을 가져와서 메시지 처리
    final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    WebPdfMessageUtil.handlePdfMessage(event, viewModel);
  }

  /// PDF iframe에 메시지 전송
  void _sendPdfMessage(String message) {
    WebPdfMessageUtil.sendPdfMessage(message, widget.documentId);
  }
  
  /// 배너 광고 위젯
  Widget _buildBannerAd() {
    return Container(
      height: 50,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: const BoxConstraints(
        minHeight: 50,
        maxHeight: 50,
      ),
      child: const PlatformAdWidget(
        adType: AdType.banner,
        adUnitId: 'pdf_viewer_banner',
      ),
    );
  }
  
  /// 앱바 빌드
  PreferredSizeWidget? _buildAppBar() {
    if (_isFullScreen) return null;
    
    // 검색 모드에서는 검색 앱바 표시
    if (_isSearching) {
      return PdfViewerSearchAppBar(
        searchController: _searchController,
        hintText: '문서 내 검색...',
        onBackPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
        },
        onChanged: (value) {
          // 검색 기능 구현
        },
        onClear: () {
          // 검색 하이라이트 제거 기능 구현
        },
      );
    }
    
    // 일반 앱바 표시
    return PDFToolbarWidget(
      title: widget.title ?? 'PDF Viewer',
      onBackPressed: () => Navigator.pop(context),
      onSearchPressed: () {
        setState(() {
          _isSearching = true;
        });
      },
      onBookmarkPressed: _showBookmarks,
      onMoreOptionsPressed: _showMoreOptions,
    );
  }
  
  /// 하단 바 빌드
  Widget _buildBottomBar() {
    return Consumer<PdfViewerViewModel>(
      builder: (context, viewModel, _) {
        if (!_isBottomBarVisible) return const SizedBox.shrink();
        
        return PDFBottomBarWidget(
          currentPage: viewModel.currentPage,
          totalPages: viewModel.totalPages,
          onPreviousPage: () => _sendPdfMessage('previousPage'),
          onNextPage: () => _sendPdfMessage('nextPage'),
          onZoomIn: () => _sendPdfMessage('zoomIn'),
          onZoomOut: () => _sendPdfMessage('zoomOut'),
          onPageChanged: (page) => _sendPdfMessage('goToPage:$page'),
        );
      },
    );
  }
  
  /// 북마크 표시 다이얼로그
  void _showBookmarks() {
    final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    PdfViewerDialogs.showBookmarksDialog(
      context: context,
      bookmarks: viewModel.bookmarks,
      currentPage: viewModel.currentPage,
      onBookmarkSelected: (bookmark) {
        _sendPdfMessage('goToPage:${bookmark.pageNumber}');
        Navigator.pop(context);
      },
      onBookmarkDeleted: (bookmarkId) {
        viewModel.deleteBookmark(bookmarkId);
      },
      onAddBookmark: () {
        PdfViewerDialogs.showAddBookmarkDialog(
          context: context,
          currentPage: viewModel.currentPage,
          onSave: (title) {
            viewModel.addBookmark(
              title,
              viewModel.currentPage,
              0.0
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }
  
  /// 더 많은 옵션 메뉴 표시
  void _showMoreOptions() {
    final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    
    PdfViewerDialogs.showMoreOptionsDialog(
      context: context,
      isFavorite: viewModel.isFavorite,
      onToggleFavorite: () {
        viewModel.toggleFavorite();
        Navigator.pop(context);
      },
      onShare: () {
        viewModel.shareDocument();
        Navigator.pop(context);
      },
      onDownload: () {
        viewModel.downloadDocument();
        Navigator.pop(context);
      },
      onOpenWith: () {
        viewModel.openWithExternalApp();
        Navigator.pop(context);
      },
      onGenerateSummary: () {
        Navigator.pop(context);
        _navigateToSummaryPage();
      },
    );
  }
  
  /// AI 요약 페이지로 이동
  void _navigateToSummaryPage() {
    // 현재 문서 가져오기
    final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    
    // AiSummaryViewModel도 개별 페이지에서 생성하도록 수정
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => AiSummaryViewModel(),
          child: AiSummaryPage(
            documentId: widget.documentId,
            document: viewModel.document,
          ),
        ),
      ),
    );
  }
} 