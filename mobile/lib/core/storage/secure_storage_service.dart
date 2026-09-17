import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage();

  static const accessTokenKey = "access_token";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: accessTokenKey);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
