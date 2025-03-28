import 'dart:html' as html;
import 'package:js/js_util.dart' as js_util;

// 웹 환경을 위한 실제 구현
void setFirebaseConfig(Map<String, dynamic> config) {
  js_util.setProperty(html.window, 'firebaseConfig', config);
} 