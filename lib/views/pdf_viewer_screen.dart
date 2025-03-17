import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' show min;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../view_models/pdf_viewer_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../models/pdf_file_info.dart';

class PDFViewerScreen extends StatefulWidget {
  final PdfFileInfo pdf;

  const PDFViewerScreen({required this.pdf, super.key});

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
  bool _showOutline = false;
  List<Map<String, dynamic>>? _outlineData;
  final ScrollController _thumbnailScrollController = ScrollController();
  final List<String> _highlightedSentences = [];
  bool _showHighlights = true;
  final Color _highlightColor = Colors.yellow.withOpacity(0.3);
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookmarks = [];
  bool _showBookmarks = false;
  
  // PDF 데이터 관련 상태
  bool _isPdfLoaded = false;
  Uint8List? _pdfData;
  String? _errorMessage;
  String? _localPath;
  int _totalPages = 0;

  // 확대/축소 관련 상수
  static const double _minZoomLevel = 0.05;
  static const double _maxZoomLevel = 5.0;
  static const double _zoomStep = 0.05;

  @override
  void initState() {
    super.initState();
    
    // PDF 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPdf();
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
      
      // 게스트 사용자 파일인 경우 특별 처리
      if (widget.pdf.isGuestFile) {
        debugPrint('게스트 사용자 PDF 파일 로드: ${widget.pdf.fileName}');
        
        if (widget.pdf.bytes != null) {
          // 바이트 데이터가 있는 경우 임시 파일로 저장
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${widget.pdf.fileName}');
          await tempFile.writeAsBytes(widget.pdf.bytes!);
          
          setState(() {
            _localPath = tempFile.path;
            _isLoading = false;
          });
          return;
        }
      }
      
      // 일반적인 PDF 로드 로직
      await viewModel.loadPdfData(widget.pdf.id);
      
      if (viewModel.pdfBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.pdf.fileName}');
        await tempFile.writeAsBytes(viewModel.pdfBytes!);
        
        setState(() {
          _localPath = tempFile.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = viewModel.errorMessage ?? 'PDF 파일을 로드할 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PDF 로드 오류: $e');
      setState(() {
        _errorMessage = '파일을 로드하는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  Provider.of<PdfViewerViewModel>(context, listen: false).clearSearch();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Provider.of<PdfViewerViewModel>(context, listen: false).toggleBookmark();
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {
              setState(() {
                _showThumbnails = !_showThumbnails;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleMenuAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'summary',
                child: Text('AI 요약'),
              ),
              const PopupMenuItem<String>(
                value: 'quiz',
                child: Text('퀴즈 생성'),
              ),
              const PopupMenuItem<String>(
                value: 'highlight',
                child: Text('하이라이트'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar) _buildSearchBar(),
          Expanded(
            child: _buildPdfViewer(),
          ),
          if (_showThumbnails) _buildThumbnailView(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '검색어 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Provider.of<PdfViewerViewModel>(context, listen: false).searchText(value);
                  // 실제 검색 기능은 SfPdfViewer 위젯에서 처리
                  // 현재 버전의 SfPdfViewer에서는 직접 검색 기능을 사용할 수 없음
                  // 대신 컨트롤러를 통해 검색 기능 구현 필요
                  _pdfViewerController.searchText(_searchController.text);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showSearchBar = false;
                _searchController.clear();
                Provider.of<PdfViewerViewModel>(context, listen: false).clearSearch();
                // 검색 결과 초기화
                _pdfViewerController.clearSelection();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Consumer<PdfViewerViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('오류가 발생했습니다: ${viewModel.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPdf,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        
        if (!viewModel.isPdfLoaded || viewModel.pdfData == null) {
          return const Center(child: Text('PDF를 불러올 수 없습니다'));
        }
        
        return SfPdfViewerTheme(
          data: SfPdfViewerThemeData(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: SfPdfViewer.memory(
            viewModel.pdfData!,
            controller: _pdfViewerController,
            key: _pdfViewerKey,
            onPageChanged: (details) {
              viewModel.setCurrentPage(details.newPageNumber);
            },
            onZoomLevelChanged: (details) {
              viewModel.setZoomLevel(details.newZoomLevel);
            },
          ),
        );
      },
    );
  }

  Widget _buildThumbnailView() {
    return Consumer<PdfViewerViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isPdfLoaded || viewModel.pdfData == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: 120,
          color: Theme.of(context).colorScheme.surface,
          child: SfPdfViewer.memory(
            viewModel.pdfData!,
            enableDoubleTapZooming: false,
            enableTextSelection: false,
            enableDocumentLinkAnnotation: false,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            pageSpacing: 0,
            onTap: (details) {
              if (details.pageNumber != null) {
                _pdfViewerController.jumpToPage(details.pageNumber!);
              }
            },
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    
    switch (action) {
      case 'summary':
        viewModel.generateSummary(widget.pdf.id);
        break;
      case 'quiz':
        viewModel.generateQuiz(widget.pdf.id);
        break;
      case 'highlight':
        viewModel.toggleHighlightMode();
        break;
    }
  }
} 