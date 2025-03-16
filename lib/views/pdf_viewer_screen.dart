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

import '../view_models/pdf_viewer_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../models/pdf_model.dart';

class PDFViewerScreen extends StatefulWidget {
  final PdfModel pdf;

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
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final ScrollController _thumbnailScrollController = ScrollController();
  final List<String> _highlightedSentences = [];
  bool _showHighlights = true;
  final Color _highlightColor = Colors.yellow.withOpacity(0.3);
  bool _isLoading = false;
  List<Map<String, dynamic>> _bookmarks = [];
  bool _showBookmarks = false;
  
  // PDF 데이터 관련 상태
  bool _isPdfLoaded = false;
  Uint8List? _pdfData;
  bool _hasError = false;
  String _errorMessage = "";

  // 확대/축소 관련 상수
  static const double _minZoomLevel = 0.05;
  static const double _maxZoomLevel = 5.0;
  static const double _zoomStep = 0.05;

  @override
  void initState() {
    super.initState();
    
    // ViewModel 초기화 및 PDF 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
      viewModel.loadPdfData(widget.pdf.id);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
              viewModel.zoomIn();
              _pdfViewerController.zoomLevel = viewModel.zoomLevel;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
              viewModel.zoomOut();
              _pdfViewerController.zoomLevel = viewModel.zoomLevel;
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              setState(() {
                _showThumbnails = !_showThumbnails;
              });
            },
          ),
        ],
        bottom: _showSearchBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // 검색 기능 구현
                          if (_pdfViewerKey.currentState != null) {
                            // 현재 버전의 SfPdfViewer에서는 searchText 메서드를 지원하지 않음
                            // 대신 다른 방법으로 검색 기능 구현 필요
                            debugPrint('검색 기능: ${_searchController.text}');
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) {
                      // 검색 기능 구현
                      if (_pdfViewerKey.currentState != null) {
                        // 현재 버전의 SfPdfViewer에서는 searchText 메서드를 지원하지 않음
                        // 대신 다른 방법으로 검색 기능 구현 필요
                        debugPrint('검색 기능: $value');
                      }
                    },
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<PdfViewerViewModel>(
      builder: (context, viewModel, _) {
        // 로딩 중인 경우
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 오류가 발생한 경우
        if (viewModel.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PDF를 불러오는 중 오류가 발생했습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(viewModel.errorMessage),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadPdfData(widget.pdf.id),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // PDF 데이터가 없는 경우
        if (!viewModel.isPdfLoaded || viewModel.pdfData == null) {
          return const Center(
            child: Text('PDF 데이터가 없습니다'),
          );
        }

        // PDF 뷰어 표시
        return Row(
          children: [
            // 썸네일 사이드바
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
                      final isCurrentPage = viewModel.currentPage == index + 1;
                      return GestureDetector(
                        onTap: () {
                          _pdfViewerController.jumpToPage(index + 1);
                          viewModel.setCurrentPage(index + 1);
                        },
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
            
            // PDF 뷰어
            Expanded(
              child: SfPdfViewer.memory(
                viewModel.pdfData!,
                key: _pdfViewerKey,
                controller: _pdfViewerController,
                onPageChanged: (PdfPageChangedDetails details) {
                  viewModel.setCurrentPage(details.newPageNumber);
                },
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  viewModel.setCurrentPage(1);
                  viewModel.setZoomLevel(1.0);
                },
              ),
            ),
          ],
        );
      },
    );
  }
} 