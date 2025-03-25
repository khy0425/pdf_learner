import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_view_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFReaderView extends StatelessWidget {
  const PDFReaderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PDFViewModel>(
      builder: (context, viewModel, child) {
        final document = viewModel.selectedDocument;
        if (document == null) {
          return const Center(child: Text('문서를 선택해주세요.'));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(document.title),
            actions: [
              IconButton(
                icon: Icon(
                  document.isFavorite ? Icons.star : Icons.star_border,
                  color: document.isFavorite ? Colors.amber : null,
                ),
                onPressed: () => viewModel.toggleFavorite(document.id),
              ),
            ],
          ),
          body: SfPdfViewer.network(
            document.filePath,
            initialPageNumber: document.currentPage,
            onPageChanged: (PdfPageChangedDetails details) {
              viewModel.updateCurrentPage(document.id, details.newPageNumber);
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              final progress = details.currentPage / details.document.pages.count;
              viewModel.updateReadingProgress(document.id, progress);
            },
          ),
        );
      },
    );
  }
} 