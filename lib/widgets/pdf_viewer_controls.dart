import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerControls extends StatelessWidget {
  final PdfViewerController controller;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double zoomLevel;

  static const double minZoomLevel = 0.05;   // 최소 5%까지 축소 가능
  static const double maxZoomLevel = 5.0;    // 최대 500%까지 확대 가능
  static const double zoomStep = 0.05;       // 더 작은 단위로 조절 가능

  const PDFViewerControls({
    required this.controller,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.zoomLevel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomControls(context),
              const SizedBox(width: 16),
              _buildPageControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out),
          tooltip: '축소 (Ctrl + -)',
          onPressed: onZoomOut,
        ),
        PopupMenuButton<double>(
          tooltip: '배율 선택',
          initialValue: zoomLevel,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0.05, child: Text('5%')),
            const PopupMenuItem(value: 0.1, child: Text('10%')),
            const PopupMenuItem(value: 0.25, child: Text('25%')),
            const PopupMenuItem(value: 0.5, child: Text('50%')),
            const PopupMenuItem(value: 0.75, child: Text('75%')),
            const PopupMenuItem(value: 1.0, child: Text('100%')),
            const PopupMenuItem(value: 1.5, child: Text('150%')),
            const PopupMenuItem(value: 2.0, child: Text('200%')),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.fullscreen),
                  SizedBox(width: 8),
                  Text('페이지 맞춤'),
                ],
              ),
              onTap: () => _fitToPage(context),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.fit_screen),
                  SizedBox(width: 8),
                  Text('너비 맞춤'),
                ],
              ),
              onTap: () => _fitToWidth(context),
            ),
          ],
          onSelected: (value) {
            controller.zoomLevel = value;
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in),
          tooltip: '확대 (Ctrl + +)',
          onPressed: onZoomIn,
        ),
      ],
    );
  }

  Widget _buildPageControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.navigate_before),
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        IconButton(
          icon: const Icon(Icons.navigate_next),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }

  void _fitToPage(BuildContext context) {
    controller.zoomLevel = 1.0;
  }

  void _fitToWidth(BuildContext context) {
    controller.zoomLevel = 1.0;
  }
} 