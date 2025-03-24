import 'package:flutter/material.dart';

/// PDF 뷰어 하단 제어바 위젯
class PDFBottomBarWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final Function(double)? onSliderChanged;
  final Function(double)? onSliderChangeEnd;
  final Function(int)? onPageChanged;
  
  const PDFBottomBarWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onSliderChanged,
    this.onSliderChangeEnd,
    this.onPageChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 페이지 수가 0인 경우 슬라이더 오류 방지
    final effectiveTotalPages = totalPages <= 0 ? 1 : totalPages;
    // 현재 페이지가 범위를 벗어나지 않도록 보정
    final effectiveCurrentPage = currentPage <= 0 
        ? 1 
        : (currentPage > effectiveTotalPages 
            ? effectiveTotalPages 
            : currentPage);
    
    return Material(
      elevation: 8.0,
      color: const Color(0xFF333333),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 페이지 슬라이더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  // 현재 페이지 / 전체 페이지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$effectiveCurrentPage / $effectiveTotalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 슬라이더
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.3),
                        valueIndicatorColor: Colors.black87,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: effectiveCurrentPage.toDouble(),
                        min: 1,
                        max: effectiveTotalPages.toDouble(),
                        divisions: effectiveTotalPages > 1 ? effectiveTotalPages - 1 : 1,
                        label: '${effectiveCurrentPage.round()}',
                        onChanged: (value) {
                          // 상위 위젯에 변경 이벤트 전달
                          if (onSliderChanged != null) {
                            onSliderChanged!(value);
                          }
                        },
                        onChangeEnd: (value) {
                          final page = value.round();
                          // 페이지 변경 콜백 호출
                          if (onPageChanged != null) {
                            onPageChanged!(page);
                          }
                          // 슬라이더 변경 종료 콜백 호출
                          if (onSliderChangeEnd != null) {
                            onSliderChangeEnd!(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 제어 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 이전 페이지 버튼
                _buildControlButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: effectiveCurrentPage > 1 ? onPreviousPage : null,
                  tooltip: '이전 페이지',
                ),
                // 다음 페이지 버튼
                _buildControlButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: effectiveCurrentPage < effectiveTotalPages ? onNextPage : null,
                  tooltip: '다음 페이지',
                ),
                // 구분선
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white30,
                ),
                // 축소 버튼
                _buildControlButton(
                  icon: Icons.zoom_out,
                  onPressed: onZoomOut,
                  tooltip: '축소',
                ),
                // 확대 버튼
                _buildControlButton(
                  icon: Icons.zoom_in,
                  onPressed: onZoomIn,
                  tooltip: '확대',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: onPressed == null ? Colors.grey.withOpacity(0.3) : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: onPressed == null ? Colors.grey : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
} 