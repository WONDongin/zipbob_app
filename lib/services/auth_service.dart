import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_token_store.dart';
import 'user_device_service.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);
}

// 로그인한 회원 정보
class AuthUser {
  final String userId;
  final String userName;
  final String? email;

  const AuthUser({required this.userId, required this.userName, this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (json['userId'] is! String || json['userName'] is! String) {
      throw const AuthException('회원 정보를 확인하지 못했어요.');
    }

    return AuthUser(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] is String ? json['email'] as String : null,
    );
  }
}

// 액세스 토큰 + 리프레시 토큰
class _TokenPair {
  final String access;
  final String refresh;

  const _TokenPair(this.access, this.refresh);

  factory _TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];

    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const AuthException('로그인 토큰을 확인하지 못했어요.');
    }

    return _TokenPair(access, refresh);
  }

  Map<String, dynamic> toJson() => {
    'accessToken': access,
    'refreshToken': refresh,
  };
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService();

  AuthService({http.Client? client, AuthTokenStore? store})
    : _client = client ?? http.Client(),
      _store = store ?? PlatformAuthTokenStore();

  final http.Client _client;
  final AuthTokenStore _store;

  _TokenPair? _tokens;
  AuthUser? _user;

  Future<void>? _refreshing;
  Future<void> _storageQueue = Future<void>.value();

  int _generation = 0;
  bool _loggingOut = false;

  bool get hasSession => _tokens != null;
  AuthUser? get user => _user;

  String get _baseUrl => UserDeviceService.serverUrl;

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // 앱 시작 시 저장된 로그인 복원
  Future<void> restore() async {
    final saved = await _store.read();

    if (saved == null) return;

    try {
      final data = jsonDecode(saved);

      if (data is! Map<String, dynamic> || data['serverUrl'] != _baseUrl) {
        await _clear(_generation);
        return;
      }

      _tokens = _TokenPair.fromJson(data);
    } on FormatException {
      await _clear(_generation);
      return;
    } on AuthException {
      await _clear(_generation);
      return;
    }

    notifyListeners();

    try {
      await getMe();
    } on AuthException {
      // 인증 만료는 getMe/재발급에서 정리.
      // 일시적인 연결 실패는 저장된 토큰 유지.
    }
  }

  // 로그인
  Future<void> login({required String userId, required String userPw}) async {
    if (_loggingOut) {
      throw const AuthException('로그아웃 처리 후 다시 시도해 주세요.');
    }

    final generation = ++_generation;

    final response = await _post('/api/users/login', {
      'userId': userId.trim(),
      'userPw': userPw,
    });

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw AuthException(_message(body, '로그인하지 못했어요. 다시 시도해 주세요.'));
    }

    final tokens = _TokenPair.fromJson(body);
    final user = AuthUser.fromJson(body);

    await _save(tokens, generation);
    _checkGeneration(generation);

    _tokens = tokens;
    _user = user;

    notifyListeners();
  }

  // 현재 로그인한 회원 조회
  Future<AuthUser> getMe() async {
    final generation = _generation;

    final response = await authenticatedGet('/api/users/me');
    final body = _decode(response);

    if (response.statusCode != 200) {
      throw AuthException(_message(body, '회원 정보를 불러오지 못했어요.'));
    }

    _checkGeneration(generation);

    final user = AuthUser.fromJson(body);
    _user = user;

    notifyListeners();

    return user;
  }

  // 회원 전용 GET 요청
  Future<http.Response> authenticatedGet(String path) async {
    if (!path.startsWith('/api/') || path.contains('://')) {
      throw ArgumentError('같은 서버의 /api/ 경로만 사용할 수 있습니다.');
    }

    if (_loggingOut || _tokens == null) {
      throw const AuthException('로그인이 필요해요.');
    }

    final generation = _generation;
    final usedAccess = _tokens!.access;

    var response = await _get(path, usedAccess);

    _checkGeneration(generation);

    if (response.statusCode == 401) {
      // 다른 요청이 이미 갱신했다면 재발급 없이 새 토큰 사용
      if (_tokens?.access == usedAccess) {
        await _refresh();
      }

      _checkGeneration(generation);

      if (_tokens == null) {
        throw const AuthException('다시 로그인해 주세요.');
      }

      response = await _get(path, _tokens!.access);

      _checkGeneration(generation);

      if (response.statusCode == 401) {
        await _clear(generation);

        throw const AuthException('로그인이 만료됐어요. 다시 로그인해 주세요.');
      }
    }

    return response;
  }

  // 동시 요청은 하나의 재발급 작업을 공유
  Future<void> _refresh() async {
    final existing = _refreshing;

    if (existing != null) return existing;

    if (_loggingOut) {
      throw const AuthException('로그아웃 처리 중이에요.');
    }

    final operation = _performRefresh(_generation);
    _refreshing = operation;

    try {
      await operation;
    } finally {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
      }
    }
  }

  Future<void> _performRefresh(int generation) async {
    final refresh = _tokens?.refresh;

    if (refresh == null) {
      throw const AuthException('다시 로그인해 주세요.');
    }

    final response = await _post('/api/users/refresh', {
      'refreshToken': refresh,
    });

    _checkGeneration(generation);

    if (response.statusCode == 400 || response.statusCode == 401) {
      await _clear(generation);

      throw const AuthException('로그인이 만료됐어요. 다시 로그인해 주세요.');
    }

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw AuthException(_message(body, '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.'));
    }

    final tokens = _TokenPair.fromJson(body);

    await _save(tokens, generation);
    _checkGeneration(generation);

    _tokens = tokens;

    notifyListeners();
  }

  // 로그아웃
  Future<String> logout() async {
    if (_loggingOut) {
      throw const AuthException('로그아웃 처리 중이에요.');
    }

    _loggingOut = true;

    try {
      // 재발급 중이라면 완료된 새 리프레시 토큰을 폐기
      final pending = _refreshing;

      if (pending != null) {
        try {
          await pending;
        } catch (_) {
          // 재발급 실패와 관계없이 세션 정리 계속
        }
      }

      final refresh = _tokens?.refresh;
      final generation = ++_generation;

      _tokens = null;
      _user = null;

      notifyListeners();

      await _save(null, generation);

      if (refresh == null) return '로그아웃했어요.';

      try {
        final response = await _post('/api/users/logout', {
          'refreshToken': refresh,
        });

        if (response.statusCode == 204) {
          return '로그아웃했어요.';
        }
      } on AuthException {
        // 서버 연결 실패와 관계없이 기기의 토큰은 삭제됨
      }

      return '이 기기에서 로그아웃했어요. '
          '서버의 로그인 해제는 연결 문제로 완료하지 못했어요.';
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _clear(int generation) async {
    if (generation != _generation) return;

    final clearedGeneration = ++_generation;

    _tokens = null;
    _user = null;

    notifyListeners();

    await _save(null, clearedGeneration);
  }

  // 저장·삭제 순서 보장
  Future<void> _save(_TokenPair? tokens, int generation) {
    final operation = _storageQueue.then((_) async {
      if (generation != _generation) return;

      if (tokens == null) {
        await _store.delete();
      } else {
        await _store.write(
          jsonEncode({'serverUrl': _baseUrl, ...tokens.toJson()}),
        );
      }
    });

    _storageQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );

    return operation;
  }

  void _checkGeneration(int generation) {
    if (generation != _generation) {
      throw const AuthException('로그인 상태가 변경됐어요. 다시 시도해 주세요.');
    }
  }

  Future<http.Response> _get(String path, String access) {
    return _send(
      () => _client.get(
        Uri.parse('$_baseUrl$path'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $access'},
      ),
    );
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _send(Future<http.Response> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthException('응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.');
    } on http.ClientException {
      throw const AuthException('서버에 연결하지 못했어요. 연결 상태를 확인해 주세요.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (body is Map<String, dynamic>) return body;
    } on FormatException {
      // 비정상 응답을 화면에 그대로 표시하지 않음
    }

    throw const AuthException('서버 응답을 확인하지 못했어요. 다시 시도해 주세요.');
  }

  String _message(Map<String, dynamic> body, String fallback) {
    final message = body['message'];

    return message is String && message.isNotEmpty ? message : fallback;
  }
}
