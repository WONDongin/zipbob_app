import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

//조건 넘겨서 메뉴리스트 받아오기
class RecommendService {
  static String get serverUrl => ApiConfig.baseUrl;

  Future<List<dynamic>> getRecommendations({
    required String? category,
    required List<String> tags,
  }) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/menufilter/recommend'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'category': category, 'tags': tags}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }

    throw Exception(
      '메뉴 추천 실패: ${response.statusCode}\n'
      '${utf8.decode(response.bodyBytes)}',
    );
  }
}
