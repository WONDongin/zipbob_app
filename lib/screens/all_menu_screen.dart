import 'package:flutter/material.dart';

import 'recipe_screen.dart';

// 전체 메뉴 화면
class AllMenuScreen extends StatelessWidget {
  const AllMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 배치를 확인하기 위한 예시 메뉴
    // _SampleMenu 클래스는 화면 하단에 정의되어 있음
    const menus = [
      _SampleMenu('김치찌개', '한식 · 찌개', Icons.soup_kitchen),
      _SampleMenu('유부초밥', '일식 · 밥', Icons.rice_bowl),
      _SampleMenu('짜장면', '중식 · 면', Icons.ramen_dining),
      _SampleMenu('토마토 파스타', '양식 · 면', Icons.dinner_dining),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('전체 메뉴')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: '메뉴명을 검색하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(label: Text('전체')),
                  SizedBox(width: 8),
                  Chip(label: Text('한식')),
                  SizedBox(width: 8),
                  Chip(label: Text('중식')),
                  SizedBox(width: 8),
                  Chip(label: Text('일식')),
                  SizedBox(width: 8),
                  Chip(label: Text('양식')),
                  SizedBox(width: 8),
                  Chip(label: Text('분식')),
                ],
              ),
            ),

            // 전체 메뉴 음식 카드
            const SizedBox(height: 22),
            for (final menu in menus)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE7D2),
                    child: Icon(menu.icon, color: const Color(0xFFB45A30)),
                  ),
                  title: Text(menu.name),
                  subtitle: Text(menu.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => RecipeScreen(menuName: menu.name),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 예시 음식 음식의 이름·설명·아이콘 묶어 둔 클래스 (_ 이파일 안에서만 쓰는 클래스)
class _SampleMenu {
  const _SampleMenu(this.name, this.description, this.icon);

  final String name;
  final String description;
  final IconData icon;
}
