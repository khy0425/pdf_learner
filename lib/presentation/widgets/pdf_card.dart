import 'package:flutter/material.dart';
import '../models/pdf_document.dart';
import '../utils/date_formatter.dart';

class PdfCard extends StatelessWidget {
  final PDFDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PdfCard({
    Key? key,
    required this.document,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 영역
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[200],
                child: document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty
                    ? Image.network(
                        document.thumbnailPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),
            // 문서 정보 영역
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 제목
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 날짜
                    Text(
                      DateFormatter.formatDate(document.lastOpened),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 