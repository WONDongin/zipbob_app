import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/code.dart';
import '../config/api_config.dart';

//카테고리, 음식특징 api
class CodeService {
  static String get serverUrl => ApiConfig.baseUrl;

  Future<List<Code>> getCategoryCodes() async {
    final response = await http.get(Uri.parse('$serverUrl/api/codes/category'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => Code.fromJson(json)).toList();
    } else {
      throw Exception('카테고리 조회 실패');
    }
  }

  Future<List<Code>> getTagCodes() async {
    final response = await http.get(Uri.parse('$serverUrl/api/codes/tag'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => Code.fromJson(json)).toList();
    } else {
      throw Exception('음식 특징 조회 실패');
    }
  }
}
