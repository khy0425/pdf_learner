/// dart:indexed_db 스텁
/// 웹이 아닌 환경에서 사용하기 위한 스텁 파일

class IndexedDB {
  Future<Database> open(String name, {int? version}) async {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
}

class Database {
  Transaction transaction(String storeName, String mode) {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
}

class Transaction {
  ObjectStore objectStore(String name) {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
}

class ObjectStore {
  Future<void> put(dynamic value, [dynamic key]) async {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
  
  Future<dynamic> get(dynamic key) async {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
  
  Future<void> delete(dynamic key) async {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
  
  Future<List<dynamic>> getAllKeys() async {
    throw UnsupportedError('IndexedDB는 웹 환경에서만 지원됩니다.');
  }
} 