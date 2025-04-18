import 'package:flutter/material.dart';

/// 북마크 생성/편집 다이얼로그
class BookmarkDialog extends StatefulWidget {
  /// 제목 컨트롤러
  final TextEditingController titleController;
  
  /// 노트 컨트롤러
  final TextEditingController noteController;
  
  /// 생성자
  const BookmarkDialog({
    Key? key, 
    required this.titleController, 
    required this.noteController,
  }) : super(key: key);

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '북마크 추가',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          inherit: true,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.titleController,
            decoration: const InputDecoration(
              labelText: '제목',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.noteController,
            decoration: const InputDecoration(
              labelText: '메모',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            // 직접 유효성 검사
            if (widget.titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('제목을 입력해주세요')),
              );
              return;
            }
            
            // 유효한 경우 결과 반환
            Navigator.of(context).pop({
              'title': widget.titleController.text,
              'note': widget.noteController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('저장'),
        ),
      ],
    );
  }
} 