import 'dart:io' as io;
import 'package:flutter/foundation.dart';

/// 플랫폼 관련 유틸리티 클래스
class PlatformUtils {
  /// 웹 플랫폼 여부
  static bool get isWeb => kIsWeb;
  
  /// 모바일 플랫폼(Android, iOS) 여부
  static bool get isMobile {
    if (kIsWeb) return false;
    return io.Platform.isAndroid || io.Platform.isIOS;
  }
  
  /// Android 플랫폼 여부
  static bool get isAndroid {
    if (kIsWeb) return false;
    return io.Platform.isAndroid;
  }
  
  /// iOS 플랫폼 여부
  static bool get isIOS {
    if (kIsWeb) return false;
    return io.Platform.isIOS;
  }
  
  /// 데스크톱 플랫폼(Windows, macOS, Linux) 여부
  static bool get isDesktop {
    if (kIsWeb) return false;
    return io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux;
  }
  
  /// Windows 플랫폼 여부
  static bool get isWindows {
    if (kIsWeb) return false;
    return io.Platform.isWindows;
  }
  
  /// macOS 플랫폼 여부
  static bool get isMacOS {
    if (kIsWeb) return false;
    return io.Platform.isMacOS;
  }
  
  /// Linux 플랫폼 여부
  static bool get isLinux {
    if (kIsWeb) return false;
    return io.Platform.isLinux;
  }
} 