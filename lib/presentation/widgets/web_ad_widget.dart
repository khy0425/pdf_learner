// 웹이 아닌 환경에서는 스텁 파일을 사용
import 'dart:html' if (dart.library.io) '../views/stub_html.dart' as html;
import 'dart:ui_web' if (dart.library.io) '../views/stub_ui_web.dart' as ui_web;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ad_service.dart';

// AdSense 스크립트가 이미 주입되었는지 추적
bool _isAdSenseInjected = false;

// 웹 광고 위젯
class WebAdWidget extends StatelessWidget {
  final AdPosition position;
  final AdBannerSize size;
  final AdType adType;
  final String? adUnitId;

  const WebAdWidget({
    Key? key,
    this.position = AdPosition.bottom,
    this.size = AdBannerSize.banner,
    this.adType = AdType.banner,
    this.adUnitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 웹이 아닌 환경에서는 광고를 표시하지 않음
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // 웹 환경에서만 사용하는 광고 위젯
    return _WebAdWidgetImpl(
      position: position,
      size: size,
      adType: adType,
      adUnitId: adUnitId,
    );
  }
}

// 실제 웹 광고 구현 (웹 환경에서만 사용)
class _WebAdWidgetImpl extends StatefulWidget {
  final AdPosition position;
  final AdBannerSize size;
  final AdType adType;
  final String? adUnitId;

  const _WebAdWidgetImpl({
    Key? key,
    required this.position,
    required this.size,
    required this.adType,
    this.adUnitId,
  }) : super(key: key);

  @override
  State<_WebAdWidgetImpl> createState() => _WebAdWidgetImplState();
}

class _WebAdWidgetImplState extends State<_WebAdWidgetImpl> {
  String _htmlId = '';
  bool _isAdLoaded = false;
  String _errorMessage = '';
  bool _isAdVisible = false;

