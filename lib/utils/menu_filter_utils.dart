import '../models/menu_filter.dart';

class MenuFilterUtils {

  // ============================================================
  // 메뉴 필터링
  // ============================================================
  //
  // 카테고리 → AND
  // 음식 특징 → OR
  //
  // 예:
  //
  // 카테고리 = rice_bowl
  // 특징 = EASY, QUICK
  //
  // 결과:
  //
  // rice_bowl
  // AND
  // (EASY OR QUICK)
  //
  // ============================================================

  static List<MenuFilter> filterMenus({
    required List<MenuFilter> menus,
    required String? selectedCategoryId,
    required Set<String> selectedFeatureIds,
  }) {
    return menus.where((menu) {

      // --------------------------------------------------------
      // 1. 카테고리 필터
      // --------------------------------------------------------

      // 카테고리가 선택되어 있다면
      // 해당 카테고리만 남긴다.
      //
      // null이면 '전체'이므로 필터하지 않는다.

      if (selectedCategoryId != null &&
          menu.category != selectedCategoryId) {
        return false;
      }

      // --------------------------------------------------------
      // 2. 음식 특징 필터
      // --------------------------------------------------------

      // 음식 특징이 하나라도 선택되어 있다면
      // OR 조건으로 필터링한다.

      if (selectedFeatureIds.isNotEmpty) {

        // 현재 메뉴가 가지고 있는 태그 ID 목록
        final menuTagIds = menu.tags
            .map((tag) => tag.codeId)
            .toSet();

        // 선택한 특징 중 하나라도 가지고 있는지 확인
        final hasAnyFeature =
            selectedFeatureIds.any(
          (featureId) =>
              menuTagIds.contains(featureId),
        );

        // 선택한 특징을 하나도 가지고 있지 않다면 제외
        if (!hasAnyFeature) {
          return false;
        }
      }

      // 모든 조건 통과
      return true;
    }).toList();
  }
}