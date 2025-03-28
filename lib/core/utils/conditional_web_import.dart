// 조건부 웹 임포트 처리
import 'dart:html' if (dart.library.io) './web_stub.dart';

// 웹 환경 여부 판단
const bool isWebPlatform = identical(0, 0.0); 