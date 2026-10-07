import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/all_menu_screen_model.dart';

class AllMenuScreenService {
  // Chrome: localhost
  // Android 에뮬레이터: 개발 PC에 접근하는 주소
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  Future<List<AllMenuScreenModel>> fetchMenus({
    String keyword = '',
    String category = '',
  }) async {
    final searchKeyword = keyword.trim();
    final searchCategory = category.trim();

    // 검색 조건이 있을 때만 파라미터 추가
    final queryParameters = <String, String>{
      if (searchKeyword.isNotEmpty) 'keyword': searchKeyword,
      if (searchCategory.isNotEmpty) 'category': searchCategory,
    };

    final uri = Uri.parse('$serverUrl/api/menus').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('메뉴 목록 조회 실패: HTTP ${response.statusCode}');
    }

    // 한글을 UTF-8로 디코딩하고 JSON 배열로 변환
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    // JSON 배열의 각 항목을 메뉴 모델로 변환
    return body
        .map(
          (item) => AllMenuScreenModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // 이미지 상대 경로를 서버 주소가 포함된 URL로 변환
  static String? resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    return Uri.parse('$serverUrl/').resolve(imagePath.trim()).toString();
  }
}
