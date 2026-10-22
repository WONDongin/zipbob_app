import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'filter_screen.dart';
import 'recipe_screen.dart';

// 추천 결과 화면
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
  State<RecommendResultScreen> createState() => _RecommendResultScreenState();
}

class _RecommendResultScreenState extends State<RecommendResultScreen> {
  static const Color primaryColor = Color(0xFFEF7544);

  // 화면 디자인 색상
  static const Color backgroundColor = Color(0xFFFFFAF5);
  static const Color softOrangeColor = Color(0xFFFFEEE5);
  static const Color borderColor = Color(0xFFF0E5DC);
  static const Color titleColor = Color(0xFF222222);
  static const Color bodyColor = Color(0xFF78716B);

  // 백엔드 서버 주소 — 기존 유지
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('추천할 수 있는 메뉴가 하나뿐이에요.')));
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
    if (path.startsWith('http://') || path.startsWith('https://')) {
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
      color: softOrangeColor,
      alignment: Alignment.center,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          size: 42,
          color: primaryColor,
        ),
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

  // 디자인 전용: 선택 조건 배지
  Widget _buildConditionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
          color: bodyColor,
        ),
      ),
    );
  }

  // 디자인 전용: 메뉴 특징 배지
  Widget _buildMenuTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: softOrangeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          height: 1.4,
          letterSpacing: -0.3,
          color: Color(0xFFAA512B),
        ),
      ),
    );
  }

  // 디자인 전용: 보조 버튼 공통 스타일
  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: bodyColor,
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      side: const BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 추천 메뉴가 없는 경우
    if (widget.menus.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            '오늘의 추천',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          foregroundColor: titleColor,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: softOrangeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 38,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '추천할 메뉴가 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentMenu = widget.menus[_currentIndex];

    final String menuName = currentMenu['menuName']?.toString() ?? '이름 없는 메뉴';

    final String categoryName = currentMenu['categoryName']?.toString() ?? '';

    final String description = currentMenu['description']?.toString() ?? '';

    final String? imageUrl = currentMenu['imageUrl']?.toString();

    debugPrint('선택 메뉴: $menuName');
    debugPrint('이미지 경로: $imageUrl');
    //debugPrint('최종 이미지 URL: ${_getImageUrl(imageUrl)}');

    final menuTags = _getMenuTags(currentMenu);

    // 화면 상단에 표시할 선택 조건 — 기존 유지
    final displayTags = <String>[
      if (categoryName.isNotEmpty) categoryName,
      ...widget.features,
    ].where((tag) => tag.isNotEmpty && tag != '전체').toSet().toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '오늘의 추천',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: titleColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 포인트 배지
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: softOrangeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '집밥PICK의 추천',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.4,
                          color: Color(0xFFAA512B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 상단 안내
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '오늘은 이 메뉴,\n'),
                    TextSpan(
                      text: '어떠세요?',
                      style: TextStyle(color: primaryColor),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -1,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '고민은 잠시 내려놓고, 맛있는 한 끼를 골라보세요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: bodyColor,
                ),
              ),

              // 기존 선택 조건을 배지 형태로 표시
              if (displayTags.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: displayTags
                      .map((tag) => _buildConditionChip(tag))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 추천 메뉴 카드
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 화면 폭에 맞춰 이미지 비율 유지
                      AspectRatio(
                        aspectRatio: 16 / 11,
                        child: _buildMenuImage(imageUrl),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  '오늘의 한 끼',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.4,
                                    color: Color(0xFFAA512B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Text(
                              menuName,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                letterSpacing: -0.8,
                                color: titleColor,
                              ),
                            ),

                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.8,
                                  letterSpacing: -0.4,
                                  color: bodyColor,
                                ),
                              ),
                            ],

                            if (menuTags.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: menuTags
                                    .map((tag) => _buildMenuTag(tag))
                                    .toList(),
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

              // 레시피 보기 — 기존 이동 코드 유지
              ElevatedButton(
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
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'GmarketSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 19),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('레시피 보기', textAlign: TextAlign.center),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 다시 추천 / 조건 변경
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reRecommend,
                      style: _secondaryButtonStyle(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text('다시 추천', textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FilterScreen(),
                          ),
                        );
                      },
                      style: _secondaryButtonStyle(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text('조건 변경', textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              const Text(
                '고민은 짧게, 집밥은 맛있게',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  letterSpacing: -0.4,
                  color: Color(0xFF99918B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
