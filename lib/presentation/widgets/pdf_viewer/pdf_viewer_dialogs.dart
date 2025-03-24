import 'package:flutter/material.dart';
import '../../models/pdf_document.dart';
import '../../models/pdf_bookmark.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';
import 'package:provider/provider.dart';

/// PDF 뷰어의 다이얼로그 및 모달을 관리하는 유틸리티 클래스
class PdfViewerDialogs {
  /// 북마크 모달 표시
  static void showBookmarks(
    BuildContext context, 
    PdfViewerViewModel viewModel,
    Function(int) onGoToPage,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF272727) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '북마크',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context);
                        showAddBookmarkDialog(
                          context: context,
                          currentPage: viewModel.currentPage,
                          onSave: (title) {
                            viewModel.addBookmark(title, viewModel.currentPage, 0.0);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: viewModel.bookmarks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('저장된 북마크가 없습니다.'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: viewModel.bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = viewModel.bookmarks[index];
                          return ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(bookmark.title),
                            subtitle: Text('${bookmark.pageNumber}페이지'),
                            onTap: () {
                              Navigator.pop(context);
                              onGoToPage(bookmark.pageNumber);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                viewModel.deleteBookmark(bookmark.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 북마크 목록 다이얼로그 표시 (새 API)
  static void showBookmarksDialog({
    required BuildContext context,
    required List<PDFBookmark> bookmarks,
    required int currentPage,
    required Function(PDFBookmark) onBookmarkSelected,
    required Function(String) onBookmarkDeleted,
    required VoidCallback onAddBookmark,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF272727) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '북마크',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context);
                        onAddBookmark();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: bookmarks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('저장된 북마크가 없습니다.'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          return ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(bookmark.title),
                            subtitle: Text('${bookmark.pageNumber}페이지'),
                            onTap: () {
                              onBookmarkSelected(bookmark);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                onBookmarkDeleted(bookmark.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 북마크 추가 다이얼로그
  static void showAddBookmarkDialog({
    required BuildContext context,
    required int currentPage,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('북마크 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '북마크 제목',
              hintText: '북마크 제목을 입력하세요',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onSave(controller.text.trim());
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }
  
  /// 더 많은 옵션 다이얼로그 표시
  static void showMoreOptionsDialog({
    required BuildContext context,
    required bool isFavorite,
    required VoidCallback onToggleFavorite,
    required VoidCallback onShare,
    required VoidCallback onDownload,
    required VoidCallback onOpenWith,
    required VoidCallback onGenerateSummary,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF272727) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  title: Text(isFavorite ? '즐겨찾기 제거' : '즐겨찾기 추가'),
                  onTap: () {
                    onToggleFavorite();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('공유'),
                  onTap: () {
                    onShare();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('다운로드'),
                  onTap: () {
                    onDownload();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('다른 앱으로 열기'),
                  onTap: () {
                    onOpenWith();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.summarize),
                  title: const Text('AI 요약 생성'),
                  onTap: () {
                    onGenerateSummary();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 문서 정보 다이얼로그 표시
  static void showDocumentInfo(
    BuildContext context, 
    PDFDocument document,
    PdfViewerViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('문서 정보', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, '제목', document.title),
              const SizedBox(height: 8),
              _buildInfoRow(context, '페이지 수', '${viewModel.totalPages}페이지'),
              const SizedBox(height: 8),
              _buildInfoRow(context, '파일 크기', '${(document.fileSize / 1024).toStringAsFixed(2)} KB'),
              const SizedBox(height: 8),
              _buildInfoRow(context, '추가 날짜', '${document.dateAdded.year}년 ${document.dateAdded.month}월 ${document.dateAdded.day}일'),
              const SizedBox(height: 8),
              _buildInfoRow(context, '마지막 열람', '${document.lastOpened.year}년 ${document.lastOpened.month}월 ${document.lastOpened.day}일'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  /// 텍스트 추출 다이얼로그
  static Future<void> showExtractTextDialog(
    BuildContext context, 
    PdfViewerViewModel viewModel,
  ) async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text("텍스트 추출 중..."),
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    
    try {
      final text = await viewModel.extractText();
      Navigator.pop(context); // 로딩 닫기
      
      // 추출된 텍스트 표시
      if (text.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("추출된 텍스트"),
            content: SingleChildScrollView(
              child: Text(text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("닫기"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("텍스트 추출 실패"),
            content: const Text("텍스트를 추출할 수 없습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 로딩 닫기
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("오류"),
          content: Text("텍스트 추출 중 오류가 발생했습니다: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }
  
  /// 정보 행 위젯
  static Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
} 