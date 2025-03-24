import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';

/// 네이티브 PDF 뷰어 위젯
class NativePdfViewerWidget extends StatefulWidget {
  final String filePath;
  final PdfViewerViewModel viewModel;

  const NativePdfViewerWidget({
    Key? key,
    required this.filePath,
    required this.viewModel,
  }) : super(key: key);

  @override
  State<NativePdfViewerWidget> createState() => _NativePdfViewerWidgetState();
}

class _NativePdfViewerWidgetState extends State<NativePdfViewerWidget> {
  PDFViewController? _controller;
  int? _currentPage;
  int? _totalPages;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages;
              _isReady = true;
            });
            widget.viewModel.setTotalPages(pages ?? 0);
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF 로딩 중 오류가 발생했습니다: $error')),
            );
          },
          onPageError: (page, error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('페이지 $page 로딩 중 오류가 발생했습니다: $error')),
            );
          },
          onViewCreated: (PDFViewController controller) {
            _controller = controller;
            widget.viewModel.setController(controller);
          },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = page;
            });
            if (page != null) {
              widget.viewModel.setCurrentPage(page);
            }
          },
        ),
        if (!_isReady)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

extension PDFViewControllerExtension on PDFViewController {
  Future<void> setZoom(double zoom) async {
    await setZoomRatio(zoom);
  }
} 