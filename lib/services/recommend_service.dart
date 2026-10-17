import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

//조건 넘겨서 메뉴리스트 받아오기
class RecommendService {
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  Future<List<dynamic>> getRecommendations({
    required String? category,
    required List<String> tags,
  }) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/menufilter/recommend'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'category': category,
        'tags': tags,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as List<dynamic>;
    }

    throw Exception(
      '메뉴 추천 실패: ${response.statusCode}\n'
      '${utf8.decode(response.bodyBytes)}',
    );
  }
}