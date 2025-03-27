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

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfViewerController _pdfViewerController;
  bool _isFullScreen = false;
  bool _isBookmarksVisible = false;
  int _currentPage = 0;
  late PDFViewerViewModel _viewModel;
  bool _isLoading = false;
  final TextEditingController _searchTextController = TextEditingController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
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
    });
  }
  
  @override
  void dispose() {
    // 뷰어가 닫힐 때 현재 페이지 저장
    _viewModel.saveCurrentPage(_viewModel.currentPage);
    _pdfViewerController.dispose();
    _searchTextController.dispose();
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
            appBar: viewModel.isFullScreen 
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
                                  viewModel.document?.title ?? '문서',
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
                                      '${viewModel.currentPage}/${viewModel.document?.pageCount ?? 0} 페이지',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                        value: viewModel.document != null && viewModel.document!.pageCount > 0 
                                            ? viewModel.currentPage / viewModel.document!.pageCount 
                                            : 0,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.grey.shade700,
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
                            icon: viewModel.document?.isFavorite ?? false
                              ? Icons.favorite
                              : Icons.favorite_border,
                            color: viewModel.document?.isFavorite ?? false
                              ? Colors.red
                              : Colors.grey.shade700,
                          onTap: () {
                              if (viewModel.isGuestMode) {
                              _showGuestModeAdDialog(context);
                            } else {
                                _toggleFavorite(context);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildViewerButton(
                          icon: Icons.bookmark_border_rounded,
                          onTap: () {
                              if (viewModel.isGuestMode) {
                              _showGuestModeAdDialog(context);
                            } else {
                                viewModel.setBookmarksVisible(!viewModel.isBookmarksVisible);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildViewerButton(
                          icon: Icons.fullscreen_rounded,
                          onTap: () {
                              viewModel.setFullScreen(true);
                          },
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            body: _buildBody(context),
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
  
  // PDF 뷰어 왼쪽 컨트롤러에 사용할 버튼 위젯
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.grey.shade700,
            ),
          ),
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
          Text(text),
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

  // PDF 뷰어 위젯 구성
  Widget _buildPdfViewer(BuildContext context) {
    return Consumer<PDFViewerViewModel>(
      builder: (context, viewModel, child) {
    // 웹 환경인지 확인
    if (kIsWeb) {
      // 웹 환경에서는 메모리에서 PDF 로드 또는 URL을 통해 로드
      return FutureBuilder<Uint8List>(
            future: viewModel.loadPdf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            // PDF 데이터가 로드되었으면 표시
            return SfPdfViewer.memory(
              snapshot.data!,
              pageSpacing: 0,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: true,
              enableDocumentLinkAnnotation: true,
              enableHyperlinkNavigation: true,
                  initialPageNumber: viewModel.currentPage,
              controller: _pdfViewerController,
              interactionMode: PdfInteractionMode.selection,
              pageLayoutMode: PdfPageLayoutMode.single,
              onPageChanged: (PdfPageChangedDetails details) {
                    viewModel.saveCurrentPage(details.newPageNumber);
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                // 문서 로드 완료 후 초기 페이지로 이동
                    if (viewModel.currentPage > 0) {
                      _pdfViewerController.jumpToPage(viewModel.currentPage);
                }
              },
            );
          } else if (snapshot.hasError) {
            // 오류 발생 시
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 72, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF를 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '오류: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // 로딩 중
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('PDF 로딩 중...'),
                ],
              ),
            );
          }
        },
      );
    } else {
      // 네이티브 환경에서는 파일 시스템에서 PDF 로드
          if (viewModel.document == null) {
            return const Center(child: Text('문서를 불러올 수 없습니다.'));
          }
          
      return SfPdfViewer.file(
            File(viewModel.document!.filePath),
        controller: _pdfViewerController,
        onPageChanged: (PdfPageChangedDetails details) {
              viewModel.saveCurrentPage(details.newPageNumber);
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          // 문서 로드 완료 후 초기 페이지로 이동
              if (viewModel.currentPage > 0) {
                _pdfViewerController.jumpToPage(viewModel.currentPage);
              }
              
              // 로드 완료 후 PDF 페이지 수 업데이트 (문서 정보가 다르면)
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
      );
    }
      },
    );
  }

  // 전체 본문 영역 구성
  Widget _buildBody(BuildContext context) {
    return Consumer<PDFViewerViewModel>(
      builder: (context, viewModel, child) {
        return Row(
          children: [
            // 왼쪽 PDF 컨트롤러 패널
            if (!viewModel.isFullScreen)
              Container(
                width: 60,
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    _buildControlButton(
                      icon: Icons.zoom_in,
                      tooltip: '확대',
                      onPressed: () {
                        _pdfViewerController.zoomLevel += 0.25;
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.zoom_out,
                      tooltip: '축소',
                      onPressed: () {
                        _pdfViewerController.zoomLevel -= 0.25;
                      },
                    ),
                    const Divider(height: 32),
                    _buildControlButton(
                      icon: Icons.navigate_before,
                      tooltip: '이전 페이지',
                      onPressed: () {
                        if (viewModel.currentPage > 1) {
                          _pdfViewerController.previousPage();
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${viewModel.currentPage}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildControlButton(
                      icon: Icons.navigate_next,
                      tooltip: '다음 페이지',
                      onPressed: () {
                        if (viewModel.document != null && 
                            viewModel.currentPage < viewModel.document!.pageCount) {
                          _pdfViewerController.nextPage();
                        }
                      },
                    ),
                    const Spacer(),
                    _buildControlButton(
                      icon: Icons.brightness_medium,
                      tooltip: '다크 모드',
                      onPressed: () {
                        // 다크 모드 기능 구현
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.search,
                      tooltip: '검색',
                      onPressed: () {
                        // 검색 기능 구현
                      },
                    ),
                  ],
                ),
              ),
              
            // 중앙 PDF 뷰어
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // PDF 뷰어
                  _buildPdfViewer(context),
                  
                  // 전체 화면 모드 종료 버튼
                  if (viewModel.isFullScreen)
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
                            viewModel.setFullScreen(false);
                          },
                        ),
                      ),
                    ),
                  
                  // 미회원 모드 안내 (진행 중 안내 표시)
                  if (viewModel.isGuestMode && 
                      viewModel.document != null &&
                      viewModel.currentPage > viewModel.document!.pageCount * 0.2)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '광고를 시청하여 AI 기능 사용 횟수를 늘릴 수 있습니다.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.videocam_outlined, size: 16),
                              label: const Text('광고 시청'),
                              onPressed: () {
                                _showGuestModeAdDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.grey.shade800,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 오른쪽 AI 기능 패널
            if (!viewModel.isFullScreen)
              _buildAIFeaturesPanel(context),
          ],
        );
      },
    );
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
                    label: const Text('광고 시청으로 AI 사용량 충전'),
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
  
  // AI 기능 사용 처리
  void _handleAIFeatureUsage({
    required BuildContext context, 
    required String featureName,
    required bool canUse,
    required VoidCallback useFeature,
  }) {
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
} 