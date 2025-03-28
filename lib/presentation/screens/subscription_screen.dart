import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/models/user_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/locale_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/payment/payment_service.dart';
import '../../services/firebase_service.dart';
import 'language_selection_screen.dart';
import '../../core/di/dependency_injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/config_utils.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);
  
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // PayPal 설정
  late final String _basicPlanId;
  late final String _premiumPlanId;
  late final String _paypalClientId;
  late final String _paypalMerchantId;

  // 선택된 통화
  String _selectedCurrency = 'USD';
  // 통화별 가격 맵
  final Map<String, Map<String, double>> _pricingByCurrency = {
    'USD': {'standard': 1.99, 'premium': 3.99},
    'EUR': {'standard': 1.79, 'premium': 3.59},
    'GBP': {'standard': 1.49, 'premium': 3.29},
    'JPY': {'standard': 220, 'premium': 440},
    'KRW': {'standard': 2390, 'premium': 4790},
  };
  
  // 통화 심볼 맵
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'KRW': '₩',
  };
  
  // 국가별 통화 매핑
  final Map<String, String> _countryCurrencyMap = {
    'en': 'USD',
    'es': 'EUR',
    'fr': 'EUR',
    'de': 'EUR',
    'ja_JP': 'JPY',
    'ko_KR': 'KRW',
    'zh_CN': 'USD',
  };
  
  // 로케일 뷰모델
  late LocaleViewModel _localeViewModel;
  
  // 결제 처리 중 상태
  bool _isProcessingPayment = false;
  
  @override
  void initState() {
    super.initState();
    _localeViewModel = DependencyInjection.instance<LocaleViewModel>();
    _initPayPalConfig();
    _initCurrency();
  }
  
  void _initPayPalConfig() {
    try {
      _basicPlanId = ConfigUtils.getPayPalBasicPlanId();
      _premiumPlanId = ConfigUtils.getPayPalPremiumPlanId();
      _paypalClientId = ConfigUtils.getPayPalClientId();
      _paypalMerchantId = ConfigUtils.getPayPalMerchantId();
    } catch (e) {
      debugPrint('PayPal 설정 초기화 실패: $e');
      // 에러 처리
    }
  }
  
  // 현재 로케일에 따라 통화 초기화
  void _initCurrency() {
    final localeKey = _localeViewModel.locale.languageCode;
    final countryCode = _localeViewModel.locale.countryCode;
    
    final fullLocaleKey = countryCode != null && countryCode.isNotEmpty
        ? '${localeKey}_$countryCode'
        : localeKey;
    
    _selectedCurrency = _countryCurrencyMap[fullLocaleKey] ?? 'USD';
  }
  
  // 특정 통화의 스탠다드 플랜 가격
  double get standardPrice => _pricingByCurrency[_selectedCurrency]?['standard'] ?? 4.99;
  
  // 특정 통화의 프리미엄 플랜 가격
  double get premiumPrice => _pricingByCurrency[_selectedCurrency]?['premium'] ?? 9.99;
  
  // 통화 심볼
  String get currencySymbol => _currencySymbols[_selectedCurrency] ?? '\$';
  
  // 통화 변경 다이얼로그 표시
  void _showCurrencySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('select_currency')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _pricingByCurrency.length,
            itemBuilder: (context, index) {
              final currency = _pricingByCurrency.keys.elementAt(index);
              final isSelected = currency == _selectedCurrency;
              
              return ListTile(
                title: Text('$currency (${_currencySymbols[currency] ?? ''})'),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  // 결제 처리
  void _processPayment(String planType) async {
    if (planType != 'basic' && planType != 'premium') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('유효하지 않은 플랜 유형입니다')),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // PayPal 구독 페이지로 이동
      final planId = planType == 'basic' ? _basicPlanId : _premiumPlanId;
      final planName = planType == 'basic' ? '베이직 플랜' : '프리미엄 플랜';
      
      if (planId.isEmpty) {
        throw Exception('유효하지 않은 플랜 ID');
      }
      
      debugPrint('플랜 ID: $planId, 플랜 이름: $planName');
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PayPalSubscriptionPage(
            planId: planId,
            planName: planName,
            planType: planType,
            paypalClientId: _paypalClientId,
            paypalMerchantId: _paypalMerchantId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('결제 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('subscription')),
        actions: [
          // 언어 선택 버튼
          const LanguageDropdown(),
          
          // 통화 선택 버튼
          IconButton(
            icon: Text(
              _selectedCurrency,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: _showCurrencySelectionDialog,
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          final user = authViewModel.currentUser;
          if (user == null) return const SizedBox();

          return SingleChildScrollView(
            child: Column(
              children: [
                // 현재 구독 상태 (간소화)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('beta_tester_benefit'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(localizations.translate('beta_description')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 구독 플랜
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    localizations.translate('subscription_plans'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                // 스탠다드 플랜
                _buildSubscriptionPlanCard(
                  title: localizations.translate('standard_plan'),
                  price: '$currencySymbol$standardPrice/${localizations.translate('month')}',
                  features: [
                    localizations.translate('unlimited_pdf_uploads'),
                    localizations.translate('ai_summary'),
                    localizations.translate('pdf_qa'),
                    localizations.translate('cloud_sync'),
                  ],
                  onSubscribe: () => _processPayment('basic'),
                  localizations: localizations,
                ),
                
                // 프리미엄 플랜
                _buildSubscriptionPlanCard(
                  title: localizations.translate('premium_plan'),
                  price: '$currencySymbol$premiumPrice/${localizations.translate('month')}',
                  isPremium: true,
                  features: [
                    '${localizations.translate('all_standard_features')} +',
                    localizations.translate('ai_quiz_gen'),
                    localizations.translate('auto_mindmap'),
                    localizations.translate('learning_analysis'),
                    localizations.translate('priority_support'),
                  ],
                  onSubscribe: () => _processPayment('premium'),
                  localizations: localizations,
                ),
                
                // 멤버십 비교 (간소화)
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('available_features'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(localizations.translate('unlimited_pdf_uploads')),
                        _buildFeatureItem(localizations.translate('ai_summary')),
                        _buildFeatureItem(localizations.translate('pdf_qa')),
                        _buildFeatureItem(localizations.translate('notes_highlights')),
                        _buildFeatureItem(localizations.translate('cloud_sync')),
                        _buildFeatureItem(localizations.translate('dark_mode')),
                        const SizedBox(height: 24),
                        Text(
                          localizations.translate('upcoming_features'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(localizations.translate('ai_quiz_gen')),
                        _buildFeatureItem(localizations.translate('auto_mindmap')),
                        _buildFeatureItem(localizations.translate('learning_analysis')),
                        _buildFeatureItem(localizations.translate('realtime_collab')),
                        const SizedBox(height: 24),
                        Text(
                          localizations.translate('beta_notice'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.translate('beta_full_notice'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // 구독 플랜 카드 위젯
  Widget _buildSubscriptionPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required VoidCallback onSubscribe,
    required AppLocalizations localizations,
    bool isPremium = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPremium ? Colors.amber : Colors.blue,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.amber.shade800 : Colors.blue,
                  ),
                ),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      localizations.translate('popular'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isPremium ? Colors.amber.shade800 : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isPremium ? Colors.amber.shade700 : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.paypal, size: 24),
                    const SizedBox(width: 8),
                    Text(localizations.translate('subscribe_paypal')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// PayPal 구독 페이지
class PayPalSubscriptionPage extends StatefulWidget {
  final String planId;
  final String planName;
  final String planType;
  final String paypalClientId;
  final String paypalMerchantId;

  const PayPalSubscriptionPage({
    Key? key,
    required this.planId,
    required this.planName,
    required this.planType,
    required this.paypalClientId,
    required this.paypalMerchantId,
  }) : super(key: key);

  @override
  State<PayPalSubscriptionPage> createState() => _PayPalSubscriptionPageState();
}

class _PayPalSubscriptionPageState extends State<PayPalSubscriptionPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
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
            _setupJavaScriptBridge();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView 오류: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('paypal.com') ||
                request.url.contains('localhost') ||
                request.url.contains('127.0.0.1')) {
              debugPrint('허용된 URL로 이동: ${request.url}');
              return NavigationDecision.navigate;
            }
            debugPrint('차단된 URL로 이동 시도: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'SubscriptionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('JS 채널 메시지 수신: ${message.message}');
          final String data = message.message;
          if (data.startsWith('log:')) {
            debugPrint('PayPal 로그: ${data.substring(4)}');
          } else if (data.startsWith('success:')) {
            final String subscriptionId = data.substring(8);
            _handleSubscriptionSuccess(subscriptionId);
          } else if (data == 'cancel') {
            Navigator.of(context).pop();
          } else {
            debugPrint('알 수 없는 메시지: $data');
          }
        },
      )
      ..loadHtmlString(_getHtmlContent(widget.paypalClientId, widget.paypalMerchantId));
      
    debugPrint('WebView 초기화 완료');
  }

  // JavaScript 브릿지 설정
  Future<void> _setupJavaScriptBridge() async {
    try {
      // JavaScript 채널 설정 확인
      await _controller.runJavaScript('''
        if (window.SubscriptionChannel) {
          console.log('JavaScript 채널이 설정되었습니다');
        } else {
          console.log('JavaScript 채널이 설정되지 않았습니다');
        }
      ''');
      
      // 디버그 정보 표시 활성화
      await _controller.runJavaScript('''
        var debugElement = document.getElementById('debug-info');
        if (debugElement) {
          debugElement.style.display = 'block';
        }
      ''');
      
      // 통신 테스트
      await _controller.runJavaScript('''
        try {
          if (window.SubscriptionChannel && typeof window.SubscriptionChannel.postMessage === 'function') {
            window.SubscriptionChannel.postMessage('log:JavaScript 브릿지 통신 테스트');
          }
        } catch (e) {
          console.error('통신 테스트 오류:', e);
        }
      ''');
    } catch (e) {
      debugPrint('JavaScript 브릿지 설정 중 오류: $e');
    }
  }

  String _getHtmlContent(String clientId, String merchantId) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PayPal 구독</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              margin: 0;
              padding: 20px;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              background-color: #f5f5f7;
            }
            h1 {
              color: #0070ba;
              margin-bottom: 20px;
              text-align: center;
            }
            #paypal-button-container {
              width: 100%;
              max-width: 350px;
              margin: 0 auto;
            }
            .subscription-details {
              background-color: white;
              border-radius: 8px;
              padding: 16px;
              margin-bottom: 20px;
              width: 100%;
              max-width: 350px;
              box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .price {
              font-size: 24px;
              color: #2c2e2f;
              font-weight: bold;
              margin-bottom: 8px;
            }
            .plan-name {
              font-size: 18px;
              color: #2c2e2f;
              margin-bottom: 16px;
            }
            .feature {
              display: flex;
              margin-bottom: 8px;
            }
            .feature-icon {
              color: #0070ba;
              margin-right: 8px;
            }
            .debug-info {
              display: none;
              margin-top: 20px;
              padding: 10px;
              border: 1px solid #ccc;
              background-color: #f9f9f9;
              font-size: 12px;
              width: 100%;
              max-width: 350px;
            }
          </style>
        </head>
        <body>
          <h1>PayPal 구독</h1>
          
          <div class="subscription-details">
            <div class="plan-name">${widget.planType == 'basic' ? '기본 구독' : '프리미엄 구독'}</div>
            <div class="price">${widget.planType == 'basic' ? '₩9,900' : '₩19,900'}/월</div>
            <div class="feature"><span class="feature-icon">✓</span> PDF 파일 무제한 접근</div>
            <div class="feature"><span class="feature-icon">✓</span> 고급 주석 기능</div>
            ${widget.planType == 'premium' ? '<div class="feature"><span class="feature-icon">✓</span> 고급 검색 기능</div>' : ''}
            ${widget.planType == 'premium' ? '<div class="feature"><span class="feature-icon">✓</span> 클라우드 백업</div>' : ''}
          </div>
          
          <div id="paypal-button-container"></div>
          
          <div id="debug-info" class="debug-info"></div>
          
          <script>
            // 디버그 정보 출력 함수
            function log(message) {
              console.log(message);
              
              // 디버그 정보 표시
              var debugElement = document.getElementById('debug-info');
              if (debugElement) {
                debugElement.style.display = 'block';
                debugElement.innerHTML += '<div>' + message + '</div>';
              }
              
              // Flutter로 로그 전송
              try {
                if (window.SubscriptionChannel && typeof window.SubscriptionChannel.postMessage === 'function') {
                  window.SubscriptionChannel.postMessage('log:' + message);
                }
              } catch (e) {
                console.error('SubscriptionChannel 접근 오류:', e);
              }
            }
            
            log('HTML 페이지 로드됨');
            
            // Flutter와 통신할 수 있는 메서드 정의
            function communicateToFlutter(action, data) {
              log('Flutter에 메시지 전송: ' + action + (data ? ', ' + data : ''));
              
              try {
                if (window.SubscriptionChannel && typeof window.SubscriptionChannel.postMessage === 'function') {
                  if (action === 'success') {
                    window.SubscriptionChannel.postMessage('success:' + data);
                  } else if (action === 'cancel') {
                    window.SubscriptionChannel.postMessage('cancel');
                  } else if (action === 'error') {
                    window.SubscriptionChannel.postMessage('error:' + data);
                  }
                } else {
                  log('SubscriptionChannel이 설정되지 않았습니다');
                }
              } catch (e) {
                log('Flutter 통신 오류: ' + e);
              }
            }
            
            // PayPal 스크립트 로드
            var script = document.createElement('script');
            script.src = 'https://www.paypal.com/sdk/js?client-id=$clientId&vault=true&intent=subscription&merchant-id=$merchantId';
            script.dataset.sdkIntegrationSource = 'button-factory';
            script.onload = function() {
              log('PayPal SDK 로드 완료');
              initPayPalButton();
            };
            script.onerror = function() {
              log('PayPal SDK 로드 실패');
            };
            document.head.appendChild(script);
            
            function initPayPalButton() {
              try {
                paypal.Buttons({
                  style: {
                    shape: 'pill',
                    color: 'blue',
                    layout: 'vertical',
                    label: 'subscribe'
                  },
                  createSubscription: function(data, actions) {
                    log('구독 생성 중...');
                    return actions.subscription.create({
                      'plan_id': '${widget.planId}'
                    });
                  },
                  onApprove: function(data, actions) {
                    log('구독 승인됨: ' + JSON.stringify(data));
                    communicateToFlutter('success', data.subscriptionID);
                  },
                  onCancel: function(data) {
                    log('구독 취소됨');
                    communicateToFlutter('cancel');
                  },
                  onError: function(err) {
                    log('구독 오류: ' + err);
                    communicateToFlutter('error', err.toString());
                  }
                }).render('#paypal-button-container');
              } catch (e) {
                log('PayPal 버튼 초기화 오류: ' + e);
              }
            }
            
            // 페이지 로드 완료 시 로그
            window.onload = function() {
              log('Window loaded');
            };
          </script>
        </body>
      </html>
    ''';
  }

  void _handleSubscriptionSuccess(String subscriptionId) async {
    if (subscriptionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 ID가 유효하지 않습니다')),
      );
      Navigator.of(context).pop();
      return;
    }

    debugPrint('구독 ID: $subscriptionId 처리 중');
    
    try {
      // 로딩 표시
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 16),
              Text('구독 정보 처리 중...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(content: Text('사용자 정보를 찾을 수 없습니다')),
        );
        Navigator.of(context).pop();
        return;
      }

      final firebaseService = DependencyInjection.instance<FirebaseService>();
      
      // 구독 정보 저장
      final subscriptionData = {
        'subscriptionId': subscriptionId,
        'planId': widget.planId,
        'planName': widget.planName,
        'planType': widget.planType,
        'status': 'active',
        'startDate': Timestamp.now(),
        'provider': 'paypal',
      };
      
      debugPrint('구독 정보 저장 시작: $subscriptionData');
      
      final result = await firebaseService.saveSubscription(userId, subscriptionData);
      
      // 로딩 메시지 숨기기
      scaffold.hideCurrentSnackBar();
      
      if (result.isSuccess) {
        debugPrint('구독 저장 성공');
        scaffold.showSnackBar(
          SnackBar(
            content: Text('구독이 성공적으로 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 현재 화면 닫고 홈 화면으로 이동
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        debugPrint('구독 저장 실패: ${result.error}');
        scaffold.showSnackBar(
          SnackBar(
            content: Text('구독 정보 저장 중 오류가 발생했습니다: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('구독 처리 중 예외 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('구독 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PayPal 구독'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 