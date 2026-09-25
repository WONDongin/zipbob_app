import 'package:flutter/material.dart';
import 'recommend_result_screen.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // 카테고리 항목 (단일 선택)
  final List<String> categories = ['전체', '한식', '중식', '일식', '양식', '분식', '아시안', '야식'];
  String selectedCategory = '한식';

  // 음식 특징 항목 (다중 선택)
  final List<String> features = ['매운', '고기', '면', '밥', '해물', '국', '찌개', '채식'];
  final Set<String> selectedFeatures = {'매운', '면'};

  void _resetSelection() {
    setState(() {
      selectedCategory = '전체';
      selectedFeatures.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 앱 전체의 공통 포인트 컬러
    const primaryColor = Color(0xFFB45A30);

    return Scaffold(
      backgroundColor: Colors.white,
      // AllMenuScreen, RecommendResultScreen과 일치하는 상단 AppBar
      appBar: AppBar(
        title: const Text(
          '조건 골라 추천',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            //color: Colors.white,
            fontSize: 20,
          ),
        ),
       // backgroundColor: const Color(0xFF2C3539),
        centerTitle: false,
        elevation: 0,
        //iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 섹션 타이틀 1
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3539),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final item = categories[index];
                        final isSelected = selectedCategory == item;
                        return FilterChipButton(
                          label: item,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedCategory = item;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 섹션 타이틀 2
                    const Text(
                      '음식 특징',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3539),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        final item = features[index];
                        final isSelected = selectedFeatures.contains(item);
                        return FilterChipButton(
                          label: item,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedFeatures.remove(item);
                              } else {
                                selectedFeatures.add(item);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 하단 고정 영역
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    '추천 가능한 메뉴 12개',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 이 조건으로 추천하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecommendResultScreen(
                              category: selectedCategory,
                              features: selectedFeatures.toList(),
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
                        '이 조건으로 추천하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 선택 초기화 버튼
                  TextButton(
                    onPressed: _resetSelection,
                    child: const Text(
                      '선택 초기화',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB45A30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF2C3539),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}