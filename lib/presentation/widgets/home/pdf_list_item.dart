import 'package:flutter/material.dart';
import '../../models/pdf_file_info.dart';

/// PDF 목록 항목 위젯
/// PDF 파일 정보를 표시하는 카드 형태의 위젯입니다.
class PdfListItem extends StatelessWidget {
  final PdfFileInfo pdfInfo;
  final Function() onOpen;
  final Function(PdfFileInfo) onDelete;
  
  const PdfListItem({
    super.key,
    required this.pdfInfo,
    required this.onOpen,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 추가 날짜 포맷팅
    final date = pdfInfo.createdAt;
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(20),
            splashColor: colorScheme.primary.withAlpha(26),
            highlightColor: colorScheme.primary.withAlpha(13),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF 아이콘
                  _buildPdfIcon(colorScheme),
                  const SizedBox(width: 16),
                  
                  // PDF 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 파일명
                        Text(
                          pdfInfo.fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // 파일 크기 및 날짜
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: colorScheme.onSurfaceVariant.withAlpha(179),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.data_usage,
                              size: 12,
                              color: colorScheme.onSurfaceVariant.withAlpha(179),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatFileSize(pdfInfo.fileSize),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        
                        // 파일 경로 또는 URL (옵션)
                        if (pdfInfo.url.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 12,
                                  color: colorScheme.primary.withAlpha(179),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '원본: ${pdfInfo.url}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // 삭제 버튼
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error.withAlpha(204),
                    ),
                    onPressed: () => onDelete(pdfInfo),
                    tooltip: '삭제',
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // PDF 아이콘
  Widget _buildPdfIcon(ColorScheme colorScheme) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // PDF 파일 아이콘
          Center(
            child: Icon(
              Icons.picture_as_pdf,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          
          // 오른쪽 상단 모서리 접힘 효과
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 파일 크기 포맷팅 (바이트 -> KB, MB 등)
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