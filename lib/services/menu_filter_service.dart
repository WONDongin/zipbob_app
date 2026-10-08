import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/menu_filter.dart';

class MenuFilterService {

  // 웹: localhost
  // Android Emulator: 10.0.2.2
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  // 메뉴 + 태그 전체 조회
  Future<List<MenuFilter>> getMenuFilters() async {

    final response = await http.get(
      Uri.parse('$serverUrl/api/menufilter'),
    );

    if (response.statusCode == 200) {

      final List<dynamic> jsonList =
          jsonDecode(
            utf8.decode(response.bodyBytes),
          );

      return jsonList
          .map(
            (json) => MenuFilter.fromJson(json),
          )
          .toList();

    } else {
      throw Exception(
        '메뉴 조회 실패: ${response.statusCode}',
      );
    }
  }
}