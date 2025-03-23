import 'dart:async';
import 'dart:io';

/// 웹 환경에서 사용할 임시 디렉토리 스텁 구현
class Directory {
  final String path;
  
  Directory(this.path);
  
  static Directory get current => Directory('/');
  
  Future<bool> exists() async => true;

  /// 디렉토리 생성 함수 (스텁)
  Future<Directory> create({bool recursive = false}) async => this;
}

/// 웹 환경에서 path_provider 대체용 스텁 파일

/// 웹 환경에서 임시 디렉토리를 모방하는 함수
Future<Directory> getTemporaryDirectory() async {
  // 웹에서는 실제로 사용되지 않으므로 더미 구현만 제공
  throw UnsupportedError('웹 환경에서는 getTemporaryDirectory를 사용할 수 없습니다.');
}

/// 웹 환경에서 문서 디렉토리를 모방하는 함수
Future<Directory> getApplicationDocumentsDirectory() async {
  // 웹에서는 실제로 사용되지 않으므로 더미 구현만 제공
  throw UnsupportedError('웹 환경에서는 getApplicationDocumentsDirectory를 사용할 수 없습니다.');
}

/// 웹 환경에서 앱 지원 디렉토리를 모방하는 함수
Future<Directory> getApplicationSupportDirectory() async {
  // 웹에서는 실제로 사용되지 않으므로 더미 구현만 제공
  throw UnsupportedError('웹 환경에서는 getApplicationSupportDirectory를 사용할 수 없습니다.');
}

/// 웹 환경에서 외부 저장소 디렉토리를 모방하는 함수
Future<Directory?> getExternalStorageDirectory() async {
  // 웹에서는 실제로 사용되지 않으므로 더미 구현만 제공
  return null;
} 