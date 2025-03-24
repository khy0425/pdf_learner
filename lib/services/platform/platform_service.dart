import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pdf_learner_v2/config/platform_config.dart';
import 'dart:async';

/// 플랫폼별 네이티브 기능을 제공하는 서비스 클래스
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  
  PlatformService._internal();
  
  static const MethodChannel _channel = MethodChannel('com.example.pdf_learner_v2/platform');
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final PlatformConfig _platformConfig = PlatformConfig();
  
  /// 파일 선택 다이얼로그를 표시하고 선택된 파일 경로를 반환
  Future<String?> pickFile({List<String>? allowedExtensions}) async {
    try {
      if (_platformConfig.isWeb) {
        // 웹에서는 JS 인터롭을 사용
        return _channel.invokeMethod<String>('pickFile', {
          'allowedExtensions': allowedExtensions ?? ['pdf'],
        });
      } else if (_platformConfig.isAndroid || _platformConfig.isIOS) {
        // 모바일에서는 네이티브 파일 피커 사용
        return _channel.invokeMethod<String>('pickFile', {
          'allowedExtensions': allowedExtensions ?? ['pdf'],
        });
      } else if (_platformConfig.isDesktop) {
        // 데스크톱에서는 네이티브 파일 다이얼로그 사용
        return _channel.invokeMethod<String>('pickFile', {
          'allowedExtensions': allowedExtensions ?? ['pdf'],
        });
      }
    } catch (e) {
      debugPrint('파일 선택 오류: $e');
    }
    return null;
  }
  
  /// 파일 저장 다이얼로그를 표시하고 저장 경로를 반환
  Future<String?> saveFile({required String fileName, String? content}) async {
    try {
      return _channel.invokeMethod<String>('saveFile', {
        'fileName': fileName,
        'content': content,
      });
    } catch (e) {
      debugPrint('파일 저장 오류: $e');
    }
    return null;
  }
  
  /// 공유 기능 실행
  Future<bool> shareContent({
    required String title,
    required String text,
    String? filePath,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareContent', {
        'title': title,
        'text': text,
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('공유 오류: $e');
      return false;
    }
  }
  
  /// 디바이스 정보 가져오기
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (_platformConfig.isWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'userAgent': webInfo.userAgent,
        };
      } else if (_platformConfig.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'device': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (_platformConfig.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'device': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else if (_platformConfig.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return {
          'platform': 'windows',
          'computerName': windowsInfo.computerName,
          'version': windowsInfo.displayVersion,
          'buildNumber': windowsInfo.buildNumber,
        };
      } else if (_platformConfig.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return {
          'platform': 'macos',
          'model': macOsInfo.model,
          'osRelease': macOsInfo.osRelease,
          'computerName': macOsInfo.computerName,
        };
      } else if (_platformConfig.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return {
          'platform': 'linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
        };
      }
    } catch (e) {
      debugPrint('디바이스 정보 가져오기 오류: $e');
    }
    
    return {'platform': 'unknown'};
  }
  
  /// 클립보드에 텍스트 복사
  Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('클립보드 복사 오류: $e');
      return false;
    }
  }
  
  /// 앱 평가 페이지 열기
  Future<bool> openAppRating() async {
    try {
      if (_platformConfig.isAndroid) {
        return _channel.invokeMethod<bool>('openAppRating', {
          'packageName': 'com.example.pdf_learner_v2',
        }) ?? false;
      } else if (_platformConfig.isIOS) {
        return _channel.invokeMethod<bool>('openAppRating', {
          'appId': '123456789', // 실제 App Store ID로 변경 필요
        }) ?? false;
      }
    } catch (e) {
      debugPrint('앱 평가 페이지 열기 오류: $e');
    }
    return false;
  }
  
  /// 바이브레이션 실행
  Future<void> vibrate({VibrationPattern pattern = VibrationPattern.medium}) async {
    if (!_platformConfig.isMobile) return;
    
    try {
      await _channel.invokeMethod('vibrate', {
        'pattern': pattern.index,
      });
    } catch (e) {
      debugPrint('진동 오류: $e');
    }
  }
  
  /// 네이티브 알림 표시
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'payload': payload,
      });
    } catch (e) {
      debugPrint('알림 표시 오류: $e');
    }
  }
}

/// 진동 패턴
enum VibrationPattern {
  light,
  medium,
  heavy,
  success,
  warning,
  error,
} 