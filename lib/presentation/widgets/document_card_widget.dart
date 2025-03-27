import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pdf_document.dart';

/// PDF 문서 카드 위젯
class DocumentCardWidget extends StatelessWidget {
  /// 문서 객체
  final PDFDocument document;
  
  /// 문서 선택 시 호출
  final Function(PDFDocument) onTap;
  
  /// 즐겨찾기 토글 시 호출
  final Function(PDFDocument)? onFavoriteToggle;
  
  /// 문서 선택 여부
  final bool isSelected;

  /// 생성자
  const DocumentCardWidget({
    Key? key,
    required this.document,
    required this.onTap,
    this.onFavoriteToggle,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => onTap(document),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파일 타입 및 즐겨찾기 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 14,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    GestureDetector(
                      onTap: () => onFavoriteToggle!(document),
                      child: Icon(
                        document.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: document.isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 파일 미리보기
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: _buildDocumentPreview(),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 파일 제목
              Text(
                document.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 파일 정보
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(document.updatedAt ?? document.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.description_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${document.pageCount} 페이지',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              // 진행률 바
              if (document.readingProgress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: document.readingProgress,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 문서 미리보기
  Widget _buildDocumentPreview() {
    try {
      // 로컬 파일 미리보기
      if (document.filePath.isNotEmpty && !document.filePath.startsWith('http')) {
        final file = File(document.filePath);
        if (file.existsSync()) {
          // 미리보기 이미지가 있는 경우
          if (document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(document.thumbnailPath!),
                fit: BoxFit.cover,
              ),
            );
          }
        }
      }
      
      // 기본 미리보기
      return Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 40,
          color: Colors.red.shade300,
        ),
      );
    } catch (e) {
      // 오류 발생 시 기본 아이콘
      return Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 40,
          color: Colors.red.shade300,
        ),
      );
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    // 오늘 날짜인 경우
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return '오늘 ${DateFormat('HH:mm').format(date)}';
    } else if (today.difference(dateDay).inDays == 1) {
      return '어제 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('yy.MM.dd').format(date);
    }
  }
} 