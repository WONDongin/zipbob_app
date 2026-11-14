import 'dart:convert';

import 'package:http/http.dart' as http; //pubspec.yaml에 http 패키지 추가 필요

import '../models/test_model.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/test';

  Future<List<TestModel>> fetchTestData() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => TestModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load test data');
    }
  }
}
