import 'dart:convert';

import '../models/all_menu_screen_model.dart';
import 'auth_service.dart';

class LikeService {
  final AuthService _auth;

  LikeService({AuthService? auth}) : _auth = auth ?? AuthService.instance;

  // 현재 로그인한 회원의 즐겨찾기 목록
  Future<List<AllMenuScreenModel>> fetchFavorites() async {
    // 비회원은 개인 목록 API를 호출하지 않음
    if (!_auth.hasSession) {
      return [];
    }

    final response = await _auth.authenticatedGet('/api/favorites');

    if (response.statusCode != 200) {
      throw const AuthException('즐겨찾기 목록을 불러오지 못했어요.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    return body
        .map(
          (item) => AllMenuScreenModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // 현재 회원의 즐겨찾기 등록
  Future<void> addFavorite(int menuId) async {
    final response = await _auth.authenticatedPut('/api/favorites/$menuId', {});

    if (response.statusCode != 204) {
      throw const AuthException('즐겨찾기를 저장하지 못했어요.');
    }
  }

  // 현재 회원의 즐겨찾기 해제
  Future<void> removeFavorite(int menuId) async {
    final response = await _auth.authenticatedDelete('/api/favorites/$menuId');

    if (response.statusCode != 204) {
      throw const AuthException('즐겨찾기를 해제하지 못했어요.');
    }
  }
}
