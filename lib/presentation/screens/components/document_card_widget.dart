import 'package:flutter/material.dart';
import '../../models/pdf_document.dart';
import '../../utils/formatters/date_formatter.dart';
import '../../utils/formatters/file_size_formatter.dart';
import '../pdf_viewer_page.dart';
import 'document_thumbnail_widget.dart';

/// PDF 문서를 카드 형태로 표시하는 위젯
class DocumentCardWidget extends StatelessWidget {
  final PDFDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const DocumentCardWidget({
    Key? key,
    required this.document,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 썸네일 영역
              SizedBox(
                height: 120,
                child: DocumentThumbnailWidget(document: document),
              ),
              
              // 문서 정보 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 문서 제목
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // 마지막 열람 시간
                      Text(
                        DateFormatter.formatDate(document.lastOpened),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 페이지 정보
                      const SizedBox(height: 2),
                      Text(
                        '${document.pageCount} 페이지',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// PDF 뷰어 페이지로 이동
  void _navigateToPdfViewer(BuildContext context) {
    // 화면 이동
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