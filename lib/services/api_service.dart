import 'dart:convert';

import 'package:http/http.dart' as http; //pubspec.yaml에 http 패키지 추가 필요

import '../models/test_model.dart';

class ApiService {
  // Android 에뮬레이터 기준 Spring Boot PC 주소 (필요 시 수정)[cite: 1]
  // 1. Android 에뮬레이터를 띄워서 앱을 테스트할 때
  static const String baseUrl = 'http://10.0.2.2:8080/api/test';

  // 2. Chrome 브라우저나 flutter test(단위 테스트)로 실행할 때 터미널
  // static const String baseUrl = 'http://localhost:8080/api/test';

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
