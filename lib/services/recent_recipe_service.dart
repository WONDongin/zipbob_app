import 'dart:convert';

import '../models/all_menu_screen_model.dart';
import 'auth_service.dart';

class RecentRecipeService {
  final AuthService _auth;

  RecentRecipeService({AuthService? auth})
    : _auth = auth ?? AuthService.instance;

  // 현재 회원의 최근 조회 기록 저장·시간 갱신
  Future<void> recordView(int menuId) async {
    // 비회원의 레시피 조회는 허용하되 기록은 저장하지 않음
    if (!_auth.hasSession) {
      return;
    }

    final response = await _auth.authenticatedPut(
      '/api/recent-recipes/$menuId',
      {},
    );

    if (response.statusCode != 204) {
      throw const AuthException('최근 본 레시피를 기록하지 못했어요.');
    }
  }

  // 현재 회원의 최근 본 레시피 목록
  Future<List<AllMenuScreenModel>> fetchRecentRecipes() async {
    // 비회원은 개인 목록 API를 호출하지 않음
    if (!_auth.hasSession) {
      return [];
    }

    final response = await _auth.authenticatedGet('/api/recent-recipes');

    if (response.statusCode != 200) {
      throw const AuthException('최근 본 레시피를 불러오지 못했어요.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    return body
        .map(
          (item) => AllMenuScreenModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
