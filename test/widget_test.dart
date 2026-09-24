import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zipbob_app/main.dart';

void main() {
  testWidgets('홈에서 즐겨찾기 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(const ZipbobApp());

    expect(find.text('오늘 뭐 먹지?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.text('저장한 메뉴가 없어요'), findsOneWidget);
  });
}
