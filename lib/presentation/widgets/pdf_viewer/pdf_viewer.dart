import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'native_pdf_viewer_widget.dart';
import 'web_pdf_viewer_widget.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';

class PDFViewer extends StatelessWidget {
  final PDFViewerViewModel viewModel;

  const PDFViewer({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF 뷰어'),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () {
              // TODO: 북마크 기능 구현
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능 구현
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, child) {
          if (viewModel.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Text(viewModel.error!),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // TODO: PDF 렌더링 구현
                    Center(
                      child: Text('PDF 콘텐츠'),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: viewModel.previousPage,
                          ),
                          Text(
                            '${viewModel.currentPage} / ${viewModel.totalPages}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward),
                            onPressed: viewModel.nextPage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.zoom_out),
                    label: '축소',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.zoom_in),
                    label: '확대',
                  ),
                ],
                onTap: (index) {
                  // TODO: 확대/축소 기능 구현
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 