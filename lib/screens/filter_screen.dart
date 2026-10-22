import 'package:flutter/material.dart';

import 'home_screen.dart'; //홈화면
import '../models/code.dart'; // 값 받아오기
import '../models/menu_filter.dart'; //메뉴 값 받아오기
import '../services/code_service.dart'; //카테고리, 음식특징 api
import '../services/menu_filter_service.dart'; //메뉴& 음식특징 리스트 api
import '../services/recommend_service.dart'; // 조건 api 넘기기
import '../utils/menu_filter_utils.dart'; //메뉴 필터링 로직
import '../widgets/filter_chip_button.dart'; //필터 버튼 UI

import 'recommend_result_screen.dart'; //추천메뉴결과

//조건골라 추천 화면
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // ============================================================
  // Service
  // ============================================================

  final CodeService _codeService = CodeService();

  final MenuFilterService _menuFilterService = MenuFilterService();

  // ============================================================
  // API 데이터
  // ============================================================

  // 카테고리 목록
  List<Code> categories = [];

  // 음식 특징 목록
  List<Code> features = [];

  // 전체 메뉴 목록
  List<MenuFilter> menus = [];

  // ============================================================
  // 선택된 조건
  // ============================================================

  // 선택된 카테고리
  //
  // null = 전체
  String? selectedCategoryId;

  // 선택된 음식 특징
  //
  // 여러 개 선택 가능
  //
  // 음식 특징은 OR 조건
  final Set<String> selectedFeatureIds = {};

  // 선택된 값 넘기기 위한 서비스, 로딩 셋팅
  final RecommendService _recommendService = RecommendService();

  bool isRequestingRecommendation = false;

  // ============================================================
  // 화면 상태
  // ============================================================

  bool isLoading = true;

  String? errorMessage;

  // ============================================================
  // 화면 최초 실행
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ============================================================
  // 데이터 조회
  // ============================================================

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 카테고리 조회
      final categoryCodes = await _codeService.getCategoryCodes();

      // 음식 특징 조회
      final tagCodes = await _codeService.getTagCodes();

      // 메뉴 + 태그 조회
      final menuList = await _menuFilterService.getMenuFilters();

      setState(() {
        categories = categoryCodes;

        features = tagCodes;

        menus = menuList;

        isLoading = false;

        errorMessage = null;
      });
    } catch (e) {
      print('필터 데이터 조회 실패: $e');

      setState(() {
        isLoading = false;

        errorMessage = '조건 정보를 불러오지 못했습니다.';
      });
    }
  }

  // ============================================================
  // 필터된 메뉴
  // ============================================================

  List<MenuFilter> get filteredMenus {
    return MenuFilterUtils.filterMenus(
      menus: menus,
      selectedCategoryId: selectedCategoryId,
      selectedFeatureIds: selectedFeatureIds,
    );
  }

  // ============================================================
  // 선택 초기화
  // ============================================================

  void _resetSelection() {
    setState(() {
      selectedCategoryId = null;

      selectedFeatureIds.clear();
    });
  }

  // ============================================================
  // 추천 결과 화면
  // ============================================================

  Future<void> _goToRecommendResult() async {
    if (isRequestingRecommendation) return;

    setState(() {
      isRequestingRecommendation = true;
    });

    try {
      // 1. 선택한 카테고리와 태그를 백엔드로 전송
      final result = await _recommendService.getRecommendations(
        category: selectedCategoryId,
        tags: selectedFeatureIds.toList(),
      );

      if (!mounted) return;

      // 백엔드에서 받은 추천 메뉴 확인
      debugPrint('추천 메뉴: $result');

      // 2. 추천 결과가 없는 경우
      if (result.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('선택한 조건에 맞는 메뉴가 없어요.')));
        return;
      }

      // 3. 백엔드 응답을 메뉴 Map 리스트로 변환
      final menus = result.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      // 4. 추천 결과 화면으로 이동하면서 메뉴 리스트 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendResultScreen(
            menus: menus,
            category: selectedCategoryId,
            features: features
                .where((feature) => selectedFeatureIds.contains(feature.codeId))
                .map((feature) => feature.codeName)
                .toList(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('추천 가능한 메뉴가 없어요.: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isRequestingRecommendation = false;
        });
      }
    }
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEF7544);
    const backgroundColor = Color(0xFFFFFAF5);
    const softOrangeColor = Color(0xFFFFEEE5);
    const borderColor = Color(0xFFF0E5DC);
    const titleColor = Color(0xFF222222);
    const bodyColor = Color(0xFF78716B);

    final sectionDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );

    final recommendationButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE7DFD8),
      disabledForegroundColor: bodyColor,
      elevation: 0,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // AppBar
      // ========================================================
      appBar: AppBar(
        leading: IconButton(
          //뒤로가기 홈으로 이동(이전페이지X) 26.10.17
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),

        title: const Text(
          '조건 골라 추천',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 17,
            letterSpacing: -0.5,
          ),
        ),

        centerTitle: true,

        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        backgroundColor: backgroundColor,

        foregroundColor: titleColor,
      ),

      // ========================================================
      // Body
      // ========================================================
      body: SafeArea(
        child: isLoading
            // --------------------------------------------------
            // 로딩
            // --------------------------------------------------
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 3,
                ),
              )
            // --------------------------------------------------
            // 에러
            // --------------------------------------------------
            : errorMessage != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: sectionDecoration,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: softOrangeColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            letterSpacing: -0.4,
                            color: bodyColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          //추천 버튼
                          onPressed:
                              filteredMenus.isEmpty ||
                                  isRequestingRecommendation
                              ? null
                              : _goToRecommendResult,
                          style: recommendationButtonStyle,
                          child: Text(
                            isRequestingRecommendation ? '추천 중...' : '추천하기',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // ------------------------------------------------
            // 정상
            // ------------------------------------------------
            : Column(
                children: [
                  // ==================================================
                  // 스크롤 영역
                  // ==================================================

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '나에게 맞는 한 끼',
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
                          const SizedBox(height: 18),

                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '오늘 먹고 싶은\n'),
                                TextSpan(
                                  text: '한 끼를 골라볼까요?',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                              letterSpacing: -1,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '원하는 카테고리와 음식 특징을 골라주세요.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.7,
                              letterSpacing: -0.4,
                              color: bodyColor,
                            ),
                          ),
                          const SizedBox(height: 26),

                          // ==================================================
                          // 카테고리
                          // ==================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: sectionDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: softOrangeColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 19,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        '카테고리',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '하나 선택',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: bodyColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                GridView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisExtent: 56,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),

                                  // 전체 + 카테고리
                                  itemCount: categories.length + 1,

                                  itemBuilder: (context, index) {
                                    // --------------------------------
                                    // 전체
                                    // --------------------------------

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

                                    // --------------------------------
                                    // 카테고리
                                    // --------------------------------

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
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==================================================
                          // 음식 특징
                          // ==================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: sectionDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: softOrangeColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.local_dining_rounded,
                                        size: 19,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        '음식 특징',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '여러 개 선택',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: bodyColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                GridView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisExtent: 56,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),

                                  itemCount: features.length,

                                  itemBuilder: (context, index) {
                                    final item = features[index];

                                    final isSelected = selectedFeatureIds
                                        .contains(item.codeId);

                                    return FilterChipButton(
                                      label: item.codeName,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedFeatureIds.remove(
                                              item.codeId,
                                            );
                                          } else {
                                            selectedFeatureIds.add(item.codeId);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),
                          const Center(
                            child: Text(
                              '고민은 짧게, 집밥은 맛있게',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.6,
                                letterSpacing: -0.4,
                                color: Color(0xFF99918B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // 하단 고정 영역
                  // ==================================================
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(top: BorderSide(color: borderColor)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x06000000),
                          offset: Offset(0, -6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // 추천 가능한 메뉴 개수
                        // ==================================================

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: softOrangeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '추천 가능한 메뉴 '
                            '${filteredMenus.length}개',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFAA512B),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ==================================================
                        // 추천하기
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: filteredMenus.isEmpty
                                ? null
                                : _goToRecommendResult,
                            style: recommendationButtonStyle,
                            child: const Text('이 조건으로 추천하기'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // 선택 초기화
                        // ==================================================
                        TextButton(
                          onPressed: _resetSelection,
                          style: TextButton.styleFrom(
                            foregroundColor: bodyColor,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '선택 초기화',
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 12,
                              letterSpacing: -0.4,
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
