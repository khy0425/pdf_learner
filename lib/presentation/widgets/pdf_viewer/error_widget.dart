import 'package:flutter/material.dart';

/// PDF 오류 표시 위젯
class PDFErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool showDetailedError;
  
  const PDFErrorWidget({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
    this.showDetailedError = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 오류 아이콘
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 24),
            
            // 오류 제목
            const Text(
              '문서를 불러올 수 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // 오류 메시지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _getSimplifiedErrorMessage(errorMessage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            
            // 상세 오류 메시지 (선택적)
            if (showDetailedError && errorMessage.length > 50)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // 재시도 버튼
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 문제 해결 팁
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '문제 해결 방법:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• 인터넷 연결 상태를 확인해보세요'),
                  const Text('• 문서가 손상되었거나 암호가 걸려있는지 확인해보세요'),
                  const Text('• 지원되는 PDF 형식인지 확인해보세요 (PDF 1.7 이하)'),
                  const Text('• 다른 문서를 열어서 앱이 정상 작동하는지 확인해보세요'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 오류 메시지를 사용자 친화적인 형태로 변환
  String _getSimplifiedErrorMessage(String errorMessage) {
    // 일반적인 오류 유형별 사용자 친화적 메시지
    if (errorMessage.contains('NetworkError') || 
        errorMessage.contains('net::ERR_') || 
        errorMessage.contains('Failed to fetch')) {
      return '네트워크 오류: 인터넷 연결을 확인해주세요.';
    } 
    else if (errorMessage.contains('CORS') || 
             errorMessage.contains('Cross-Origin')) {
      return '보안 제한: 웹 환경에서 이 PDF에 접근할 수 없습니다.';
    }
    else if (errorMessage.contains('password') || 
             errorMessage.contains('encrypted')) {
      return '암호화된 PDF: 이 문서는 비밀번호로 보호되어 있습니다.';
    }
    else if (errorMessage.contains('format') || 
             errorMessage.contains('invalid')) {
      return '지원되지 않는 형식: 유효한 PDF 파일이 아닙니다.';
    }
    else if (errorMessage.contains('Access denied') || 
             errorMessage.contains('permission')) {
      return '접근 권한 없음: 이 파일에 대한 읽기 권한이 없습니다.';
    }
    else {
      // 알 수 없는 오류인 경우
      return '문서를 열 수 없습니다. 다시 시도해보세요.';
    }
  }
} 