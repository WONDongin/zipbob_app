import 'dart:math';

import 'package:flutter/material.dart';

import 'filter_screen.dart';
import 'recipe_screen.dart';

class RecommendResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> menus;
  final String? category;
  final List<String> features;

  const RecommendResultScreen({
    super.key,
    required this.menus,
    this.category,
    this.features = const [],
  });

  @override
  State<RecommendResultScreen> createState() =>
      _RecommendResultScreenState();
}

class _RecommendResultScreenState
    extends State<RecommendResultScreen> {
  static const Color primaryColor = Color(0xFFB45A30);

  final Random _random = Random();

  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    // 화면에 처음 들어올 때 랜덤 메뉴 선택
    _currentIndex = _random.nextInt(widget.menus.length);
  }

  // 다시 추천: 현재 메뉴와 다른 메뉴를 우선 선택
  void _reRecommend() {
    if (widget.menus.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추천할 수 있는 메뉴가 하나뿐이에요.'),
        ),
      );
      return;
    }

    setState(() {
      int nextIndex;

      do {
        nextIndex = _random.nextInt(widget.menus.length);
      } while (nextIndex == _currentIndex);

      _currentIndex = nextIndex;
    });
  }

  // 현재 메뉴의 태그 이름 목록
  List<String> _getMenuTags(Map<String, dynamic> menu) {
    final rawTags = menu['tags'];

    if (rawTags is List) {
      return rawTags.map((tag) {
        // tags가 [{tagName: ...}] 형태인 경우
        if (tag is Map) {
          return tag['tagName']?.toString() ?? '';
        }

        // tags가 문자열 리스트인 경우도 처리
        return tag.toString();
      }).where((tag) => tag.isNotEmpty).toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    // 안전하게 빈 리스트 처리
    if (widget.menus.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('오늘의 추천')),
        body: const Center(
          child: Text('추천할 메뉴가 없습니다.'),
        ),
      );
    }

    final currentMenu = widget.menus[_currentIndex];

    final String menuName =
        currentMenu['menuName']?.toString() ?? '이름 없는 메뉴';

    final String categoryName =
        currentMenu['categoryName']?.toString() ?? '';

    final String description =
        currentMenu['description']?.toString() ?? '';

    final String? imageUrl =
        currentMenu['imageUrl']?.toString();

    final menuTags = _getMenuTags(currentMenu);

    // 화면 상단에 표시할 선택 조건
    final displayTags = <String>[
      if (categoryName.isNotEmpty) categoryName,
      ...widget.features,
    ].where((tag) => tag.isNotEmpty && tag != '전체').toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '오늘의 추천',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3539),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            children: [
              // 선택 조건 표시
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: displayTags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 추천 메뉴 카드
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 메뉴 이미지
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE7D2),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          child: imageUrl != null &&
                                  imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.restaurant,
                                        size: 100,
                                        color: primaryColor,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.restaurant,
                                  size: 100,
                                  color: primaryColor,
                                ),
                        ),
                      ),

                      // 메뉴 이름 및 설명
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menuName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            if (menuTags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                menuTags.join('  '),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 레시피 보기
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeScreen(
                          menuName: menuName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '레시피 보기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 다시 추천 / 조건 변경
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _reRecommend,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '다시 추천',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FilterScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '조건 변경',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}