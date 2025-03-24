import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../services/anonymous_user_service.dart';

/// 무료 사용 한도 초과 시 회원가입을 유도하는 다이얼로그
class SignUpPromptDialog extends StatelessWidget {
  final AnonymousUserService _anonymousUserService = AnonymousUserService();
  
  SignUpPromptDialog({Key? key}) : super(key: key);
  
  /// 다이얼로그 표시
  static Future<void> show(BuildContext context, {bool forceShow = false}) async {
    final dialog = SignUpPromptDialog();
    await dialog._showIfNeeded(context, forceShow: forceShow);
  }
  
  /// 필요한 경우에만 다이얼로그 표시
  Future<void> _showIfNeeded(BuildContext context, {bool forceShow = false}) async {
    if (forceShow || await _anonymousUserService.isFreeLimitExceeded()) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => this,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('무료 사용 한도 초과'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '무료 사용 한도를 초과했습니다. 계속 사용하려면 다음 중 하나를 선택해주세요:',
          ),
          SizedBox(height: 16),
          Text('• 회원가입 후 본인의 API 키 입력'),
          Text('• 유료 요금제 구독'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('나중에'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const AuthScreen(initialSignUp: true)),
            );
          },
          child: const Text('회원가입'),
        ),
      ],
    );
  }
} 