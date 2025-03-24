import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_keys.dart';

class ApiKeyService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, String> _apiKeys = {};

  Map<String, String> get apiKeys => _apiKeys;

  Future<void> initialize() async {
    await _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    _apiKeys = {
      'firebaseApiKey': await _storage.read(key: 'firebaseApiKey') ?? ApiKeys.firebaseApiKey,
      'firebaseAppId': await _storage.read(key: 'firebaseAppId') ?? ApiKeys.firebaseAppId,
      'firebaseMessagingSenderId': await _storage.read(key: 'firebaseMessagingSenderId') ?? ApiKeys.firebaseMessagingSenderId,
      'firebaseProjectId': await _storage.read(key: 'firebaseProjectId') ?? ApiKeys.firebaseProjectId,
      'firebaseStorageBucket': await _storage.read(key: 'firebaseStorageBucket') ?? ApiKeys.firebaseStorageBucket,
      'googleCloudApiKey': await _storage.read(key: 'googleCloudApiKey') ?? ApiKeys.googleCloudApiKey,
      'openAiApiKey': await _storage.read(key: 'openAiApiKey') ?? ApiKeys.openAiApiKey,
    };
    notifyListeners();
  }

  Future<void> updateApiKey(String key, String value) async {
    await _storage.write(key: key, value: value);
    _apiKeys[key] = value;
    notifyListeners();
  }

  String? getApiKey(String key) {
    return _apiKeys[key];
  }
} 