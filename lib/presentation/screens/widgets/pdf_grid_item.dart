import 'package:flutter/material.dart';
import '../../models/pdf_document.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// PDF 그리드 아이템 위젯
class PdfGridItem extends StatelessWidget {
  final PdfDocument document;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const PdfGridItem({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 영역
            Expanded(
              child: Stack(
                children: [
                  // 썸네일 이미지
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8.0),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: _buildThumbnail(context),
                  ),
                  
                  // 북마크 배지
                  if (document.bookmarks.isNotEmpty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bookmark,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${document.bookmarks.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 더보기 버튼
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: onMorePressed,
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // 문서 정보 영역
            Padding(
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
                  const SizedBox(height: 4),
                  
                  // 페이지 수 및 크기
                  Text(
                    '${document.pageCount} 페이지',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  // 최근 조회 시간
                  Text(
                    _formatDate(document.lastAccessedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  // 썸네일 위젯 생성
  Widget _buildThumbnail(BuildContext context) {
    if (document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty) {
      // 썸네일이 있는 경우
      if (kIsWeb) {
        // 웹일 경우 네트워크 이미지나 메모리 이미지로 처리
        if (document.thumbnailPath!.startsWith('http')) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8.0),
            ),
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8.0),
            ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            document.fileName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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