import 'package:flutter/material.dart';
import '../models/code.dart';
import '../services/code_service.dart';
import 'recommend_result_screen.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // API 호출을 담당하는 Service
  final CodeService _codeService = CodeService();

  // API에서 받아올 카테고리 목록
  List<Code> categories = [];

  // API에서 받아올 음식 특징 목록
  List<Code> features = [];

  // 선택된 카테고리 ID
  // null이면 '전체'로 처리
  String? selectedCategoryId;

  // 선택된 음식 특징 ID들
  final Set<String> selectedFeatureIds = {};

  // API 조회 중인지 여부
  bool isLoading = true;

  // API 조회 실패 여부
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // 화면이 처음 만들어질 때 코드 조회
    _loadCodes();
  }

  // 카테고리 + 음식 특징 조회
  Future<void> _loadCodes() async {
    try {
      final categoryCodes = await _codeService.getCategoryCodes();
      final tagCodes = await _codeService.getTagCodes();

      setState(() {
        categories = categoryCodes;
        features = tagCodes;

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      print('코드 조회 실패: $e');

      setState(() {
        isLoading = false;
        errorMessage = '조건 정보를 불러오지 못했습니다.';
      });
    }
  }

  // 선택 초기화
  void _resetSelection() {
    setState(() {
      selectedCategoryId = null;
      selectedFeatureIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 앱 전체의 공통 포인트 컬러
    const primaryColor = Color(0xFFB45A30);

    return Scaffold(
      backgroundColor: Colors.white,

      // 상단 AppBar
      appBar: AppBar(
        title: const Text(
          '조건 골라 추천',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCodes,
                          child: const Text('다시 불러오기'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // ----------------------------------------
                      // 가운데 스크롤 영역
                      // ----------------------------------------
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ----------------------------------------
                              // 카테고리
                              // ----------------------------------------
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
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),

                                // '전체' 1개를 추가하기 때문에 + 1
                                itemCount: categories.length + 1,

                                itemBuilder: (context, index) {
                                  // 첫 번째는 '전체'
                                  if (index == 0) {
                                    final isSelected =
                                        selectedCategoryId == null;

                                    return FilterChipButton(
                                      label: '전체',
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryId = null;
                                        });
                                      },
                                    );
                                  }

                                  // 실제 API에서 가져온 카테고리
                                  final item = categories[index - 1];

                                  final isSelected =
                                      selectedCategoryId == item.codeId;

                                  return FilterChipButton(
                                    label: item.codeName,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        selectedCategoryId = item.codeId;
                                      });
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 32),

                              // ----------------------------------------
                              // 음식 특징
                              // ----------------------------------------
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
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: features.length,
                                itemBuilder: (context, index) {
                                  final item = features[index];

                                  final isSelected =
                                      selectedFeatureIds.contains(item.codeId);

                                  return FilterChipButton(
                                    label: item.codeName,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedFeatureIds
                                              .remove(item.codeId);
                                        } else {
                                          selectedFeatureIds
                                              .add(item.codeId);
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

                      // ----------------------------------------
                      // 하단 고정 영역
                      // ----------------------------------------
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

                            // ----------------------------------------
                            // 추천하기 버튼
                            // ----------------------------------------
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RecommendResultScreen(
                                        // 선택된 카테고리 ID
                                        category: selectedCategoryId,

                                        // 선택된 특징 ID 목록
                                        features:
                                            selectedFeatureIds.toList(),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
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

                            // ----------------------------------------
                            // 선택 초기화
                            // ----------------------------------------
                            TextButton(
                              onPressed: _resetSelection,
                              child: const Text(
                                '선택 초기화',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  decoration:
                                      TextDecoration.underline,
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


// ============================================================
// 필터 버튼 위젯
// ============================================================

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
            color: isSelected
                ? primaryColor
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF2C3539),
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}