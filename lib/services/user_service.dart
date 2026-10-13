import 'dart:convert';

import 'package:http/http.dart' as http;

import 'user_device_service.dart';

// 서버가 반환한 회원가입 오류
class SignupException implements Exception {
  final String message;

  const SignupException(this.message);
}

class UserService {
  Future<String> signup({
    required String userId,
    required String userPw,
    required String userPwConfirm,
    required String userName,
    required String email,
    required String emailAdr,
  }) async {
    // 앱 시작 시 이미 등록한 기기 정보 사용
    final device = UserDeviceService.currentDevice;

    if (device == null) {
      throw const SignupException('기기 등록이 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    final response = await http
        .post(
          Uri.parse('${UserDeviceService.serverUrl}/api/users/signup'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'userId': userId.trim(),
            'userPw': userPw,
            'userPwConfirm': userPwConfirm,
            'userName': userName.trim(),
            'email': email.trim().toLowerCase(),
            'emailAdr': emailAdr.trim().toLowerCase(),
            'userDeviceId': device.userDeviceId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    // 성공·오류 응답 모두 JSON인지 확인
    Map<String, dynamic>? body;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } on FormatException {
      // JSON이 아니면 아래에서 기본 안내 문구 사용
    }

    if (response.statusCode == 201) {
      return body?['message'] is String
          ? body!['message'] as String
          : '회원가입이 완료되었습니다.';
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      final message = body?['message'];

      throw SignupException(
        message is String && message.isNotEmpty ? message : '가입 정보를 확인해 주세요.',
      );
    }

    throw const SignupException('회원가입을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
  }
}
