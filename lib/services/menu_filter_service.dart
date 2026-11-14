import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/menu_filter.dart';
import '../config/api_config.dart';

//메뉴+음식특징 전체 api
class MenuFilterService {
  static String get serverUrl => ApiConfig.baseUrl;
  // 메뉴 + 태그 전체 조회
  Future<List<MenuFilter>> getMenuFilters() async {
    final response = await http.get(Uri.parse('$serverUrl/api/menufilter'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      return jsonList.map((json) => MenuFilter.fromJson(json)).toList();
    } else {
      throw Exception('메뉴 조회 실패: ${response.statusCode}');
    }
  }
}
