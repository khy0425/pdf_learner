import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import '../models/pdf_document.dart';
import '../viewmodels/pdf_viewer_viewmodel.dart';
import '../services/auth_service.dart';
import '../views/premium_subscription_page.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// 네이티브 환경에서는 실제 File 클래스 사용, 웹에서는 스텁 사용
// 주의: 스텁 클래스는 SfPdfViewer.file에 직접 전달하면 안됨
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart' as io;

class PDFViewerPage extends StatefulWidget {
  final String filePath;
  
  const PDFViewerPage({
    Key? key,
    required this.filePath,
  }) : super(key: key);
  
  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  bool _isSearching = false;
  bool _isToolbarVisible = true;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  
  late PDFViewerViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = PDFViewerViewModel();
    _loadDocument();
    
    // 전체 화면 모드로 진입
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
  
  @override
  void dispose() {
    // 전체 화면 모드 해제
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _searchController.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
  
  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _viewModel.loadDocument(widget.filePath);
      
      if (kIsWeb && _viewModel.document != null) {
        await _loadPdfBytes(_viewModel.document!.filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '문서를 불러오는 중 오류가 발생했습니다: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 문서를 불러오는 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadPdfBytes(String url) async {
    try {
      debugPrint('웹 환경에서 PDF 바이트 불러오기 시도: $url');
      
      if (url.startsWith('blob:')) {
        // Blob URL은 특별한 처리가 필요
        // 이 경우에는 해당 URL에서 데이터를 직접 가져옵니다
        final http.Response response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          setState(() {
            _pdfBytes = response.bodyBytes;
          });
          debugPrint('Blob URL에서 PDF 바이트 로드 성공: ${_pdfBytes!.length} 바이트');
        } else {
          throw Exception('PDF 파일 다운로드 실패: ${response.statusCode}');
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        // 일반 URL
        final http.Response response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          setState(() {
            _pdfBytes = response.bodyBytes;
          });
          debugPrint('URL에서 PDF 바이트 로드 성공: ${_pdfBytes!.length} 바이트');
        } else {
          throw Exception('PDF 파일 다운로드 실패: ${response.statusCode}');
        }
      } else {
        // 웹 애셋 또는 다른 유형의 경로
        setState(() {
          _errorMessage = '지원되지 않는 PDF 경로 형식: $url';
        });
      }
    } catch (e) {
      debugPrint('PDF 바이트 로드 중 오류: $e');
      setState(() {
        _errorMessage = 'PDF 바이트 로드 실패: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<PDFViewerViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: _isToolbarVisible ? _buildAppBar(viewModel) : null,
            body: _buildBody(viewModel),
            bottomNavigationBar: _isToolbarVisible ? _buildBottomBar(viewModel) : null,
            floatingActionButton: !_isToolbarVisible 
                ? FloatingActionButton(
                    mini: true,
                    child: const Icon(Icons.menu),
                    onPressed: () {
                      setState(() {
                        _isToolbarVisible = true;
                      });
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
  
  AppBar _buildAppBar(PDFViewerViewModel viewModel) {
    return AppBar(
      title: Text(
        viewModel.document?.title ?? '문서 보기',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        if (!_isSearching) ...[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '검색',
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: '북마크',
            onPressed: () => _showBookmarksDialog(viewModel),
          ),
          IconButton(
            icon: Icon(viewModel.isNightMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: viewModel.isNightMode ? '라이트 모드' : '다크 모드',
            onPressed: () => viewModel.toggleNightMode(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '더 보기',
            onPressed: () => _showOptionsMenu(viewModel),
          ),
        ],
        if (_isSearching) ...[
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _cancelSearch();
                  },
                ),
              ),
              onSubmitted: (value) => _searchText(value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: '이전 결과',
            onPressed: _searchResult.hasResult
                ? () {
                    _searchResult.previousInstance();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            tooltip: '다음 결과',
            onPressed: _searchResult.hasResult
                ? () {
                    _searchResult.nextInstance();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '검색 닫기',
            onPressed: () {
              _cancelSearch();
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildBody(PDFViewerViewModel viewModel) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF 문서 로드 중...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('문서를 불러올 수 없습니다.'),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (!viewModel.hasDocument) {
      return const Center(
        child: Text('문서를 불러올 수 없습니다.'),
      );
    }
    
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isToolbarVisible = !_isToolbarVisible;
            });
          },
          child: _buildPdfViewer(viewModel),
        ),
      ],
    );
  }
  
  Widget _buildPdfViewer(PDFViewerViewModel viewModel) {
    // 웹 환경에서 PDF 표시
    if (kIsWeb) {
      // 인증 서비스 가져오기
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Firebase URL인 경우 SfPdfViewer.network로 표시
      if (viewModel.document?.url != null && 
          (viewModel.document!.url!.contains('firebasestorage.googleapis.com') || 
           viewModel.document!.url!.contains('https://') || 
           viewModel.document!.url!.contains('http://'))) {
        
        // 유료 회원이거나 로컬 URL인 경우 PDF 표시
        if (authService.isPremiumUser || 
            !viewModel.document!.url!.contains('firebasestorage.googleapis.com')) {
          String pdfUrl = viewModel.document!.url!;
          debugPrint('Firebase Storage URL에서 PDF 로드: $pdfUrl');
          
          return SfPdfViewer.network(
            pdfUrl,
            key: _pdfViewerKey,
            pageSpacing: 2,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            pageLayoutMode: viewModel.isTwoPageView 
                ? PdfPageLayoutMode.continuous 
                : PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.vertical,
            onPageChanged: (PdfPageChangedDetails details) {
              viewModel.goToPage(details.newPageNumber);
              _updatePageController(details.newPageNumber);
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              debugPrint('Firebase PDF 문서 로드 성공: 페이지 수 ${details.document.pages.count}');
              if (viewModel.document != null && details.document.pages.count != viewModel.document!.pageCount) {
                _updateDocumentPageCount(details.document.pages.count);
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              debugPrint('Firebase PDF 문서 로드 실패: ${details.error}');
              setState(() {
                _errorMessage = 'Firebase PDF 로드 실패: ${details.error}';
              });
            },
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                _showTextSelectionMenu(details, viewModel);
              }
            },
            initialZoomLevel: viewModel.zoomLevel,
            onZoomLevelChanged: (PdfZoomDetails details) {
              viewModel.setZoom(details.newZoomLevel);
            },
          );
        } else {
          // 유료 회원이 아닌 경우 유료 회원 전용 컨텐츠 메시지 표시
          return _buildPremiumContent(viewModel);
        }
      } else {
        // 지원되지 않는 URL 형식이거나 Firebase URL이 아닌 경우 안내 메시지 표시
        return _buildFirebaseGuide(viewModel, authService);
      }
    } else {
      // 네이티브 환경에서는 파일로 PDF 로드
      // dart:io의 File 클래스 사용
      final file = io.File(viewModel.document!.filePath);
      
      // 파일 존재 여부 확인
      if (!file.existsSync()) {
        return const Center(
          child: Text('파일을 찾을 수 없습니다.'),
        );
      }
      
      // 다이나믹 타입으로 처리하여 컴파일러 경고 우회
      // SfPdfViewer.file은 dart:io의 File 객체를 기대함
      return SfPdfViewer.file(
        file as dynamic,
        key: _pdfViewerKey,
        pageSpacing: 2,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        pageLayoutMode: viewModel.isTwoPageView 
            ? PdfPageLayoutMode.continuous 
            : PdfPageLayoutMode.single,
        scrollDirection: PdfScrollDirection.vertical,
        onPageChanged: (PdfPageChangedDetails details) {
          viewModel.goToPage(details.newPageNumber);
          _updatePageController(details.newPageNumber);
        },
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          if (details.selectedText != null && details.selectedText!.isNotEmpty) {
            _showTextSelectionMenu(details, viewModel);
          }
        },
        initialZoomLevel: viewModel.zoomLevel,
        onZoomLevelChanged: (PdfZoomDetails details) {
          viewModel.setZoom(details.newZoomLevel);
        },
      );
    }
  }
  
  Widget _buildBottomBar(PDFViewerViewModel viewModel) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.navigate_before),
              tooltip: '이전 페이지',
              onPressed: viewModel.canGoBack
                  ? () {
                      viewModel.previousPage();
                      if (_pdfViewerKey.currentState != null) {
                        setPageNumber(viewModel.currentPage);
                      }
                      _updatePageController(viewModel.currentPage);
                    }
                  : null,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null) {
                        viewModel.goToPage(page);
                        if (_pdfViewerKey.currentState != null) {
                          setPageNumber(viewModel.currentPage);
                        }
                      }
                    },
                  ),
                ),
                Text(' / ${viewModel.pageCount}'),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              tooltip: '다음 페이지',
              onPressed: viewModel.canGoForward
                  ? () {
                      viewModel.nextPage();
                      if (_pdfViewerKey.currentState != null) {
                        setPageNumber(viewModel.currentPage);
                      }
                      _updatePageController(viewModel.currentPage);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
  
  void _updatePageController(int page) {
    _pageController.text = page.toString();
  }
  
  void _searchText(String searchText) {
    if (searchText.isEmpty) return;
    
    _searchResult.clear();
    if (_pdfViewerKey.currentState != null) {
      searchTextInPdf(searchText);
    }
  }
  
  void _cancelSearch() {
    setState(() {
      _isSearching = false;
    });
    
    _searchResult.clear();
  }
  
  void _showTextSelectionMenu(
    PdfTextSelectionChangedDetails details,
    PDFViewerViewModel viewModel,
  ) {
    if (details.selectedText == null || details.selectedText!.isEmpty) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(details.globalSelectedRegion!.bottomLeft);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 10,
        position.dy + 10,
      ),
      items: [
        PopupMenuItem(
          child: const Text('하이라이트'),
          onTap: () {
            final text = details.selectedText!;
            final rect = Rect(
              left: details.globalSelectedRegion!.left,
              top: details.globalSelectedRegion!.top,
              right: details.globalSelectedRegion!.right,
              bottom: details.globalSelectedRegion!.bottom,
            );
            
            viewModel.addAnnotation(
              text,
              AnnotationType.highlight,
              rect,
            );
          },
        ),
        PopupMenuItem(
          child: const Text('메모 추가'),
          onTap: () {
            final text = details.selectedText!;
            _showAddNoteDialog(text, viewModel);
          },
        ),
        PopupMenuItem(
          child: const Text('복사'),
          onTap: () {
            Clipboard.setData(ClipboardData(text: details.selectedText!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('텍스트가 클립보드에 복사되었습니다'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
  
  void _showAddNoteDialog(String selectedText, PDFViewerViewModel viewModel) {
    final noteController = TextEditingController();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('메모 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '선택한 텍스트: "$selectedText"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
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
            TextButton(
              onPressed: () {
                if (noteController.text.isNotEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      );
    });
  }
  
  void _showBookmarksDialog(PDFViewerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('북마크'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddBookmarkDialog(viewModel),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: viewModel.bookmarks.isEmpty
              ? const Center(
                  child: Text('북마크가 없습니다.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = viewModel.bookmarks[index];
                    return ListTile(
                      title: Text(bookmark.title),
                      subtitle: Text('페이지 ${bookmark.pageNumber}'),
                      onTap: () {
                        viewModel.goToPage(bookmark.pageNumber);
                        if (_pdfViewerKey.currentState != null) {
                          setPageNumber(bookmark.pageNumber);
                        }
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onTap: () {
                          viewModel.removeBookmark(bookmark.id);
                          Navigator.pop(context);
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
      ),
    );
  }
  
  void _showAddBookmarkDialog(PDFViewerViewModel viewModel) {
    final bookmarkTitleController = TextEditingController(
      text: '페이지 ${viewModel.currentPage}',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 추가'),
        content: TextField(
          controller: bookmarkTitleController,
          decoration: const InputDecoration(
            labelText: '북마크 제목',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await viewModel.addBookmark(bookmarkTitleController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('북마크가 추가되었습니다'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  _showBookmarksDialog(viewModel);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('북마크 추가 실패: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  void _showOptionsMenu(PDFViewerViewModel viewModel) {
    // 인증 서비스 가져오기
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('문서 정보'),
            onTap: () {
              Navigator.pop(context);
              _showDocumentInfoDialog(viewModel);
            },
          ),
          ListTile(
            leading: Icon(viewModel.isTwoPageView ? Icons.book : Icons.chrome_reader_mode),
            title: Text(viewModel.isTwoPageView ? '단일 페이지 보기' : '두 페이지 보기'),
            onTap: () {
              Navigator.pop(context);
              viewModel.toggleTwoPageView();
            },
          ),
          ListTile(
            leading: const Icon(Icons.fullscreen),
            title: const Text('전체 화면'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isToolbarVisible = false;
              });
            },
          ),
          // 퀴즈 생성 옵션 (유료 회원만)
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('퀴즈 생성'),
            subtitle: authService.isPremiumUser 
                ? null 
                : const Text('유료 회원 전용', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: authService.isPremiumUser
                ? () {
                    Navigator.pop(context);
                    _showQuizGenerationDialog(viewModel);
                  }
                : () {
                    Navigator.pop(context);
                    // 유료 회원이 아니면 구독 페이지로 이동
                    _showPremiumFeatureDialog('퀴즈 생성');
                  },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('공유'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('공유 기능은 곧 추가될 예정입니다'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('저장'),
            onTap: () async {
              Navigator.pop(context);
              final savedPath = await viewModel.saveToFile();
              
              if (context.mounted) {
                if (savedPath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('문서가 저장되었습니다: $savedPath'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('문서 저장에 실패했습니다'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _showDocumentInfoDialog(PDFViewerViewModel viewModel) {
    final titleController = TextEditingController(text: viewModel.document?.title);
    final descriptionController = TextEditingController(
      text: viewModel.document?.description ?? '',
    );
    final urlController = TextEditingController(text: viewModel.document?.url ?? '');
    
    // 인증 서비스 가져오기
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 정보'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (authService.isPremiumUser) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Firebase URL',
                    border: const OutlineInputBorder(),
                    helperText: '웹에서 PDF를 보려면 Firebase Storage URL을 입력하세요',
                    suffix: IconButton(
                      icon: const Icon(Icons.help_outline, size: 16),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCorsGuideDialog();
                      },
                      tooltip: 'CORS 설정 가이드',
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              Text('파일 경로: ${viewModel.document?.filePath}'),
              Text('페이지 수: ${viewModel.document?.pageCount}'),
              Text(
                '생성 일시: ${viewModel.document?.createdAt.toLocal().toString().split('.')[0]}',
              ),
              Text(
                '수정 일시: ${viewModel.document?.updatedAt.toLocal().toString().split('.')[0]}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                // URL 업데이트 (유료 회원만)
                if (authService.isPremiumUser && 
                    urlController.text.isNotEmpty && 
                    urlController.text != viewModel.document?.url) {
                  await viewModel.updateDocumentUrl(urlController.text);
                }
                
                // 제목 및 설명 업데이트
                await viewModel.updateDocumentInfo(
                  titleController.text,
                  descriptionController.text.isEmpty ? null : descriptionController.text,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  // URL이 변경되었으면 화면 새로고침
                  if (authService.isPremiumUser &&
                      urlController.text.isNotEmpty && 
                      urlController.text != viewModel.document?.url) {
                    setState(() {});
                  }
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 페이지 번호 설정 헬퍼 함수
  void setPageNumber(int pageNumber) {
    _updatePageController(pageNumber);
    _viewModel.goToPage(pageNumber);
    
    // SfPdfViewer는 현재 API에서 페이지 이동 메서드를 제공하지 않으므로
    // ViewModel과 UI 업데이트만 처리하고 실제 화면은 다시 로드시 업데이트됨
    debugPrint('페이지 $pageNumber(으)로 이동 (UI만 업데이트)');
  }
  
  // PDF 문서의 페이지 수 업데이트
  void _updateDocumentPageCount(int pageCount) {
    if (_viewModel.document == null) return;
    
    debugPrint('PDF 문서 페이지 수 업데이트: $pageCount');
    _viewModel.updateDocumentPageCount(pageCount);
  }

  // PDF 내 텍스트 검색 헬퍼 함수
  void searchTextInPdf(String text) {
    // 현재 버전의 SfPdfViewer는 searchText API를 제공하지 않으므로
    // 검색 텍스트만 로깅하고 실제 검색은 구현하지 않음
    debugPrint('텍스트 검색 요청: $text (API 미지원)');
    
    // 검색 결과가 없음을 사용자에게 알림
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('현재 버전에서는 텍스트 검색이 지원되지 않습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 웹 환경에서 PDF 다운로드
  void _downloadPdf(PDFDocument? document) async {
    if (document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다운로드할 PDF 문서가 없습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // PDF 다운로드
      final String url = document.url ?? document.filePath;
      debugPrint('PDF 다운로드 시도: $url');
      
      final http.Response response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // 파일 이름 생성
        final fileName = document.fileName;
        
        // 웹 환경에서 다운로드
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // 다운로드 링크 생성
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        // 다운로드 링크를 DOM에 추가
        html.document.body!.children.add(anchor);
        
        // 클릭하여 다운로드 시작
        anchor.click();
        
        // 다운로드 후 링크 및 URL 객체 정리
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 다운로드 완료: $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PDF 다운로드 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF 다운로드 실패: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 유료 회원 전용 컨텐츠 안내 위젯
  Widget _buildPremiumContent(PDFViewerViewModel viewModel) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                '유료 회원 전용 기능',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '이 기능은 유료 회원만 사용할 수 있습니다. 구독하시면 다음 혜택을 누릴 수 있습니다:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Firebase에 PDF 저장하여 여러 기기에서 동기화'),
                  Text('• 클라우드에서 PDF 읽기 및 주석 동기화'),
                  Text('• PDF에서 자동 퀴즈 생성'),
                  Text('• 고급 검색 및 분석 기능'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()),
                  );
                },
                child: const Text('구독하기'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _downloadPdf(viewModel.document);
                },
                child: const Text('PDF 다운로드'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Firebase 안내 위젯
  Widget _buildFirebaseGuide(PDFViewerViewModel viewModel, AuthService authService) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                '웹에서 PDF 보기 안내',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                authService.isLoggedIn
                    ? '웹 환경에서 PDF를 보려면 Firebase Storage에 파일을 업로드해야 합니다.'
                    : '웹 환경에서 PDF를 저장하고 보려면 로그인이 필요합니다.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '현재 문서 경로: ${viewModel.document?.filePath ?? "경로 없음"}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              if (viewModel.document?.url != null)
                Text(
                  'URL: ${viewModel.document!.url}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 16),
              if (!authService.isLoggedIn)
                ElevatedButton(
                  onPressed: () {
                    // 로그인 페이지로 이동
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: const Text('로그인'),
                )
              else if (!authService.isPremiumUser)
                ElevatedButton(
                  onPressed: () {
                    // 구독 페이지로 이동
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()),
                    );
                  },
                  child: const Text('유료 회원 등록'),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: const Text('CORS 설정 가이드'),
                  onPressed: () {
                    _showCorsGuideDialog();
                  },
                ),
              const SizedBox(height: 16),
              if (authService.isPremiumUser)
                const Text(
                  'Firebase Storage 설정 방법:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (authService.isPremiumUser)
                const SizedBox(height: 8),
              if (authService.isPremiumUser)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Firebase 콘솔에서 Storage 서비스를 활성화하세요.'),
                    Text('2. CORS 설정을 추가하세요: gsutil cors set cors.json gs://your-bucket'),
                    Text('3. PDF를 업로드하고 공개 URL을 사용하세요.'),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _downloadPdf(viewModel.document);
                    },
                    child: const Text('PDF 다운로드'),
                  ),
                  const SizedBox(width: 16),
                  if (authService.isPremiumUser)
                    ElevatedButton(
                      onPressed: () {
                        _uploadToFirebase(viewModel);
                      },
                      child: const Text('Firebase에 업로드'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Firebase Storage에 PDF 업로드
  void _uploadToFirebase(PDFViewerViewModel viewModel) {
    // 인증 서비스 가져오기
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // 회원 타입 확인
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase에 업로드하려면 로그인이 필요합니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (!authService.isPremiumUser) {
      // 유료 회원이 아님을 안내하고 구독 페이지로 이동
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase 업로드는 유료 회원만 이용할 수 있습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 구독 페이지로 이동
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()),
        );
      });
      
      return;
    }
    
    // 실제 업로드 기능 구현은 별도 패키지 필요
    _showFirebaseUrlInputDialog(viewModel);
  }
  
  // Firebase URL 입력 다이얼로그
  void _showFirebaseUrlInputDialog(PDFViewerViewModel viewModel) {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Firebase Storage URL 입력'),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              onPressed: () {
                Navigator.pop(context);
                _showCorsGuideDialog();
              },
              tooltip: 'CORS 설정 가이드',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Firebase Storage에 PDF를 업로드한 후, 생성된 URL을 입력하세요.\n'
              'CORS 설정이 되어 있어야 웹에서 PDF를 볼 수 있습니다.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Firebase Storage URL',
                hintText: 'https://firebasestorage.googleapis.com/...',
                border: OutlineInputBorder(),
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
          TextButton(
            onPressed: () async {
              if (urlController.text.isNotEmpty) {
                final url = urlController.text.trim();
                Navigator.pop(context);
                
                if (viewModel.document != null) {
                  // 기존 문서의 URL 업데이트
                  final success = await viewModel.updateDocumentUrl(url);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Firebase URL이 업데이트되었습니다: $url'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    
                    // 새로고침
                    setState(() {});
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL 업데이트 실패'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  // 새 문서 생성
                  final success = await viewModel.loadDocumentFromFirebaseUrl(url);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Firebase 문서가 로드되었습니다: $url'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    
                    // 새로고침
                    setState(() {});
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Firebase 문서 로드 실패'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  // CORS 설정 가이드 다이얼로그
  void _showCorsGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CORS 설정 가이드'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Firebase Storage에서 PDF를 웹에서 볼 수 있게 하려면 CORS 설정이 필요합니다:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. cors.json 파일 생성:'),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('''[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]''', style: TextStyle(fontFamily: 'monospace')),
              ),
              SizedBox(height: 8),
              Text('2. gcloud 인증:'),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('gcloud auth login', style: TextStyle(fontFamily: 'monospace')),
              ),
              SizedBox(height: 8),
              Text('3. CORS 설정 적용:'),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('gsutil cors set cors.json gs://YOUR-BUCKET-NAME', 
                  style: TextStyle(fontFamily: 'monospace')),
              ),
              SizedBox(height: 16),
              Text('이 설정 후에는 웹 브라우저에서 Firebase Storage의 PDF URL을 사용할 수 있습니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 유료 회원 전용 기능 안내 다이얼로그
  void _showPremiumFeatureDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('유료 회원 전용 기능'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '$featureName 기능은 유료 회원만 이용할 수 있습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '유료 구독을 통해 더 많은 기능을 이용해 보세요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumSubscriptionPage()),
              );
            },
            child: const Text('구독하기'),
          ),
        ],
      ),
    );
  }
  
  // 퀴즈 생성 다이얼로그
  void _showQuizGenerationDialog(PDFViewerViewModel viewModel) {
    int questionCount = 5;
    bool useCurrentPageOnly = false;
    final pageRangeController = TextEditingController(text: viewModel.currentPage.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('퀴즈 생성'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이 PDF 문서에서 퀴즈를 생성합니다.'),
                const SizedBox(height: 16),
                const Text('문제 수:'),
                Slider(
                  value: questionCount.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  label: questionCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      questionCount = value.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: useCurrentPageOnly,
                      onChanged: (value) {
                        setState(() {
                          useCurrentPageOnly = value ?? false;
                        });
                      },
                    ),
                    const Text('특정 페이지만 사용'),
                  ],
                ),
                if (useCurrentPageOnly)
                  TextField(
                    controller: pageRangeController,
                    decoration: const InputDecoration(
                      labelText: '페이지 범위',
                      hintText: '예: 1-5, 7, 9-10',
                      border: OutlineInputBorder(),
                      helperText: '쉼표(,)로 구분하고 범위는 하이픈(-)으로 표시',
                    ),
                    keyboardType: TextInputType.text,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  // 페이지 범위 파싱
                  List<int> pageNumbers = [];
                  if (useCurrentPageOnly) {
                    try {
                      pageNumbers = _parsePageRange(pageRangeController.text, viewModel.pageCount);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('페이지 범위 형식이 잘못되었습니다: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }
                  }
                  
                  // 퀴즈 생성 화면으로 이동
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizGenerationPage(
                          document: viewModel.document!,
                          questionCount: questionCount,
                          pageNumbers: useCurrentPageOnly ? pageNumbers : null,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('퀴즈 생성'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 페이지 범위 파싱 헬퍼 함수
  List<int> _parsePageRange(String input, int maxPages) {
    if (input.trim().isEmpty) {
      throw Exception('페이지 범위를 입력해주세요.');
    }
    
    final Set<int> pageNumbers = {};
    final parts = input.split(',');
    
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        // 범위 처리 (예: 1-5)
        final range = trimmed.split('-');
        if (range.length != 2) {
          throw Exception('페이지 범위 형식이 올바르지 않습니다: $trimmed');
        }
        
        final start = int.tryParse(range[0].trim());
        final end = int.tryParse(range[1].trim());
        
        if (start == null || end == null) {
          throw Exception('페이지 번호는 숫자여야 합니다: $trimmed');
        }
        
        if (start > end) {
          throw Exception('시작 페이지는 종료 페이지보다 작아야 합니다: $trimmed');
        }
        
        if (start < 1 || end > maxPages) {
          throw Exception('페이지 범위가 문서의 범위를 벗어났습니다 (1-$maxPages): $trimmed');
        }
        
        for (int i = start; i <= end; i++) {
          pageNumbers.add(i);
        }
      } else {
        // 단일 페이지 처리 (예: 7)
        final page = int.tryParse(trimmed);
        if (page == null) {
          throw Exception('페이지 번호는 숫자여야 합니다: $trimmed');
        }
        
        if (page < 1 || page > maxPages) {
          throw Exception('페이지 번호가 문서의 범위를 벗어났습니다 (1-$maxPages): $page');
        }
        
        pageNumbers.add(page);
      }
    }
    
    if (pageNumbers.isEmpty) {
      throw Exception('유효한 페이지 번호가 없습니다.');
    }
    
    return pageNumbers.toList()..sort();
  }
} 