import 'package:flutter/material.dart';
import '../../models/pdf_file_info.dart';
import '../../theme/app_theme.dart';

/// PDF 목록 위젯
/// PDF 파일의 목록을 리스트로 표시합니다.
class PdfListWidget extends StatelessWidget {
  final List<PdfFileInfo> pdfFiles;
  final Function(PdfFileInfo) onDelete;

  const PdfListWidget({
    super.key,
    required this.pdfFiles,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pdfFiles.length,
      itemBuilder: (context, index) {
        final pdf = pdfFiles[index];
        return _buildPdfListItem(context, pdf);
      },
    );
  }

  Widget _buildPdfListItem(BuildContext context, PdfFileInfo pdf) {
    // 파일 크기는 이미 모델에서 포맷팅 제공
    String fileSize = pdf.formattedSize;

    // 다운로드 상태 표시
    Widget statusIcon;
    Color statusColor;
    String statusText;

    if (pdf.isCloudStored && !pdf.isLocal) {
      statusIcon = const CircularProgressIndicator(strokeWidth: 2);
      statusColor = Colors.blue;
      statusText = '다운로드 중...';
    } else if (pdf.isLocal) {
      statusIcon = const Icon(Icons.storage, size: 16);
      statusColor = Colors.green;
      statusText = '로컬 파일';
    } else if (pdf.isCloudStored) {
      statusIcon = const Icon(Icons.cloud_done, size: 16);
      statusColor = Colors.blue;
      statusText = '클라우드 저장됨';
    } else if (pdf.isGuestFile) {
      statusIcon = const Icon(Icons.warning, size: 16);
      statusColor = Colors.orange;
      statusText = '게스트 모드 - 로그인 시 파일이 저장됩니다';
    } else {
      statusIcon = const Icon(Icons.error, size: 16);
      statusColor = Colors.red;
      statusText = '알 수 없는 상태';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/pdf-viewer',
            arguments: pdf,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파일 이름 및 삭제 버튼
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pdf.fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(pdf),
                    tooltip: '삭제',
                    iconSize: 20,
                    splashRadius: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 파일 정보
              Row(
                children: [
                  // 파일 크기
                  Icon(
                    Icons.data_usage,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 추가 날짜
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(pdf.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 상태 표시
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: statusIcon,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 액션 버튼
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 보기 버튼
                  _buildActionButton(
                    context,
                    icon: Icons.visibility,
                    label: '보기',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pdf-viewer',
                        arguments: pdf,
                      );
                    },
                  ),
                  
                  // 검색 버튼
                  _buildActionButton(
                    context,
                    icon: Icons.search,
                    label: '검색',
                    onPressed: () {
                      // 검색 기능 구현
                      _showSearchDialog(context, pdf);
                    },
                  ),
                  
                  // 학습 버튼
                  _buildActionButton(
                    context,
                    icon: Icons.auto_stories,
                    label: '학습',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pdf-study',
                        arguments: pdf,
                      );
                    },
                  ),
                  
                  // 공유 버튼
                  _buildActionButton(
                    context,
                    icon: Icons.share,
                    label: '공유',
                    onPressed: () {
                      // 공유 기능 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('공유 기능은 준비 중입니다'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSearchDialog(BuildContext context, PdfFileInfo pdf) {
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 내용 검색'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${pdf.fileName} 내에서 검색할 내용을 입력하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: '검색어 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/pdf-search',
                  arguments: {
                    'pdf': pdf,
                    'query': searchController.text,
                  },
                );
              }
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return '알 수 없음';
    
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