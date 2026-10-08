import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_device_model.dart';

class UserDeviceService {
  // Chrome: 개발 PC
  // Android 에뮬레이터: 에뮬레이터에서 개발 PC에 접근
  // iOS 시뮬레이터: 개발 Mac
  static String get serverUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }

  // 로컬 저장소에서 UUID를 찾을 때 사용하는 이름
  static const String _deviceIdKey = 'zipbob_device_id';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // 등록 성공 후 앱 실행 중 사용할 기기 정보
  static UserDeviceModel? currentDevice;

  // 1. 저장된 UUID가 있으면 사용하고, 없으면 생성해서 저장
  Future<String> _getOrCreateDeviceId() async {
    final savedId = await _preferences.getString(_deviceIdKey);

    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final newId = Uuid().v4();

    // API 호출 전에 저장하므로, 요청 실패 후 재시도해도 같은 UUID 사용
    await _preferences.setString(_deviceIdKey, newId);

    return newId;
  }

  // 2. 기기 정보 수집 후 백엔드에 등록 요청
  Future<UserDeviceModel> register() async {
    final deviceId = await _getOrCreateDeviceId();

    late final String osType;
    String? osVersion;
    String? deviceModel;

    if (kIsWeb) {
      osType = 'WEB';

      // 웹에서는 휴대폰 모델·OS 버전 조회를 생략
    } else {
      final platform = defaultTargetPlatform;

      if (platform == TargetPlatform.android) {
        osType = 'ANDROID';
      } else if (platform == TargetPlatform.iOS) {
        osType = 'IOS';
      } else {
        throw UnsupportedError('현재 Android, iOS, Web을 지원합니다.');
      }

      // 부가정보 조회 실패 때문에 기기 등록 전체가 실패하지 않도록 처리
      try {
        final deviceInfo = DeviceInfoPlugin();

        if (platform == TargetPlatform.android) {
          final info = await deviceInfo.androidInfo;
          osVersion = info.version.release;
          deviceModel = info.model;
        } else {
          final info = await deviceInfo.iosInfo;
          osVersion = info.systemVersion;
          deviceModel = info.utsname.machine;
        }
      } catch (error) {
        debugPrint('기기 부가정보 조회 실패: $error');
      }
    }

    final response = await http
        .post(
          Uri.parse('$serverUrl/api/user-devices'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'deviceId': deviceId,
            'osType': osType,
            'osVersion': osVersion,
            'deviceModel': deviceModel,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('기기 등록 실패: HTTP ${response.statusCode}');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final device = UserDeviceModel.fromJson(json);

    currentDevice = device;

    return device;
  }
}
