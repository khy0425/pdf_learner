import 'package:flutter/material.dart';
import '../../models/pdf_document.dart';
import '../pdf_viewer_page.dart';
import '../../utils/date_formatter.dart';
import 'document_thumbnail_widget.dart';

/// 문서를 리스트 형태로 표시하는 위젯
class DocumentListView extends StatelessWidget {
  final List<PDFDocument> documents;
  final Function(PDFDocument) onDocumentLongPress;
  final bool isSearching;
  
  const DocumentListView({
    Key? key,
    required this.documents,
    required this.onDocumentLongPress,
    this.isSearching = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final document = documents[index];
        
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 64,
            child: DocumentThumbnailWidget(document: document),
          ),
          title: Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatter.formatDate(document.lastOpened),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${document.pageCount}페이지',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openPdfViewer(context, document),
          onLongPress: () => onDocumentLongPress(document),
        );
      },
    );
  }
  
  /// PDF 뷰어 페이지 열기
  void _openPdfViewer(BuildContext context, PDFDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          documentId: document.id,
          document: document,
          showAds: true,
          showRewardButton: true,
        ),
      ),
    );
  }
} 