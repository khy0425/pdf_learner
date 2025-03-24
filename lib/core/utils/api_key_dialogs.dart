import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../views/auth/api_key_management_view.dart';
import '../views/auth/gemini_api_tutorial_view.dart';
import '../views/subscription/subscription_page.dart';

/// API 키 관련 다이얼로그 유틸리티
class ApiKeyDialogs {
  /// API 키를 찾을 수 없을 때 표시하는 대화상자
  static void showApiKeyUnavailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 필요'),
        content: const Text(
          'AI 요약 기능을 사용하려면 Gemini API 키가 필요합니다.\n\n'
          '구글 AI Studio에서 무료로 키를 발급받아 등록하거나, '
          '프리미엄 멤버십으로 업그레이드하세요.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiKeyManagementView(),
                ),
              );
            },
            child: const Text('API 키 등록'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              );
            },
            child: const Text('프리미엄 업그레이드'),
          ),
        ],
      ),
    );
  }

  /// API 키 할당량 초과시 표시하는 대화상자
  static void showQuotaExceededDialog(BuildContext context, {bool isPremium = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 할당량 초과'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(
                text: '오늘의 AI 요약 기능 사용량을 모두 소진했습니다.\n\n'
              ),
              if (!isPremium) 
                const TextSpan(
                  text: '다음 중 한 가지 방법을 선택할 수 있습니다:\n\n'
                )
              else
                const TextSpan(
                  text: '다음 방법을 사용해보세요:\n\n'
                ),
              if (!isPremium) ...[
                const TextSpan(
                  text: '1. ',
                ),
                TextSpan(
                  text: '프리미엄 멤버십으로 업그레이드',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      );
                    },
                ),
                const TextSpan(
                  text: '하여 일일 사용량 증가\n\n'
                ),
              ],
              TextSpan(
                text: isPremium ? '1. ' : '2. ',
              ),
              TextSpan(
                text: '나만의 API 키 등록',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApiKeyManagementView(),
                      ),
                    );
                  },
              ),
              const TextSpan(
                text: '하여 자유롭게 사용\n\n'
              ),
              TextSpan(
                text: isPremium ? '2. ' : '3. ',
              ),
              const TextSpan(
                text: '내일 다시 시도하기 (00시에 사용량 초기화)',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  /// API 키 튜토리얼 표시
  static void showApiKeyTutorialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 발급 방법'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Google AI Studio에서 무료로 API 키를 발급받을 수 있습니다.'),
              SizedBox(height: 12),
              Text('1. Google AI Studio 계정에 로그인합니다.'),
              Text('2. API 키 발급 페이지로 이동합니다.'),
              Text('3. "API 키 생성" 버튼을 클릭합니다.'),
              Text('4. 생성된 키를 복사하여 앱에 등록합니다.'),
              SizedBox(height: 12),
              Text('자세한 방법은 튜토리얼을 참고하세요.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeminiApiTutorialView(),
                ),
              );
            },
            child: const Text('튜토리얼 보기'),
          ),
        ],
      ),
    );
  }
  
  /// API 오류 다이얼로그
  static Future<void> showApiErrorDialog(
    BuildContext context, 
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 오류'),
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
  
  /// Google AI Studio 열기
  static Future<void> openGoogleAiStudio() async {
    final url = Uri.parse('https://makersuite.google.com/app/apikey');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('URL을 열 수 없습니다: $url');
    }
  }
} 