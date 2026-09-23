import 'package:flutter_test/flutter_test.dart';
import 'package:zipbob_app/services/api_service.dart';

void main() {
  test('Spring Boot DB 연동 및 col1, col2, col3 Select 테스트', () async {
    final apiService = ApiService();

    // Spring Boot 서버로 요청 전송
    final result = await apiService.fetchTestData();

    // 검증 (데이터가 비어있지 않은지)
    expect(result.isNotEmpty, true);

    // 데이터 잘 출력되는지 콘솔로 확인
    print('--- DB Select 결과 ---');
    print('col1: ${result[0].col1}');
    print('col2: ${result[0].col2}');
    print('col3: ${result[0].col3}');
  });
}