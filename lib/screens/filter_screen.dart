import 'package:flutter/material.dart';

import '../models/code.dart';
import '../models/menu_filter.dart';
import '../services/code_service.dart';
import '../services/menu_filter_service.dart';
import '../services/recommend_service.dart';
import '../utils/menu_filter_utils.dart'; //메뉴 필터링 로직
import '../widgets/filter_chip_button.dart'; //필터 버튼 UI

import 'recommend_result_screen.dart'; //추천메뉴결과

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

  final MenuFilterService _menuFilterService =
      MenuFilterService();

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
      final categoryCodes =
          await _codeService.getCategoryCodes();

      // 음식 특징 조회
      final tagCodes =
          await _codeService.getTagCodes();

      // 메뉴 + 태그 조회
      final menuList =
          await _menuFilterService.getMenuFilters();

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

        errorMessage =
            '조건 정보를 불러오지 못했습니다.';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 조건에 맞는 메뉴가 없어요.'),
        ),
      );
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
          features: selectedFeatureIds.toList(),
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('추천 가능한 메뉴가 없어요.: $e'),
      ),
    );
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

    const primaryColor =
        Color(0xFFB45A30);

    return Scaffold(

      backgroundColor: Colors.white,

      // ========================================================
      // AppBar
      // ========================================================

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

        backgroundColor:
            Colors.white,

        foregroundColor:
            const Color(0xFF2C3539),
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
                child:
                    CircularProgressIndicator(),
              )

            // --------------------------------------------------
            // 에러
            // --------------------------------------------------

            : errorMessage != null

                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [

                        Text(
                          errorMessage!,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        ElevatedButton( //추천 버튼
                          onPressed: filteredMenus.isEmpty || isRequestingRecommendation
                            ? null
                            : _goToRecommendResult,
                          child: Text(
                            isRequestingRecommendation
                                ? '추천 중...'
                                : '추천하기',
                          ),
                        ),
                      ],
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
                        child:
                            SingleChildScrollView(

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              // ==================================================
                              // 카테고리
                              // ==================================================

                              const Text(
                                '카테고리',
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF2C3539,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              GridView.builder(

                                shrinkWrap:
                                    true,

                                physics:
                                    const NeverScrollableScrollPhysics(),

                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(

                                  crossAxisCount:
                                      4,

                                  childAspectRatio:
                                      1.8,

                                  crossAxisSpacing:
                                      8,

                                  mainAxisSpacing:
                                      8,
                                ),

                                // 전체 + 카테고리
                                itemCount:
                                    categories.length +
                                        1,

                                itemBuilder:
                                    (context, index) {

                                  // --------------------------------
                                  // 전체
                                  // --------------------------------

                                  if (index == 0) {

                                    final isSelected =
                                        selectedCategoryId ==
                                            null;

                                    return FilterChipButton(

                                      label:
                                          '전체',

                                      isSelected:
                                          isSelected,

                                      onTap: () {

                                        setState(() {

                                          selectedCategoryId =
                                              null;
                                        });
                                      },
                                    );
                                  }

                                  // --------------------------------
                                  // 카테고리
                                  // --------------------------------

                                  final item =
                                      categories[
                                          index - 1];

                                  final isSelected =
                                      selectedCategoryId ==
                                          item.codeId;

                                  return FilterChipButton(

                                    label:
                                        item.codeName,

                                    isSelected:
                                        isSelected,

                                    onTap: () {

                                      setState(() {

                                        selectedCategoryId =
                                            item.codeId;
                                      });
                                    },
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 32,
                              ),

                              // ==================================================
                              // 음식 특징
                              // ==================================================

                              const Text(
                                '음식 특징',
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF2C3539,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              GridView.builder(

                                shrinkWrap:
                                    true,

                                physics:
                                    const NeverScrollableScrollPhysics(),

                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(

                                  crossAxisCount:
                                      4,

                                  childAspectRatio:
                                      1.8,

                                  crossAxisSpacing:
                                      8,

                                  mainAxisSpacing:
                                      8,
                                ),

                                itemCount:
                                    features.length,

                                itemBuilder:
                                    (context, index) {

                                  final item =
                                      features[index];

                                  final isSelected =
                                      selectedFeatureIds
                                          .contains(
                                    item.codeId,
                                  );

                                  return FilterChipButton(

                                    label:
                                        item.codeName,

                                    isSelected:
                                        isSelected,

                                    onTap: () {

                                      setState(() {

                                        if (isSelected) {

                                          selectedFeatureIds
                                              .remove(
                                            item.codeId,
                                          );

                                        } else {

                                          selectedFeatureIds
                                              .add(
                                            item.codeId,
                                          );
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

                      // ==================================================
                      // 하단 고정 영역
                      // ==================================================

                      Container(

                        decoration:
                            BoxDecoration(

                          color:
                              Colors.white,

                          boxShadow: [

                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(
                                0.05,
                              ),
                              offset:
                                  const Offset(
                                0,
                                -3,
                              ),
                              blurRadius:
                                  6,
                            ),
                          ],
                        ),

                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child: Column(
                          children: [

                            // ==================================================
                            // 추천 가능한 메뉴 개수
                            // ==================================================

                            Text(
                              '추천 가능한 메뉴 '
                              '${filteredMenus.length}개',

                              style:
                                  const TextStyle(
                                fontSize: 15,
                                color:
                                    Colors.grey,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // ==================================================
                            // 추천하기
                            // ==================================================

                            SizedBox(

                              width:
                                  double.infinity,

                              height: 52,

                              child:
                                  ElevatedButton(

                                onPressed:
                                    filteredMenus
                                            .isEmpty
                                        ? null
                                        : _goToRecommendResult,

                                style:
                                    ElevatedButton
                                        .styleFrom(

                                  backgroundColor:
                                      primaryColor,

                                  disabledBackgroundColor:
                                      Colors.grey
                                          .shade300,

                                  elevation: 0,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                ),

                                child:
                                    const Text(
                                  '이 조건으로 추천하기',

                                  style:
                                      TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // ==================================================
                            // 선택 초기화
                            // ==================================================

                            TextButton(

                              onPressed:
                                  _resetSelection,

                              child:
                                  const Text(
                                '선택 초기화',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 14,
                                  decoration:
                                      TextDecoration
                                          .underline,
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