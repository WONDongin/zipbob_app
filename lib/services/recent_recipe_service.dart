import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/all_menu_screen_model.dart';
import 'user_device_service.dart';

class RecentRecipeService {
  // 기기 등록 API에서 받은 서버의 정수 기기 ID 사용
  int _getUserDeviceId() {
    final device = UserDeviceService.currentDevice;

    if (device == null) {
      throw StateError('기기 등록이 완료되지 않았습니다.');
    }

    return device.userDeviceId;
  }

  // 목록 조회·기록 저장 요청에 사용할 URL 생성
  Uri _buildUri({int? menuId}) {
    final path = menuId == null
        ? '/api/recent-recipes'
        : '/api/recent-recipes/$menuId';

    return Uri.parse(
      '${UserDeviceService.serverUrl}$path',
    ).replace(queryParameters: {'userDeviceId': _getUserDeviceId().toString()});
  }

  // 최근 본 기록 저장 또는 마지막 조회 시간 갱신
  // PUT /api/recent-recipes/3?userDeviceId=1
  Future<void> recordView(int menuId) async {
    final response = await http
        .put(_buildUri(menuId: menuId))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 204) {
      throw Exception('최근 본 레시피 기록 저장 실패: HTTP ${response.statusCode}');
    }
  }

  // 기기별 최근 본 레시피 목록 조회
  // GET /api/recent-recipes?userDeviceId=1
  Future<List<AllMenuScreenModel>> fetchRecentRecipes() async {
    final response = await http
        .get(_buildUri())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('최근 본 레시피 목록 조회 실패: HTTP ${response.statusCode}');
    }

    // 한글이 깨지지 않도록 UTF-8로 디코딩
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    // JSON 목록을 메뉴 모델 목록으로 변환
    // 서버가 반환한 최신 조회순을 그대로 유지
    return body
        .map(
          (item) => AllMenuScreenModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
