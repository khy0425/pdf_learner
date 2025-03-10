/// 웹 환경에서 사용할 Platform 스텁 클래스
class Platform {
  static const bool isWindows = false;
  static const bool isMacOS = false;
  static const bool isLinux = false;
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static bool get isFuchsia => false;
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
} 