  @override
  void initState() {
    super.initState();
    
    // 웹에서만 실행
    if (kIsWeb) {
      _htmlId = 'ad-container-${DateTime.now().millisecondsSinceEpoch}';
      
      // AdSense 스크립트 주입
      _injectAdSenseScript();
      
      // 광고 로드 지연 (스크립트 로드를 위한 시간)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _loadAd();
          
          // 지연 후 광고 표시 (로드 시간 확보)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isAdVisible = true;
              });
            }
          });
        }
      });
    } else {
      _errorMessage = '이 플랫폼에서는 사용할 수 없습니다';
    }
  }

  // AdSense 스크립트 확인 및 필요시 주입
  void _injectAdSenseScript() {
    if (_isAdSenseInjected) {
      debugPrint('AdSense 스크립트가 이미 주입되었습니다');
      return; // 이미 주입된 경우 중복 주입 방지
    }
    
    // 이미 스크립트가 존재하는지 확인
    if (_checkAdSenseScript()) {
      _isAdSenseInjected = true;
      debugPrint('AdSense 스크립트가 이미 존재합니다.');
      return;
    }
    
    try {
      // 존재하지 않으면 AdSense 스크립트 추가
      final adSenseScript = html.ScriptElement()
        ..async = true
        ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${AdService.getAdSenseClientId()}'
        ..type = 'text/javascript';
      
      // 로드 성공 알림
      adSenseScript.onLoad.listen((event) {
        debugPrint('AdSense 스크립트 로드 성공');
        
        // 바로 광고 로드 시도
        if (mounted) {
          _loadAd();
        }
      });
      
      // 로드 오류 처리
      adSenseScript.onError.listen((event) {
        debugPrint('AdSense 스크립트 로드 실패: ${event.toString()}');
        setState(() {
          _errorMessage = 'AdSense 스크립트 로드 실패';
        });
      });
  
      html.document.head?.append(adSenseScript);
      _isAdSenseInjected = true;
      debugPrint('AdSense 스크립트 주입 시작');
    } catch (e) {
      debugPrint('AdSense 스크립트 주입 중 오류: $e');
      setState(() {
        _errorMessage = 'AdSense 초기화 오류';
      });
    }
  }
  
  // AdSense 스크립트 확인
  bool _checkAdSenseScript() {
    try {
      final scripts = html.document.getElementsByTagName('script');
      for (int i = 0; i < scripts.length; i++) {
        final script = scripts[i];
        if (script is html.ScriptElement) {
          if (script.src.contains('pagead2.googlesyndication.com/pagead/js/adsbygoogle.js')) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('AdSense 스크립트 확인 중 오류: $e');
      return false;
    }
  }

  // 광고 크기 설정
  Map<String, int> _getAdSize() {
    switch (widget.size) {
      case AdBannerSize.banner:
        return {'width': 320, 'height': 50};
      case AdBannerSize.largeBanner:
        return {'width': 320, 'height': 100};
      case AdBannerSize.mediumRectangle:
        return {'width': 300, 'height': 250};
      default:
        return {'width': 320, 'height': 50};
    }
  }

  // 광고 로드
  void _loadAd() {
    if (!mounted) return;
    
    final adSize = _getAdSize();
    final width = adSize['width']!;
    final height = adSize['height']!;
    final adUnitId = widget.adUnitId ?? AdService.getAdSenseAdUnitId();
    
    if (adUnitId.isEmpty) {
      setState(() {
        _errorMessage = '광고 ID가 설정되지 않음';
      });
      return;
    }

    // 기존 요소가 있으면 제거
    final oldElement = html.document.getElementById(_htmlId);
    if (oldElement != null) {
      oldElement.remove();
    }

    try {
      // 새 컨테이너 생성
      final adContainer = html.DivElement()
        ..id = _htmlId
        ..style.width = '${width}px'
        ..style.height = '${height}px'
        ..style.overflow = 'hidden'
        ..style.background = '#f9f9f9';
      
      // 직접 iframe 요소 생성
      final adIframe = html.IFrameElement()
        ..width = width.toString()
        ..height = height.toString()
        ..style.border = 'none'
        ..srcdoc = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              body { margin: 0; padding: 0; overflow: hidden; }
              .adsbygoogle { display: block; width: ${width}px; height: ${height}px; }
            </style>
            <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${AdService.getAdSenseClientId()}"></script>
          </head>
          <body>
            <ins class="adsbygoogle"
              style="display:inline-block;width:${width}px;height:${height}px"
              data-ad-client="${AdService.getAdSenseClientId()}"
              data-ad-slot="${adUnitId}"></ins>
            <script>
              (adsbygoogle = window.adsbygoogle || []).push({});
              console.log('광고 컨테이너 로드: ${width}x${height}');
            </script>
          </body>
          </html>
        ''';
      
      adContainer.append(adIframe);

      // body에 추가
      html.document.body?.append(adContainer);

      // 요소를 화면 밖으로 이동 (Flutter에서 관리할 것이므로)
      adContainer.style
        ..position = 'absolute'
        ..top = '-1000px'
        ..left = '-1000px';

      // Flutter에서 사용할 View 등록
      ui_web.platformViewRegistry.registerViewFactory(_htmlId, (int viewId) {
        return adContainer;
      });

      setState(() {
        _isAdLoaded = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '광고 로드 실패';
      });
      debugPrint('광고 로드 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 광고 크기 설정
    final adSize = _getAdSize();
    final width = adSize['width']!;
    final height = adSize['height']!;
    
    return Container(
      width: width.toDouble(),
      height: height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge, // 내용이 넘치지 않도록 클립
      child: Stack(
        children: [
          // 광고가 로드되지 않았거나 오류가 있을 때 표시할 위젯
          if (!_isAdLoaded || _errorMessage.isNotEmpty)
            Center(
              child: _errorMessage.isNotEmpty
                ? Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            ),
          
          // 광고 위젯 (로드 완료 시에만 표시)
          if (_isAdVisible && _htmlId.isNotEmpty)
            Positioned.fill(
              child: HtmlElementView(
                viewType: _htmlId,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 광고 요소 정리
    final element = html.document.getElementById(_htmlId);
    if (element != null) {
      element.remove();
    }
    super.dispose();
  }
} 