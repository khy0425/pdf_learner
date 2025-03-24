import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_learner/providers/pdf_provider.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf_learner/models/pdf_file_info.dart';

// 간단한 PDF 뷰어 화면
class SimplePdfViewer extends StatefulWidget {
  final PdfFileInfo pdfFile;

  const SimplePdfViewer({required this.pdfFile, Key? key}) : super(key: key);

  @override
  State<SimplePdfViewer> createState() => _SimplePdfViewerState();
}

class _SimplePdfViewerState extends State<SimplePdfViewer> {
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;
  Uint8List? _pdfBytes;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final bytes = await widget.pdfFile.readAsBytes();
      
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // 요약 기능 - 실제 구현은 AI 서비스와 연결 필요
  void _showSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 요약'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF 내용 요약이 여기에 표시됩니다.'),
            SizedBox(height: 12),
            Text('이 기능은 AI 서비스와 연결하여 자동으로 PDF 내용을 요약할 수 있습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // 퀴즈 기능 - 실제 구현은 AI 서비스와 연결 필요
  void _showQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 퀴즈'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF 내용을 기반으로 생성된 퀴즈가 여기에 표시됩니다.'),
            SizedBox(height: 12),
            Text('이 기능은 AI 서비스와 연결하여 PDF 내용을 바탕으로 퀴즈를 생성할 수 있습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pdfFile.fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: _showSummary,
            tooltip: 'PDF 요약',
          ),
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: _showQuiz,
            tooltip: '퀴즈 생성',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 정보 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '페이지: $_currentPage / $_totalPages',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '파일 크기: ${(widget.pdfFile.fileSize / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // PDF 뷰어 또는 로딩/에러 상태
            Expanded(
              child: _buildBody(),
            ),
            
            // 하단 툴바
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF 파일을 로드하는 중...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('PDF 파일을 로드하는 중 오류가 발생했습니다.'),
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPdfBytes,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(child: Text('PDF 데이터를 불러올 수 없습니다.'));
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      controller: _pdfViewerController,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
          // totalPages 속성 접근 오류 수정 
          // _totalPages 업데이트는 onDocumentLoaded에서만 수행
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: _currentPage > 1
                ? () => _pdfViewerController.previousPage()
                : null,
            tooltip: '이전 페이지',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
            tooltip: '축소',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _pdfViewerController.zoomLevel += 0.25,
            tooltip: '확대',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: _currentPage < _totalPages
                ? () => _pdfViewerController.nextPage()
                : null,
            tooltip: '다음 페이지',
          ),
        ],
      ),
    );
  }

  // PDF 파일 정보 표시 위젯
  Widget _buildPdfInfo() {
    final formattedDate = _formatDate(widget.pdfFile.createdAt);
    final formattedSize = _formatFileSize(widget.pdfFile.fileSize);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '파일명: ${widget.pdfFile.fileName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('생성일: $formattedDate'),
          Text('파일 크기: $formattedSize'),
          if (widget.pdfFile.url != null)
            Text(
              'URL: ${widget.pdfFile.url!.length > 40 ? widget.pdfFile.url!.substring(0, 40) + '...' : widget.pdfFile.url!}',
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 파일 크기 형식화
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
} 