import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/code.dart';

class CodeService {

  static const String baseUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  Future<List<Code>> getCategoryCodes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/codes/category'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Code.fromJson(json))
          .toList();
    } else {
      throw Exception('카테고리 조회 실패');
    }
  }

  Future<List<Code>> getTagCodes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/codes/tag'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Code.fromJson(json))
          .toList();
    } else {
      throw Exception('음식 특징 조회 실패');
    }
  }
}