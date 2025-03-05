import 'package:flutter/material.dart';

class PDFThumbnails extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;
  final ScrollController scrollController;

  const PDFThumbnails({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    required this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: ListView.builder(
          controller: scrollController,
          itemCount: totalPages,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final isCurrentPage = currentPage == pageNumber;
            
            return _buildThumbnailItem(
              context,
              pageNumber,
              isCurrentPage,
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailItem(
    BuildContext context,
    int pageNumber,
    bool isCurrentPage,
  ) {
    return GestureDetector(
      onTap: () => onPageSelected(pageNumber),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentPage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isCurrentPage ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isCurrentPage
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: AspectRatio(
          aspectRatio: 0.7,  // A4 용지 비율에 근접
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  color: isCurrentPage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isCurrentPage
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: isCurrentPage ? 16 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 