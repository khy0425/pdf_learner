import 'package:flutter/material.dart';
import 'package:pdf_learner_v2/data/models/pdf_document.dart';
import 'package:pdf_learner_v2/theme/app_theme.dart';
import 'package:pdf_learner_v2/core/utils/date_formatter.dart';

/// UPDF 스타일의 PDF 문서 카드 위젯
class PDFDocumentCard extends StatelessWidget {
  final PDFDocument document;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final bool showFavoriteIcon;
  final bool isSelected;
  final bool showDate;
  final bool useGrid;

  const PDFDocumentCard({
    Key? key,
    required this.document,
    required this.onTap,
    this.onMoreTap,
    this.showFavoriteIcon = true,
    this.isSelected = false,
    this.showDate = true,
    this.useGrid = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return useGrid ? _buildGridItem(context) : _buildListItem(context);
  }

  /// 그리드 형태의 카드
  Widget _buildGridItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryDarkColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.05))
              : (isDark ? const Color(0xFF272727) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 영역
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 썸네일 이미지
                    _buildThumbnail(context),
                    
                    // 상단 즐겨찾기 및 더보기 버튼
                    if (showFavoriteIcon || onMoreTap != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            if (showFavoriteIcon)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  document.favorites.isNotEmpty
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: document.favorites.isNotEmpty
                                      ? Colors.red
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            if (showFavoriteIcon && onMoreTap != null)
                              const SizedBox(width: 8),
                            if (onMoreTap != null)
                              GestureDetector(
                                onTap: onMoreTap,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.more_horiz,
                                    color: Colors.white,
                                    size: 16,
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
            
            // 문서 정보 영역
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 문서 제목
                    Text(
                      document.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 날짜 표시
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          DateFormatter.formatToRelative(document.lastOpened),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : AppTheme.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  /// 리스트 형태의 카드
  Widget _buildListItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryDarkColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.05))
              : (isDark ? const Color(0xFF272727) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 썸네일 이미지
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildThumbnail(context),
              ),
            ),
            
            // 문서 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 문서 제목
                    Text(
                      document.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 날짜와 페이지 수
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              DateFormatter.formatToRelative(document.lastOpened),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : AppTheme.neutral500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${document.pageCount}페이지',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : AppTheme.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // 즐겨찾기 및 더보기 버튼
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showFavoriteIcon)
                  IconButton(
                    icon: Icon(
                      document.favorites.isNotEmpty
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: document.favorites.isNotEmpty
                          ? Colors.red
                          : (isDark ? Colors.grey[400] : AppTheme.neutral500),
                      size: 20,
                    ),
                    onPressed: () {
                      // 즐겨찾기 토글 기능 추가 필요
                    },
                  ),
                if (onMoreTap != null)
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.grey[400] : AppTheme.neutral500,
                      size: 20,
                    ),
                    onPressed: onMoreTap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 썸네일 위젯
  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    
    if (document.thumbnailPath.isNotEmpty) {
      // 실제 썸네일이 있는 경우
      return Image.network(
        document.thumbnailPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultThumbnail(theme);
        },
      );
    } else {
      // 기본 썸네일
      return _buildDefaultThumbnail(theme);
    }
  }

  /// 기본 썸네일 위젯
  Widget _buildDefaultThumbnail(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : AppTheme.neutral200,
      child: Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 32,
          color: isDark ? Colors.grey[600] : AppTheme.neutral500,
        ),
      ),
    );
  }
} 