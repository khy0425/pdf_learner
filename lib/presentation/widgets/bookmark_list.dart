import 'package:flutter/material.dart';
import '../../domain/models/pdf_bookmark.dart';
import 'package:intl/intl.dart';

class BookmarkList extends StatelessWidget {
  final List<PDFBookmark> bookmarks;
  final bool isLoading;
  final Function(PDFBookmark) onBookmarkTap;
  final Function(PDFBookmark) onEditTap;
  final Function(PDFBookmark) onDeleteTap;
  
  const BookmarkList({
    super.key,
    required this.bookmarks,
    required this.isLoading,
    required this.onBookmarkTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '북마크가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                inherit: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '하단의 북마크 버튼을 눌러 추가하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                inherit: true,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: bookmarks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildBookmarkItem(context, bookmark);
      },
    );
  }
  
  Widget _buildBookmarkItem(BuildContext context, PDFBookmark bookmark) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final formattedDate = dateFormat.format(bookmark.createdAt);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => onBookmarkTap(bookmark),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            inherit: true,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bookmark.pageNumber} 페이지',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            inherit: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => onEditTap(bookmark),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => onDeleteTap(bookmark),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (bookmark.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: Text(
                    bookmark.note.isNotEmpty ? bookmark.note : '메모 없음',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                      inherit: true,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (bookmark.selectedText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '선택된 텍스트:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    inherit: true,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  child: Text(
                    bookmark.selectedText,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      inherit: true,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 