import 'package:flutter/material.dart';

import '../models/code.dart';
import '../models/all_menu_screen_model.dart';
import '../services/code_service.dart';
import '../services/all_menu_screen_service.dart';
import '../services/like_service.dart';
import '../services/recent_recipe_service.dart';
import '../services/auth_service.dart';
import '../services/recommend_service.dart'; // 조건 api 넘기기 작성자:sun - 26.10.17
import 'recommend_result_screen.dart'; //아무거나 추천 결과 페이지 - 26.10.17 sun
import 'login_screen.dart';
import 'account_screen.dart';
import 'all_menu_screen.dart';
import 'favorites_screen.dart';
import 'filter_screen.dart';
import 'recipe_screen.dart';
import 'signup_screen.dart';

// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CodeService _codeService = CodeService();
  final LikeService _likeService = LikeService();
  final RecentRecipeService _recentRecipeService = RecentRecipeService();
  // 선택된 값 넘기기 위한 서비스, 로딩 셋팅 - 26.10.17 sun
  final RecommendService _recommendService = RecommendService();

  late Future<List<Code>> _categoriesFuture;
  late Future<List<AllMenuScreenModel>> _favoritesFuture;
  late Future<List<AllMenuScreenModel>> _recentRecipesFuture;

  // 마우스가 올라간 카테고리 코드
  String? _hoveredCategoryId;

  @override
  void initState() {
    super.initState();

    // 홈 최초 진입 시 각 목록 조회
    _categoriesFuture = _fetchCategories();
    _favoritesFuture = _fetchFavorites();
    _recentRecipesFuture = _fetchRecentRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 기존 공통코드 API 재사용
  Future<List<Code>> _fetchCategories() {
    return _codeService.getCategoryCodes().timeout(const Duration(seconds: 15));
  }

  // 카테고리 조회 실패 시 재시도
  void _retryCategories() {
    setState(() {
      _categoriesFuture = _fetchCategories();
    });
  }

  // 기존 즐겨찾기 API 재사용
  Future<List<AllMenuScreenModel>> _fetchFavorites() {
    return _likeService.fetchFavorites();
  }

  // 최근 본 레시피 조회
  Future<List<AllMenuScreenModel>> _fetchRecentRecipes() {
    return _recentRecipeService.fetchRecentRecipes();
  }

  // 저장한 메뉴만 새로고침
  void _refreshFavorites() {
    if (!mounted) {
      return;
    }

    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }

  // 최근 본 레시피만 새로고침
  void _refreshRecentRecipes() {
    if (!mounted) {
      return;
    }

    setState(() {
      _recentRecipesFuture = _fetchRecentRecipes();
    });
  }

  // 홈으로 돌아왔을 때 두 목록 새로고침
  void _refreshHomeMenus() {
    if (!mounted) {
      return;
    }

    setState(() {
      _favoritesFuture = _fetchFavorites();
      _recentRecipesFuture = _fetchRecentRecipes();
    });
  }

  // 이동한 화면에서 돌아오면 홈 목록 갱신
  Future<void> _openScreen(Widget screen) async {
    FocusScope.of(context).unfocus();

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );

    if (!mounted) {
      return;
    }

    _refreshHomeMenus();
  }

  // 검색어를 전체 메뉴 화면에 전달
  void _openMenuSearch() {
    _openScreen(AllMenuScreen(initialKeyword: _searchController.text.trim()));
  }

  // 전체 메뉴 중에서 랜덤 추천 - 26.10.174 sun
  Future<void> _openRandomRecommendation() async {
    FocusScope.of(context).unfocus();

    try {
      // 서버에서 전체 메뉴 추천 목록 조회
      final response = await _recommendService.getRecommendations(
        category: null,
        tags: [],
      );

      // 서버 응답 확인
      debugPrint('===== 전체 메뉴 추천 API 응답 =====');
      debugPrint('응답 메뉴 개수: ${response.length}');

      for (final menu in response) {
        debugPrint('메뉴 데이터: $menu');
      }

      debugPrint('===== 응답 확인 끝 =====');

      if (!mounted) return;

      // List<dynamic>을 List<Map<String, dynamic>>으로 변환
      final List<Map<String, dynamic>> menus = response
          .map((menu) => Map<String, dynamic>.from(menu as Map))
          .toList();

      if (menus.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('추천할 메뉴가 없어요.')));
        return;
      }

      // 추천 결과 화면으로 이동
      await _openScreen(
        RecommendResultScreen(menus: menus, category: null, features: const []),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('랜덤 추천 오류: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴 추천에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  } //아무거나 추천 end

  // 선택한 카테고리로 전체 메뉴 화면 이동
  void _openCategory(String categoryId) {
    _openScreen(AllMenuScreen(initialCategory: categoryId));
  }

  // 즐겨찾기 화면 이동
  void _openFavorites() {
    _openScreen(const FavoritesScreen());
  }

  // 저장한 메뉴·최근 본 레시피의 상세 화면 이동
  void _openRecipe(AllMenuScreenModel menu) {
    _openScreen(RecipeScreen(menuId: menu.menuId, menuName: menu.menuName));
  }

  // 실제 화면을 만들기 전까지 임시 화면으로 이동
  void moveTo(BuildContext context, String title) {
    _openScreen(TemporaryScreen(title: title));
  }

  // 주황색 아이콘이 있는 영역 제목
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFFEF7544)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              color: Color(0xFF222222),
            ),
          ),
        ),
      ],
    );
  }

  // 카테고리 아이콘 그리드
  Widget _buildCategoryGrid() {
    return FutureBuilder<List<Code>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Text('카테고리를 불러오지 못했어요.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _retryCategories,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('등록된 카테고리가 없어요.'),
          );
        }

        return GridView.builder(
          // 홈 ListView가 세로 스크롤을 담당
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 115,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        );
      },
    );
  }

  // 카테고리 카드
  Widget _buildCategoryCard(Code category) {
    final isHovered = _hoveredCategoryId == category.codeId;

    return Material(
      color: isHovered ? const Color(0xFFEF7544) : Colors.white,
      animationDuration: const Duration(milliseconds: 150),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isHovered ? const Color(0xFFEF7544) : const Color(0xFFECE6E0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCategory(category.codeId),
        onHover: (hovering) {
          setState(() {
            if (hovering) {
              _hoveredCategoryId = category.codeId;
            } else if (_hoveredCategoryId == category.codeId) {
              _hoveredCategoryId = null;
            }
          });
        },
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            children: [
              Image.asset(
                'assets/images/categories/${category.codeId}_icon.png',
                width: 52,
                height: 52,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.restaurant,
                      size: 32,
                      color: isHovered ? Colors.white : const Color(0xFFEF7544),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Text(
                    category.codeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHovered ? Colors.white : const Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 저장한 메뉴 영역
  Widget _buildSavedMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('내가 저장한 메뉴', Icons.favorite_rounded),
            ),
            TextButton(
              onPressed: _openFavorites,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF7544),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '전체 보기',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AllMenuScreenModel>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildListError(
                message: '저장한 메뉴를 불러오지 못했어요.',
                onRetry: _refreshFavorites,
              );
            }

            final menus = snapshot.data ?? [];

            if (menus.isEmpty) {
              return _buildEmptyMenuList(
                icon: Icons.favorite_border,
                title: '아직 저장한 메뉴가 없어요.',
                description: '마음에 드는 메뉴의 하트를 눌러보세요.',
              );
            }

            // API 응답 순서대로 최대 3개 표시
            final previewMenus = menus.take(3).toList();

            return SizedBox(
              height: 190,
              child: ListView.separated(
                key: const PageStorageKey<String>('savedMenus'),
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: previewMenus.length,
                separatorBuilder: (_, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  return _buildMenuCard(
                    previewMenus[index],
                    showFavoriteBadge: true,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // 최근 본 레시피 영역: 전체 보기 버튼 없음
  Widget _buildRecentRecipes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('최근 본 레시피', Icons.history_rounded),
        const SizedBox(height: 14),
        FutureBuilder<List<AllMenuScreenModel>>(
          future: _recentRecipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildListError(
                message: '최근 본 레시피를 불러오지 못했어요.',
                onRetry: _refreshRecentRecipes,
              );
            }

            final menus = snapshot.data ?? [];

            if (menus.isEmpty) {
              return _buildEmptyMenuList(
                icon: Icons.history,
                title: '아직 본 레시피가 없어요.',
                description: '궁금한 메뉴의 레시피를 확인해 보세요.',
              );
            }

            // 서버가 반환한 최신순을 유지하며 최대 5개 표시
            final recentMenus = menus.take(5).toList();

            return SizedBox(
              height: 190,
              child: ListView.separated(
                key: const PageStorageKey<String>('recentRecipes'),
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: recentMenus.length,
                separatorBuilder: (_, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  return _buildMenuCard(
                    recentMenus[index],
                    showFavoriteBadge: false,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // 목록 조회 실패 안내
  Widget _buildListError({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE6E0)),
      ),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  // 기록이 없는 경우 안내
  Widget _buildEmptyMenuList({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE6E0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFFEF7544)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _openScreen(const AllMenuScreen()),
            child: const Text('전체 메뉴 둘러보기'),
          ),
        ],
      ),
    );
  }

  // 저장한 메뉴·최근 본 레시피 공통 카드
  Widget _buildMenuCard(
    AllMenuScreenModel menu, {
    required bool showFavoriteBadge,
  }) {
    return SizedBox(
      width: 145,
      child: Material(
        color: const Color(0xFFFFEEE5),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openRecipe(menu),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMenuImage(menu.imageUrl),

              // 메뉴명이 잘 보이도록 하단 그라데이션
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 저장한 메뉴에만 즐겨찾기 표시
              if (showFavoriteBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 19,
                      color: Color(0xFFEF7544),
                    ),
                  ),
                ),

              // 메뉴명
              Positioned(
                left: 10,
                right: 10,
                bottom: 14,
                child: Text(
                  menu.menuName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1.4,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 카드 이미지
  Widget _buildMenuImage(String? imageUrl) {
    final resolvedUrl = AllMenuScreenService.resolveImageUrl(imageUrl);

    const placeholder = ColoredBox(
      color: Color(0xFFFFE7D2),
      child: Center(
        child: Icon(Icons.restaurant, size: 40, color: Color(0xFFEF7544)),
      ),
    );

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return placeholder;
    }

    return Image.network(
      resolvedUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const ColoredBox(
          color: Color(0xFFFFEEE5),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFEF7544),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  // 홈 화면의 끝을 알려주는 푸터
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: const Color(0xFFEF7544),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, size: 22, color: Colors.white),
              SizedBox(width: 6),
              Text(
                '집밥PICK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '고민은 짧게, 집밥은 맛있게',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            '오늘도 맛있는 한 끼 챙기세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFFFFE5D8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 왼쪽 로고, 오른쪽 즐겨찾기
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 76,
        backgroundColor: const Color(0xFFFFFAF5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Image.asset(
          'assets/images/logo/zipbob_pick_logo.png',
          width: 160,
          height: 48,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          semanticLabel: '집밥PICK',
        ),
        actions: [
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              final loggedIn = AuthService.instance.hasSession;

              return IconButton(
                tooltip: loggedIn ? '내 정보' : '로그인',
                onPressed: () => _openScreen(
                  loggedIn ? const AccountScreen() : const LoginScreen(),
                ),
                icon: Icon(
                  loggedIn
                      ? Icons.account_circle
                      : Icons.person_outline_rounded,
                  size: 27,
                  color: loggedIn
                      ? const Color(0xFFEF7544)
                      : const Color(0xFF222222),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.favorite_border,
                size: 30,
                color: Color(0xFF222222),
              ),
              tooltip: '즐겨찾기',
              onPressed: _openFavorites,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          // 푸터가 앱 화면 양옆까지 채워지도록 전체 패딩 제거
          padding: EdgeInsets.zero,
          children: [
            // 본문에만 여백 적용
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 메인 문구
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '오늘 ',
                          style: TextStyle(color: Color(0xFF222222)),
                        ),
                        TextSpan(
                          text: '뭐 먹지?',
                          style: TextStyle(color: Color(0xFFEF7544)),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 40,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '고민은 짧게, 집밥은 맛있게',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 키보드 검색 또는 돋보기 클릭으로 검색
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _openMenuSearch(),
                    style: const TextStyle(
                      fontSize: 15,
                      letterSpacing: -0.5,
                      color: Color(0xFF222222),
                    ),
                    decoration: InputDecoration(
                      hintText: '어떤 메뉴를 찾고 있나요?',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF858585),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: IconButton(
                        tooltip: '전체 메뉴 검색',
                        onPressed: _openMenuSearch,
                        icon: const Icon(
                          Icons.search,
                          size: 26,
                          color: Color(0xFF666666),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DEDA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2DEDA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF7544),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // 추천 버튼
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FilledButton(
                          //오늘의 추천
                          onPressed: _openRandomRecommendation,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEF7544),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.casino, size: 26),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '아무거나 추천',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openScreen(const FilterScreen()),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEEE5),
                            foregroundColor: const Color(0xFFEF7544),
                            side: const BorderSide(
                              color: Color(0xFFEF7544),
                              width: 1.2,
                            ),
                            minimumSize: const Size(0, 70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tune, size: 26),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '조건 골라 추천',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 카테고리 아이콘 그리드
                  const SizedBox(height: 30),
                  _buildSectionTitle('카테고리', Icons.grid_view_rounded),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(),

                  // 저장한 메뉴 미리보기
                  const SizedBox(height: 30),
                  _buildSavedMenus(),

                  // 최근 본 레시피
                  const SizedBox(height: 30),
                  _buildRecentRecipes(),
                ],
              ),
            ),

            // 본문 아래에 주황색 푸터 표시
            _buildFooter(),
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
