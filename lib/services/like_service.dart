import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/all_menu_screen_model.dart';
import 'user_device_service.dart';

class LikeService {
  // 기기 등록 API에서 받은 서버의 정수 기기 ID 사용
  int _getUserDeviceId() {
    final device = UserDeviceService.currentDevice;

    if (device == null) {
      throw StateError('기기 등록이 완료되지 않았습니다.');
    }

    return device.userDeviceId;
  }

  // 목록·등록·삭제 요청에 사용할 URL 생성
  Uri _buildUri({int? menuId}) {
    final path = menuId == null ? '/api/favorites' : '/api/favorites/$menuId';

    return Uri.parse(
      '${UserDeviceService.serverUrl}$path',
    ).replace(queryParameters: {'userDeviceId': _getUserDeviceId().toString()});
  }

  // 기기별 즐겨찾기 메뉴 목록 조회 : GET /api/favorites?userDeviceId=1
  Future<List<AllMenuScreenModel>> fetchFavorites() async {
    final response = await http
        .get(_buildUri())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('즐겨찾기 목록 조회 실패: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    return body
        .map(
          (item) => AllMenuScreenModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // 즐겨찾기 등록 : PUT /api/favorites/1?userDeviceId=1
  Future<void> addFavorite(int menuId) async {
    final response = await http
        .put(_buildUri(menuId: menuId))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 204) {
      throw Exception('즐겨찾기 등록 실패: HTTP ${response.statusCode}');
    }
  }

  // 즐겨찾기 해제 : DELETE /api/favorites/1?userDeviceId=1
  Future<void> removeFavorite(int menuId) async {
    final response = await http
        .delete(_buildUri(menuId: menuId))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 204) {
      throw Exception('즐겨찾기 해제 실패: HTTP ${response.statusCode}');
    }
  }
}
