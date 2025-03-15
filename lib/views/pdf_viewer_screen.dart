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

import '../view_models/pdf_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../models/pdf_model.dart';
import '../services/pdf_service.dart';

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
  final PdfService _pdfService = PdfService();
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
    _loadPdfData();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  /// PDF 데이터 로드
  Future<void> _loadPdfData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      final pdfData = await pdfViewModel.getPdfData(widget.pdf.id);
      
      if (pdfData == null) {
        throw Exception('PDF 데이터를 불러올 수 없습니다.');
      }
      
      if (mounted) {
        setState(() {
          _pdfData = pdfData;
          _isPdfLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PDF 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
              setState(() {
                _zoomLevel = min(_zoomLevel + _zoomStep, _maxZoomLevel);
                _pdfViewerController.zoomLevel = _zoomLevel;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _zoomLevel = max(_zoomLevel - _zoomStep, _minZoomLevel);
                _pdfViewerController.zoomLevel = _zoomLevel;
              });
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
                          _searchResult = _pdfViewerKey.currentState!.searchText(
                            _searchController.text,
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) {
                      _searchResult = _pdfViewerKey.currentState!.searchText(value);
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
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
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdfData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (!_isPdfLoaded || _pdfData == null) {
      return const Center(
        child: Text('PDF 데이터가 없습니다'),
      );
    }

    return Row(
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
          child: SfPdfViewer.memory(
            _pdfData!,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _currentPage = 1;
                _zoomLevel = 1.0;
              });
            },
          ),
        ),
      ],
    );
  }
} 