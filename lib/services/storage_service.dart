import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _storage;
  bool _isInitialized = false;
  final Map<String, UploadTask> _activeUploads = {};

  StorageService(this._storage);

  bool get isInitialized => _isInitialized;
  Map<String, UploadTask> get activeUploads => _activeUploads;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _storage.ref().listAll();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('스토리지 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final ref = _storage.ref().child(path).child(fileName);
    final uploadTask = ref.putData(bytes);
    _activeUploads[fileName] = uploadTask;
    notifyListeners();

    try {
      final snapshot = await uploadTask;
      _activeUploads.remove(fileName);
      notifyListeners();
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _activeUploads.remove(fileName);
      notifyListeners();
      debugPrint('파일 업로드 실패: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      debugPrint('파일 삭제 실패: $e');
      rethrow;
    }
  }

  Future<String> getDownloadUrl(String path) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      debugPrint('다운로드 URL 가져오기 실패: $e');
      rethrow;
    }
  }

  Future<List<String>> listFiles(String path) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _storage.ref().child(path).listAll();
      return result.items.map((item) => item.fullPath).toList();
    } catch (e) {
      debugPrint('파일 목록 가져오기 실패: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> getMetadata(String path) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final metadata = await _storage.ref().child(path).getMetadata();
      return {
        'contentType': metadata.contentType ?? '',
        'size': metadata.size.toString(),
        'timeCreated': metadata.timeCreated?.toIso8601String() ?? '',
        'updated': metadata.updated.toIso8601String(),
      };
    } catch (e) {
      debugPrint('메타데이터 가져오기 실패: $e');
      rethrow;
    }
  }

  void cancelUpload(String fileName) {
    final uploadTask = _activeUploads[fileName];
    if (uploadTask != null) {
      uploadTask.cancel();
      _activeUploads.remove(fileName);
      notifyListeners();
    }
  }

  void cancelAllUploads() {
    for (final uploadTask in _activeUploads.values) {
      uploadTask.cancel();
    }
    _activeUploads.clear();
    notifyListeners();
  }
} 