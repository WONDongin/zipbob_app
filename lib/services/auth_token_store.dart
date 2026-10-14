import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthTokenStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

// 토큰 저장 / 삭제
class PlatformAuthTokenStore implements AuthTokenStore {
  static const _key = 'zipbob_auth_session_v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _webSession;

  // 웹: 메모리 저장 / 모바일: 보안 저장소
  @override
  Future<String?> read() async {
    if (kIsWeb) return _webSession;

    return _storage.read(key: _key);
  }

  @override
  Future<void> write(String value) async {
    if (kIsWeb) {
      _webSession = value;
      return;
    }

    await _storage.write(key: _key, value: value);
  }

  @override
  Future<void> delete() async {
    if (kIsWeb) {
      _webSession = null;
      return;
    }

    // 인증 토큰만 삭제
    await _storage.delete(key: _key);
  }
}
