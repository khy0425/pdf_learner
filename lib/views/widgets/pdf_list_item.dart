import 'package:flutter/material.dart';
import '../../models/pdf_document.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// PDF 목록 아이템 위젯
class PdfListItem extends StatelessWidget {
  final PdfDocument document;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const PdfListItem({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // 썸네일 영역
              SizedBox(
                width: 60,
                height: 70,
                child: _buildThumbnail(context),
              ),
              const SizedBox(width: 12),
              
              // 문서 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 문서 제목
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 파일명
                    Text(
                      document.fileName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 메타데이터 행
                    Row(
                      children: [
                        // 페이지 수
                        Icon(
                          Icons.description,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${document.pageCount} 페이지',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 북마크 수
                        Icon(
                          Icons.bookmark,
                          size: 14,
                          color: document.bookmarks.isNotEmpty
                              ? Colors.blue
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${document.bookmarks.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: document.bookmarks.isNotEmpty
                                ? Colors.blue
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 날짜 정보
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(document.lastAccessedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 더보기 버튼
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMorePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 썸네일 위젯 생성
  Widget _buildThumbnail(BuildContext context) {
    if (document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty) {
      // 썸네일이 있는 경우
      if (kIsWeb) {
        // 웹일 경우 네트워크 이미지나 메모리 이미지로 처리
        if (document.thumbnailPath!.startsWith('http')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              document.thumbnailPath!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultThumbnail(context);
              },
            ),
          );
        } else {
          return _buildDefaultThumbnail(context);
        }
      } else {
        // 네이티브 환경일 경우 파일 이미지로 처리
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(document.thumbnailPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultThumbnail(context);
              },
            ),
          );
        } catch (e) {
          return _buildDefaultThumbnail(context);
        }
      }
    } else {
      // 썸네일이 없는 경우 기본 아이콘 표시
      return _buildDefaultThumbnail(context);
    }
  }

  // 기본 썸네일 위젯
  Widget _buildDefaultThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // 날짜 포맷 변환
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }
} 