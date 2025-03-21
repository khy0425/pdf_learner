import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../view_models/pdf_viewer_view_model.dart';

class PdfViewerControls extends StatelessWidget {
  final PdfViewerViewModel viewModel;
  final VoidCallback onSearch;
  final VoidCallback onThumbnails;
  final VoidCallback onBookmarks;
  final Function(String) onMenuAction;
  
  const PdfViewerControls({
    super.key,
    required this.viewModel,
    required this.onSearch,
    required this.onThumbnails,
    required this.onBookmarks,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopControls(context),
        _buildBottomControls(context),
      ],
    );
  }
  
  Widget _buildTopControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 컨트롤
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: '검색',
                onPressed: onSearch,
              ),
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white),
                tooltip: '썸네일 보기',
                onPressed: onThumbnails,
              ),
            ],
          ),
          
          // 중앙 - 페이지 표시
          GestureDetector(
            onTap: () => _showPageNavigationDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${viewModel.currentPage} / ${viewModel.totalPages}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 오른쪽 컨트롤
          Row(
            children: [
              IconButton(
                icon: Icon(
                  viewModel.isPageBookmarked(viewModel.currentPage)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: Colors.white,
                ),
                tooltip: '북마크',
                onPressed: onBookmarks,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: onMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'highlight',
                    child: Row(
                      children: [
                        Icon(Icons.highlight),
                        SizedBox(width: 8),
                        Text('하이라이트 모드'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.summarize),
                        SizedBox(width: 8),
                        Text('문서 요약'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('공유'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 이전 페이지 버튼
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            tooltip: '이전 페이지',
            onPressed: viewModel.currentPage > 1
                ? () => viewModel.previousPage()
                : null,
          ),
          
          // 다음 페이지 버튼
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            tooltip: '다음 페이지',
            onPressed: viewModel.currentPage < viewModel.totalPages
                ? () => viewModel.nextPage()
                : null,
          ),
          
          // 구분선
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          
          // 확대 버튼
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            tooltip: '확대',
            onPressed: () => viewModel.zoomIn(),
          ),
          
          // 축소 버튼
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            tooltip: '축소',
            onPressed: () => viewModel.zoomOut(),
          ),
          
          // 구분선
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          
          // 북마크 추가/제거 버튼
          IconButton(
            icon: Icon(
              viewModel.isPageBookmarked(viewModel.currentPage)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
            ),
            tooltip: '북마크 추가/제거',
            onPressed: () => viewModel.toggleBookmark(viewModel.currentPage),
          ),
        ],
      ),
    );
  }
  
  void _showPageNavigationDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 이동'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - ${viewModel.totalPages} 범위 내 페이지 번호 입력',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final pageNumber = int.tryParse(controller.text);
              if (pageNumber != null && 
                  pageNumber >= 1 && 
                  pageNumber <= viewModel.totalPages) {
                viewModel.goToPage(pageNumber);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('유효한 페이지 번호를 입력해주세요')),
                );
              }
            },
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }
} 