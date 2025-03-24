import 'package:flutter/material.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

/// PDF 뷰어 툴바 위젯
class PDFToolbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback onBackPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onMoreOptionsPressed;
  
  const PDFToolbarWidget({
    Key? key,
    required this.title,
    required this.onBackPressed,
    required this.onSearchPressed,
    required this.onBookmarkPressed,
    required this.onMoreOptionsPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFF333333),
      elevation: 4,
      title: Text(
        title ?? '문서 보기',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed,
      ),
      actions: [
        // 검색 버튼
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: onSearchPressed,
        ),
        // 북마크 버튼
        IconButton(
          icon: const Icon(Icons.bookmark, color: Colors.white),
          onPressed: onBookmarkPressed,
        ),
        // 추가 옵션 버튼
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: onMoreOptionsPressed,
        ),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// PDF 뷰어용 검색 앱바 위젯
class PdfViewerSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;
  
  const PdfViewerSearchAppBar({
    Key? key,
    required this.searchController,
    required this.onBackPressed,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFF333333),
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed,
      ),
      title: TextField(
        controller: searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              searchController.clear();
              onClear();
            },
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 