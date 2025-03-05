/// 웹 환경에서 사용할 Platform 스텁 클래스
class Platform {
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isFuchsia => false;
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
} 