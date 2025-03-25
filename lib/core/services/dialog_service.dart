import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@singleton
class DialogService {
  /// 확인 다이얼로그 표시
  Future<bool> showConfirmDialog(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 에러 다이얼로그 표시
  Future<void> showErrorDialog(
    BuildContext context, {
    String? title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 로딩 다이얼로그 표시
  Future<void> showLoadingDialog(
    BuildContext context, {
    String message = '로딩 중...',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// 로딩 다이얼로그 닫기
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
} 