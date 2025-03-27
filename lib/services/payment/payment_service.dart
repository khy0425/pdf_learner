import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:injectable/injectable.dart';

/// 결제 상태 열거형
enum PaymentStatus {
  /// 초기 상태
  initial,
  
  /// 진행 중
  processing,
  
  /// 성공
  success,
  
  /// 실패
  failed,
  
  /// 취소됨
  cancelled
}

/// 결제 요청 모델
class PaymentRequest {
  /// 결제 금액
  final double amount;
  
  /// 결제 통화
  final String currency;
  
  /// 상품/서비스 이름
  final String productName;
  
  /// 생성자
  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.productName,
  });
}

/// 결제 응답 모델
class PaymentResponse {
  /// 결제 상태
  final PaymentStatus status;
  
  /// 트랜잭션 ID (성공 시)
  final String? transactionId;
  
  /// 에러 메시지 (실패 시)
  final String? errorMessage;
  
  /// 생성자
  PaymentResponse({
    required this.status,
    this.transactionId,
    this.errorMessage,
  });
  
  /// 결제 성공 여부
  bool get isSuccess => status == PaymentStatus.success;
}

/// 결제 제공자 인터페이스
abstract class PaymentProvider {
  /// 결제 처리
  Future<PaymentResponse> processPayment(PaymentRequest request);
}

/// PayPal 결제 제공자 구현
@injectable
class PayPalPaymentProvider implements PaymentProvider {
  /// PayPal 샌드박스 모드
  final bool _sandboxMode;
  
  /// PayPal 클라이언트 ID
  final String _clientId;
  
  /// PayPal 비밀 키
  final String _secret;
  
  /// 생성자
  PayPalPaymentProvider({
    bool sandboxMode = true,
    required String clientId,
    required String secret,
  })  : _sandboxMode = sandboxMode,
        _clientId = clientId,
        _secret = secret;
  
  @override
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // PayPal 결제 URL 구성
      final baseUrl = _sandboxMode
          ? 'https://www.sandbox.paypal.com'
          : 'https://www.paypal.com';
      
      final formattedAmount = request.amount.toStringAsFixed(2);
      
      final paypalUrl = Uri.parse(
        '$baseUrl/cgi-bin/webscr?cmd=_xclick'
        '&business=${Uri.encodeComponent(_clientId)}'
        '&currency_code=${Uri.encodeComponent(request.currency)}'
        '&amount=${Uri.encodeComponent(formattedAmount)}'
        '&item_name=${Uri.encodeComponent(request.productName)}'
        '&return=https://yourapp.com/payment/success'
        '&cancel_return=https://yourapp.com/payment/cancel',
      );
      
      // URL 런처로 PayPal 웹사이트 열기
      final canLaunch = await canLaunchUrl(paypalUrl);
      
      if (canLaunch) {
        await launchUrl(
          paypalUrl,
          mode: LaunchMode.externalApplication,
        );
        
        // 이 구현에서는 실제 결제 성공 여부를 알 수 없으므로
        // 브라우저가 열리면 성공 상태를 반환합니다.
        // 실제 구현에서는 웹훅이나 리디렉션 URL을 통해 결과를 확인해야 합니다.
        return PaymentResponse(
          status: PaymentStatus.processing,
          transactionId: 'pending', // 실제로는 별도의 로직으로 확인해야 함
        );
      } else {
        return PaymentResponse(
          status: PaymentStatus.failed,
          errorMessage: 'Could not launch PayPal',
        );
      }
    } catch (e) {
      return PaymentResponse(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
}

/// 결제 서비스
@injectable
class PaymentService {
  final Map<String, PaymentProvider> _providers = {};
  
  /// 생성자에서 기본 결제 제공자를 등록할 수 있습니다.
  PaymentService({PayPalPaymentProvider? paypalProvider}) {
    if (paypalProvider != null) {
      registerProvider('paypal', paypalProvider);
    }
  }
  
  /// 결제 제공자 등록
  void registerProvider(String name, PaymentProvider provider) {
    _providers[name] = provider;
  }
  
  /// 결제 제공자 가져오기
  PaymentProvider? getProvider(String name) {
    return _providers[name];
  }
  
  /// PayPal 결제 처리
  Future<PaymentResponse> processPayPalPayment(PaymentRequest request) async {
    final provider = _providers['paypal'];
    if (provider == null) {
      return PaymentResponse(
        status: PaymentStatus.failed,
        errorMessage: '결제 제공자가 구성되지 않았습니다.',
      );
    }
    
    try {
      return await provider.processPayment(request);
    } catch (e) {
      return PaymentResponse(
        status: PaymentStatus.failed,
        errorMessage: '결제 처리 중 오류: $e',
      );
    }
  }
}

/// PayPal 결제 웹뷰 화면
class PayPalWebViewScreen extends StatefulWidget {
  /// PayPal URL
  final String paypalUrl;
  
  /// 성공 URL
  final String successUrl;
  
  /// 취소 URL
  final String cancelUrl;
  
  /// 생성자
  const PayPalWebViewScreen({
    Key? key,
    required this.paypalUrl,
    required this.successUrl,
    required this.cancelUrl,
  }) : super(key: key);

  @override
  State<PayPalWebViewScreen> createState() => _PayPalWebViewScreenState();
}

class _PayPalWebViewScreenState extends State<PayPalWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initWebView();
  }
  
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // 성공 URL로 리디렉션된 경우
            if (request.url.startsWith(widget.successUrl)) {
              Navigator.pop(context, PaymentStatus.success);
              return NavigationDecision.prevent;
            }
            
            // 취소 URL로 리디렉션된 경우
            if (request.url.startsWith(widget.cancelUrl)) {
              Navigator.pop(context, PaymentStatus.cancelled);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paypalUrl));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, PaymentStatus.cancelled);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 