import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'user_device_service.dart';

// 계정 찾기·비밀번호 재설정 API 오류
class AccountRecoveryException implements Exception {
  final String message;

  const AccountRecoveryException(this.message);
}

class AccountRecoveryService {
  // 아이디 찾기
  Future<String> findId({
    required String email,
    required String emailAdr,
    required String verificationToken,
  }) async {
    final body = await _post('/find-id', {
      'email': email.trim().toLowerCase(),
      'emailAdr': emailAdr.trim().toLowerCase(),
      'verificationToken': verificationToken,
    });

    final userId = body['userId'];

    if (userId is! String || userId.isEmpty) {
      throw const AccountRecoveryException('아이디 응답을 확인하지 못했어요. 다시 인증해 주세요.');
    }

    return userId;
  }

  // 비밀번호 재설정
  Future<void> resetPassword({
    required String userId,
    required String email,
    required String emailAdr,
    required String verificationToken,
    required String userPw,
    required String userPwConfirm,
  }) async {
    await _post('/reset-password', {
      'userId': userId.trim(),
      'email': email.trim().toLowerCase(),
      'emailAdr': emailAdr.trim().toLowerCase(),
      'verificationToken': verificationToken,
      'userPw': userPw,
      'userPwConfirm': userPwConfirm,
    });
  }

  // 계정 관련 공통 POST 요청
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      // 로그인 전 사용하는 API이므로 로그인 토큰을 보내지 않음
      final response = await http
          .post(
            Uri.parse('${UserDeviceService.serverUrl}/api/users$path'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic>? body;

      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } on FormatException {
        // HTML 등 예상하지 못한 응답은 기본 안내로 처리
      }

      if (response.statusCode == 200 && body != null) {
        return body;
      }

      final message = body?['message'];

      throw AccountRecoveryException(
        message is String && message.isNotEmpty
            ? message
            : '요청을 처리하지 못했어요. 다시 시도해 주세요.',
      );
    } on TimeoutException {
      throw AccountRecoveryException(
        path == '/reset-password'
            ? '응답이 지연되고 있어요. 이미 변경됐을 수 있으니 새 비밀번호로 로그인을 확인해 주세요.'
            : '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
      );
    } on http.ClientException {
      throw const AccountRecoveryException('서버에 연결하지 못했어요. 연결 상태를 확인해 주세요.');
    }
  }
}
