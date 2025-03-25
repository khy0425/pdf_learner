import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 비밀번호 보안 설명 다이얼로그
class PasswordSecurityDialog extends StatelessWidget {
  const PasswordSecurityDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.security,
                  color: Color(0xFF5D5FEF),
                  size: 28,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '비밀번호 암호화 관리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            const SizedBox(height: 8),
            _buildSecuritySection(
              '비밀번호 암호화 방식',
              '• Firebase는 업계 표준인 bcrypt 해싱 알고리즘 사용\n'
              '• 소금(salt)을 적용한 해싱으로 추가 보안 제공\n'
              '• 원본 비밀번호는 저장되지 않고 해시값만 저장',
            ),
            const SizedBox(height: 16),
            _buildSecuritySection(
              '데이터 전송 보안',
              '• 비밀번호는 HTTPS 암호화 연결을 통해 전송\n'
              '• 앱 내에서 비밀번호를 저장하지 않음\n'
              '• Google의 다중 레이어 보안 인프라 활용',
            ),
            const SizedBox(height: 16),
            _buildSecuritySection(
              '사용자 보호 조치',
              '• 비밀번호 입력 시 문자 표시 숨김 처리\n'
              '• 비밀번호 최소 6자 이상 요구\n'
              '• 안전한 비밀번호 재설정 제공',
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copySecurityGuide(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('보안 가이드 복사'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5D5FEF),
                      side: const BorderSide(color: Color(0xFF5D5FEF)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D5FEF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D5FEF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  void _copySecurityGuide(BuildContext context) {
    const securityGuide = """
Firebase Authentication 비밀번호 암호화 가이드

비밀번호 암호화 방식:
• Firebase는 업계 표준인 bcrypt 해싱 알고리즘 사용
• 비밀번호는 클라이언트(앱) 측에 저장되지 않음
• 비밀번호는 서버에서 해싱되어 저장됨 (원본 비밀번호는 저장 안 함)
• Google의 다중 레이어 보안 인프라로 보호됨

PDF 학습기 앱에서의 비밀번호 관리:
• 인증 정보는 안전한 HTTPS 연결을 통해 Firebase로 전송
• 비밀번호를 앱 내에 저장하지 않음
• Firebase의 인증 시스템을 활용한 안전한 인증 처리
• 비밀번호는 최소 6자 이상으로 요구
""";

    Clipboard.setData(const ClipboardData(text: securityGuide));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('비밀번호 보안 가이드가 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 