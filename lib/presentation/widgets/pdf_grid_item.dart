import 'package:flutter/material.dart';
import '../models/pdf_file_info.dart';
import '../../core/utils/file_utils.dart';
import 'dart:io';

/// PDF 그리드 아이템 위젯
class PdfGridItem extends StatelessWidget {
  /// PDF 파일 정보
  final PdfFileInfo pdfFile;
  
  /// 클릭 핸들러
  final void Function(PdfFileInfo file)? onTap;
  
  /// 즐겨찾기 토글 핸들러
  final void Function(PdfFileInfo file)? onFavoriteToggle;
  
  /// 삭제 핸들러
  final void Function(PdfFileInfo file)? onDelete;
  
  /// 생성자
  const PdfGridItem({
    Key? key,
    required this.pdfFile,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileSizeStr = FileUtils.getFileSizeString(pdfFile.size);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: pdfFile.isSelected ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: pdfFile.isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(pdfFile) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 부분
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 썸네일 이미지
                  pdfFile.thumbnail != null
                      ? Image.memory(
                          pdfFile.thumbnail!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                        ),
                        
                  // 즐겨찾기 버튼
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          pdfFile.isFavorite ? Icons.star : Icons.star_border,
                          color: pdfFile.isFavorite
                              ? Colors.amber
                              : Colors.grey.shade600,
                        ),
                        onPressed: onFavoriteToggle != null
                            ? () => onFavoriteToggle!(pdfFile)
                            : null,
                      ),
                    ),
                  ),
                  
                  // 삭제 버튼
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: onDelete != null
                            ? () => onDelete!(pdfFile)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 파일 정보 부분
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 파일명
                  Text(
                    pdfFile.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // 파일 크기
                  Text(
                    fileSizeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  // 마지막 수정일
                  if (pdfFile.lastModified != null)
                    Text(
                      '수정일: ${_formatDate(pdfFile.lastModified!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 