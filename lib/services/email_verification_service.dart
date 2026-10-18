import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'user_device_service.dart';

// 이메일 인증 API 오류
class EmailVerificationException implements Exception {
  final String message;

  const EmailVerificationException(this.message);
}

// 인증번호 발송 결과
class EmailVerificationSent {
  final int id;
  final int expiresInSeconds;

  const EmailVerificationSent(this.id, this.expiresInSeconds);
}

// 인증번호 확인 결과
class EmailVerificationConfirmed {
  final String token;
  final int expiresInSeconds;

  const EmailVerificationConfirmed(this.token, this.expiresInSeconds);
}

class EmailVerificationService {
  // 인증번호 발송
  Future<EmailVerificationSent> send({
    required String email,
    required String emailAdr,
    String purpose = 'SIGNUP',
  }) async {
    final body = await _post('/send', {
      'email': email.trim().toLowerCase(),
      'emailAdr': emailAdr.trim().toLowerCase(),
      'purpose': purpose,
    });

    final id = body['emailVerificationId'];
    final seconds = body['expiresInSeconds'];

    if (id is! int || id <= 0 || seconds is! int || seconds < 0) {
      throw const EmailVerificationException('인증 발송 응답을 확인하지 못했어요.');
    }

    return EmailVerificationSent(id, seconds);
  }

  // 인증번호 확인
  Future<EmailVerificationConfirmed> confirm({
    required int emailVerificationId,
    required String verificationCode,
  }) async {
    final body = await _post('/confirm', {
      'emailVerificationId': emailVerificationId,
      'verificationCode': verificationCode,
    });

    final token = body['verificationToken'];
    final seconds = body['expiresInSeconds'];

    if (token is! String || token.isEmpty || seconds is! int || seconds <= 0) {
      throw const EmailVerificationException(
        '인증 확인 응답을 확인하지 못했어요. 다시 인증해 주세요.',
      );
    }

    return EmailVerificationConfirmed(token, seconds);
  }

  // 이메일 인증 API 공통 요청
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${UserDeviceService.serverUrl}'
              '/api/email-verifications$path',
            ),
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
        // JSON이 아닌 응답이면 기본 안내 문구 사용
      }

      if (response.statusCode == 200 && body != null) {
        return body;
      }

      final message = body?['message'];

      throw EmailVerificationException(
        message is String && message.isNotEmpty
            ? message
            : '이메일 인증을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    } on TimeoutException {
      throw const EmailVerificationException(
        '응답이 지연되고 있어요. '
        '발송 요청이었다면 메일이 도착했을 수 있어요. '
        '잠시 후 재발송해 주세요.',
      );
    } on http.ClientException {
      throw const EmailVerificationException('서버에 연결하지 못했어요. 연결 상태를 확인해 주세요.');
    }
  }
}
