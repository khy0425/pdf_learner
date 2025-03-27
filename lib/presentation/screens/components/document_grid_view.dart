import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/pdf_document.dart';
import '../pdf_viewer_page.dart';
import 'document_card_widget.dart';

/// 문서 그리드 뷰 컴포넌트
class DocumentGridView extends StatelessWidget {
  final List<PDFDocument> documents;
  final Function(PDFDocument) onDocumentLongPress;
  final bool isSearching;
  
  const DocumentGridView({
    Key? key,
    required this.documents,
    required this.onDocumentLongPress,
    this.isSearching = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          
          return DocumentCardWidget(
            document: document,
            onTap: () => _openPdfViewer(context, document),
            onLongPress: () => onDocumentLongPress(document),
          );
        },
      ),
    );
  }
  
  /// 화면 너비에 따라 컬럼 개수 반환 - 웹에서는 사용하지 않음
  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return 2;
    } else if (width < 900) {
      return 3;
    } else if (width < 1200) {
      return 4;
    } else {
      return 5;
    }
  }
  
  /// PDF 뷰어 페이지 열기
  void _openPdfViewer(BuildContext context, PDFDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(
          document: document,
          documentId: document.id,
        ),
      ),
    );
  }
} 