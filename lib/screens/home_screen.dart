import 'package:flutter/material.dart';

import 'all_menu_screen.dart';
import 'favorites_screen.dart';

// 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 실제 화면을 만들기 전까지 임시 화면으로 이동
  void moveTo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TemporaryScreen(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 화면 상단의 제목과 버튼 (앱 이름, 전체메뉴, 즐겨찾기)
      appBar: AppBar(
        title: const Text('집밥픽', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // 전체 메뉴 (돋보기)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '전체 메뉴 검색',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const AllMenuScreen(),
              ),
            ),
          ),
          // 즐겨찾기 (하트)
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: '즐겨찾기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const FavoritesScreen(),
              ),
            ),
          ),
        ],
      ),
      // 실제 화면 내용 (문구, 이미지 자리, 추천 버튼, 카테고리)
      body: SafeArea(
        // 화면 내용을 세로로 배치
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '오늘 뭐 먹지?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '고민은 짧게, 집밥은 맛있게',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 28),

            // 실제 음식 이미지는 추후 적용
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7D2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.ramen_dining,
                size: 110,
                color: Color(0xFFB45A30),
              ),
            ),

            // 오늘의 추천
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => moveTo(context, '오늘의 추천'),
                child: const Text('아무거나 추천'),
              ),
            ),
            // 조건 추천
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => moveTo(context, '조건 골라 추천'),
                child: const Text('조건 골라 추천'),
              ),
            ),

            // 카테고리
            const SizedBox(height: 30),
            const Text(
              '카테고리 바로가기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['한식', '중식', '일식', '분식'].map((category) {
                return ActionChip(
                  label: Text(category),
                  onPressed: () => moveTo(context, '$category 메뉴'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// 임시 화면
class TemporaryScreen extends StatelessWidget {
  const TemporaryScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title 화면 준비 중', style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
