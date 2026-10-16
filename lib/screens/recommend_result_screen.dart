import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
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

  // 백엔드 서버 주소
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  final Random _random = Random();

  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    // 추천 메뉴가 있을 때만 랜덤으로 메뉴 선택
    _currentIndex = widget.menus.isEmpty
        ? 0
        : _random.nextInt(widget.menus.length);
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
      return rawTags
          .map((tag) {
            // tags가 [{tagName: ...}] 형태인 경우
            if (tag is Map) {
              return tag['tagName']?.toString() ?? '';
            }

            // tags가 문자열 리스트인 경우
            return tag.toString();
          })
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    return [];
  }

  // 이미지 주소 만들기
  String? _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final path = imagePath.trim();

    // 이미 전체 주소라면 그대로 사용
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    // 상대 경로 앞에 백엔드 주소 추가
    return '$serverUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  // 이미지가 없거나 로딩에 실패했을 때 표시할 화면
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFFE7D2),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant,
        size: 100,
        color: primaryColor,
      ),
    );
  }

  // 메뉴 이미지 표시
  Widget _buildMenuImage(String? imagePath) {
    final imageUrl = _getImageUrl(imagePath);

    // 이미지 주소가 없으면 기본 아이콘 표시
    if (imageUrl == null) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,

      // 이미지 요청에 실패해도 기존 화면 유지
      errorBuilder: (context, error, stackTrace) {
        debugPrint('메뉴 이미지 로딩 실패: $imageUrl');
        debugPrint('오류 내용: $error');

        return _buildImagePlaceholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 추천 메뉴가 없는 경우
    if (widget.menus.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('오늘의 추천'),
        ),
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
        debugPrint('선택 메뉴: $menuName');
        debugPrint('이미지 경로: $imageUrl');
        //debugPrint('최종 이미지 URL: ${_getImageUrl(imageUrl)}');

    final menuTags = _getMenuTags(currentMenu);

    // 화면 상단에 표시할 선택 조건
    final displayTags = <String>[
      if (categoryName.isNotEmpty) categoryName,
      ...widget.features,
    ]
        .where((tag) => tag.isNotEmpty && tag != '전체')
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          '오늘의 추천',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: _buildMenuImage(imageUrl),
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
                          menuId: currentMenu['menuId'] as int,
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
                          side: const BorderSide(
                            color: primaryColor,
                          ),
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
                          side: const BorderSide(
                            color: primaryColor,
                          ),
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
