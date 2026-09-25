import 'package:flutter/material.dart';
import 'filter_screen.dart';
import 'recipe_screen.dart';

class RecommendResultScreen extends StatefulWidget {
  final String category;
  final List<String> features;

  const RecommendResultScreen({
    super.key,
    this.category = '한식',
    this.features = const ['매운', '찌개'],
  });

  @override
  State<RecommendResultScreen> createState() => _RecommendResultScreenState();
}

class _RecommendResultScreenState extends State<RecommendResultScreen> {
  // 예시 데이터 리스트
  final List<Map<String, dynamic>> _sampleData = [
    {
      'name': '김치찌개',
      'tags': ['한식', '매운', '찌개'],
      'icon': Icons.soup_kitchen,
    },
    {
      'name': '부대찌개',
      'tags': ['한식', '고기', '찌개'],
      'icon': Icons.soup_kitchen,
    },
    {
      'name': '떡볶이',
      'tags': ['분식', '매운', '떡'],
      'icon': Icons.ramen_dining,
    },
  ];

  int _currentIndex = 0;

  // '다시 추천' 클릭 시 동작
  void _reRecommend() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _sampleData.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB45A30);
    final currentMenu = _sampleData[_currentIndex];

    // 선택된 태그 목록 (전달받은 태그 or 메뉴 태그)
    final displayTags = widget.features.isNotEmpty
        ? [widget.category, ...widget.features]
        : (currentMenu['tags'] as List<String>);

    return Scaffold(
      backgroundColor: Colors.white,
      // 상단 AppBar (홈/필터 화면과 디자인 통일)
      appBar: AppBar(
        title: const Text(
          '오늘의 추천',
          style: TextStyle(fontWeight: FontWeight.bold/*, color: Colors.white*/),
        ),
        //backgroundColor: const Color(0xFF2C3539),
        elevation: 0,
        //iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // 1. 상단 선택 조건 태그 칩들
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: displayTags
                      .where((tag) => tag != '전체')
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
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
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 2, 5. 메인 추천 음식 카드
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // 음식 이미지 상단 영역
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE7D2), // HomeScreen 이미지 배경색과 동일
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          child: Icon(
                            currentMenu['icon'] as IconData,
                            size: 100,
                            color: const Color(0xFFB45A30),
                          ),
                        ),
                      ),

                      // 음식 이름 및 상세 태그
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentMenu['name'] as String,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (currentMenu['tags'] as List<String>).join('  '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. 레시피 보기 버튼 -> RecipeScreen으로 이동
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeScreen(
                          menuName: currentMenu['name'] as String,
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

              // 4. 하단 버튼 2개 (다시 추천 / 조건 변경)
              Row(
                children: [
                  // 다시 추천
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

                  // 조건 변경 -> filter_screen.dart로 이동
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FilterScreen(),
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