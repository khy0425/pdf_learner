import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner_v2/utils/web_stub.dart' as io;

/// 플랫폼별 설정 및 기능을 제공하는 클래스
class PlatformConfig {
  static final PlatformConfig _instance = PlatformConfig._internal();
  
  factory PlatformConfig() => _instance;
  
  PlatformConfig._internal();
  
  final Platform _platform = const LocalPlatform();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  bool get isWeb => kIsWeb;
  bool get isAndroid => !kIsWeb && _platform.isAndroid;
  bool get isIOS => !kIsWeb && _platform.isIOS;
  bool get isWindows => !kIsWeb && _platform.isWindows;
  bool get isMacOS => !kIsWeb && _platform.isMacOS;
  bool get isLinux => !kIsWeb && _platform.isLinux;
  bool get isFuchsia => !kIsWeb && _platform.isFuchsia;
  
  bool get isMobile => isAndroid || isIOS;
  bool get isDesktop => isWindows || isMacOS || isLinux;
  
  /// 현재 플랫폼에 대한 상세 정보를 제공
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final info = <String, dynamic>{
      'platform': currentPlatform,
      'isWeb': isWeb,
      'isMobile': isMobile,
      'isDesktop': isDesktop,
    };
    
    try {
      if (isWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        info['browser'] = webInfo.browserName.name;
        info['userAgent'] = webInfo.userAgent;
      } else if (isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['device'] = androidInfo.model;
        info['osVersion'] = androidInfo.version.release;
        info['sdkVersion'] = androidInfo.version.sdkInt.toString();
      } else if (isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['device'] = iosInfo.model;
        info['osVersion'] = iosInfo.systemVersion;
        info['name'] = iosInfo.name;
      } else if (isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info['osVersion'] = windowsInfo.displayVersion;
        info['buildNumber'] = windowsInfo.buildNumber;
      } else if (isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        info['osVersion'] = macOsInfo.osRelease;
        info['model'] = macOsInfo.model;
      } else if (isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info['name'] = linuxInfo.name;
        info['version'] = linuxInfo.version;
      }
    } catch (e) {
      debugPrint('플랫폼 정보 가져오기 오류: $e');
    }
    
    return info;
  }
  
  /// 현재 플랫폼 이름 반환
  String get currentPlatform {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isWindows) return 'windows';
    if (isMacOS) return 'macos';
    if (isLinux) return 'linux';
    if (isFuchsia) return 'fuchsia';
    return 'unknown';
  }
  
  /// 플랫폼별 기본 패딩 제공
  EdgeInsets getDefaultPadding() {
    if (isWeb) {
      return const EdgeInsets.all(16.0);
    } else if (isMobile) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }
  
  /// 현재 디바이스 화면 크기에 따른 레이아웃 타입 반환
  ScreenSizeType getScreenSizeType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return ScreenSizeType.mobile;
    } else if (width < 900) {
      return ScreenSizeType.tablet;
    } else if (width < 1200) {
      return ScreenSizeType.desktop;
    } else {
      return ScreenSizeType.largeDesktop;
    }
  }
  
  /// 플랫폼별 스타일 값 반환
  T getValueForPlatform<T>({
    required T defaultValue,
    T? webValue,
    T? androidValue,
    T? iosValue,
    T? windowsValue,
    T? macOSValue,
    T? linuxValue,
  }) {
    if (isWeb && webValue != null) return webValue;
    if (isAndroid && androidValue != null) return androidValue;
    if (isIOS && iosValue != null) return iosValue;
    if (isWindows && windowsValue != null) return windowsValue;
    if (isMacOS && macOSValue != null) return macOSValue;
    if (isLinux && linuxValue != null) return linuxValue;
    return defaultValue;
  }
  
  /// 현재 플랫폼에 적합한 파일 확장자 형식을 반환
  List<String> getSupportedPdfExtensions() {
    // 모든 플랫폼에서 기본적으로 지원하는 PDF 확장자
    return ['.pdf', 'application/pdf'];
  }
}

/// 화면 크기 타입
enum ScreenSizeType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
} 