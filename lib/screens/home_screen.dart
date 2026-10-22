import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../models/code.dart';
import '../services/all_menu_screen_service.dart';
import '../services/auth_service.dart';
import '../services/code_service.dart';
import '../services/like_service.dart';
import '../services/recent_recipe_service.dart';
import '../services/recommend_service.dart';
import '../widgets/member_login_card.dart';
import 'account_screen.dart';
import 'all_menu_screen.dart';
import 'favorites_screen.dart';
import 'filter_screen.dart';
import 'login_screen.dart';
import 'recipe_screen.dart';
import 'recommend_result_screen.dart';

// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary = Color(0xFFEF7544);
  static const Color _textColor = Color(0xFF222222);

  final TextEditingController _searchController = TextEditingController();

  final AuthService _auth = AuthService.instance;
  final CodeService _codeService = CodeService();
  final LikeService _likeService = LikeService();
  final RecentRecipeService _recentRecipeService = RecentRecipeService();
  final RecommendService _recommendService = RecommendService();

  late Future<List<Code>> _categoriesFuture;
  late Future<List<AllMenuScreenModel>> _favoritesFuture;
  late Future<List<AllMenuScreenModel>> _recentRecipesFuture;

  // 계정이 변경됐는지 구분하는 값.
  late int _sessionRevision;
  late bool _hadSession;

  String? _hoveredCategoryId;

  @override
  void initState() {
    super.initState();

    _sessionRevision = _auth.sessionRevision;
    _hadSession = _auth.hasSession;

    _categoriesFuture = _fetchCategories();
    _favoritesFuture = _fetchFavorites();
    _recentRecipesFuture = _fetchRecentRecipes();

    // 로그인·로그아웃·계정 변경 감지.
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _searchController.dispose();

    super.dispose();
  }

  // 로그인 상태가 바뀌면 개인 목록을 새로 조회한다.
  //
  // 닉네임 변경이나 토큰 갱신처럼 같은 로그인 세션에서 발생하는
  // 알림은 개인 목록 재조회 대상에서 제외한다.
  void _onAuthChanged() {
    final nextRevision = _auth.sessionRevision;
    final nextHasSession = _auth.hasSession;

    if (_sessionRevision == nextRevision && _hadSession == nextHasSession) {
      return;
    }

    _sessionRevision = nextRevision;
    _hadSession = nextHasSession;

    _refreshHomeMenus();
  }

  Future<List<Code>> _fetchCategories() {
    return _codeService.getCategoryCodes().timeout(const Duration(seconds: 15));
  }

  Future<List<AllMenuScreenModel>> _fetchFavorites() {
    // 비회원일 때 서비스에서 빈 목록을 반환한다.
    // 회원 전용 API 요청은 보내지 않는다.
    return _likeService.fetchFavorites();
  }

  Future<List<AllMenuScreenModel>> _fetchRecentRecipes() {
    return _recentRecipeService.fetchRecentRecipes();
  }

  void _retryCategories() {
    setState(() {
      _categoriesFuture = _fetchCategories();
    });
  }

  void _refreshFavorites() {
    if (!mounted) {
      return;
    }

    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }

  void _refreshRecentRecipes() {
    if (!mounted) {
      return;
    }

    setState(() {
      _recentRecipesFuture = _fetchRecentRecipes();
    });
  }

  void _refreshHomeMenus() {
    if (!mounted) {
      return;
    }

    setState(() {
      _favoritesFuture = _fetchFavorites();
      _recentRecipesFuture = _fetchRecentRecipes();
    });
  }

  // 상세 화면·즐겨찾기 화면 등에서 돌아오면 홈 목록을 갱신한다.
  Future<void> _openScreen(Widget screen) async {
    FocusScope.of(context).unfocus();

    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => screen));

    if (!mounted) {
      return;
    }

    _refreshHomeMenus();
  }

  void _openMenuSearch() {
    _openScreen(AllMenuScreen(initialKeyword: _searchController.text.trim()));
  }

  void _openCategory(String categoryId) {
    _openScreen(AllMenuScreen(initialCategory: categoryId));
  }

  void _openRecipe(AllMenuScreenModel menu) {
    _openScreen(RecipeScreen(menuId: menu.menuId, menuName: menu.menuName));
  }

  // 비회원은 로그인 안내, 회원은 즐겨찾기 화면으로 이동.
  void _openFavorites() {
    if (!_auth.hasSession) {
      showMemberLogin(context);
      return;
    }

    _openScreen(const FavoritesScreen());
  }

  Future<void> _openRandomRecommendation() async {
    FocusScope.of(context).unfocus();

    try {
      final response = await _recommendService.getRecommendations(
        category: null,
        tags: [],
      );

      if (!mounted) {
        return;
      }

      final menus = response
          .map((menu) => Map<String, dynamic>.from(menu as Map))
          .toList();

      if (menus.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('추천할 메뉴가 없어요.')));
        return;
      }

      await _openScreen(
        RecommendResultScreen(menus: menus, category: null, features: const []),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('랜덤 추천 오류: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메뉴 추천에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21, color: _primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildCategoryCard(Code category) {
    final isHovered = _hoveredCategoryId == category.codeId;

    return Material(
      color: isHovered ? _primary : Colors.white,
      animationDuration: const Duration(milliseconds: 150),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isHovered ? _primary : const Color(0xFFECE6E0)),
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
                      color: isHovered ? Colors.white : _primary,
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
                      color: isHovered ? Colors.white : _textColor,
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
                foregroundColor: _primary,
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
          // 계정 변경 시 기존 FutureBuilder의 목록을 재사용하지 않는다.
          key: ValueKey('favorites-$_sessionRevision-$_hadSession'),
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

            // 홈에서는 즐겨찾기 최대 3개 미리보기.
            return _buildHorizontalMenus(
              menus.take(3).toList(),
              showFavoriteBadge: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentRecipes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('최근 본 레시피', Icons.history_rounded),
        const SizedBox(height: 14),
        FutureBuilder<List<AllMenuScreenModel>>(
          key: ValueKey('recent-$_sessionRevision-$_hadSession'),
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

            // 백엔드의 최신순을 그대로 사용한다.
            return _buildHorizontalMenus(
              menus.take(5).toList(),
              showFavoriteBadge: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalMenus(
    List<AllMenuScreenModel> menus, {
    required bool showFavoriteBadge,
  }) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: menus.length,
        separatorBuilder: (_, index) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          return _buildMenuCard(
            menus[index],
            showFavoriteBadge: showFavoriteBadge,
          );
        },
      ),
    );
  }

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
          Icon(icon, size: 34, color: _primary),
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
                      color: _primary,
                    ),
                  ),
                ),
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

  Widget _buildMenuImage(String? imageUrl) {
    final resolvedUrl = AllMenuScreenService.resolveImageUrl(imageUrl);

    const placeholder = ColoredBox(
      color: Color(0xFFFFE7D2),
      child: Center(child: Icon(Icons.restaurant, size: 40, color: _primary)),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _openMenuSearch(),
      style: const TextStyle(
        fontSize: 15,
        letterSpacing: -0.5,
        color: _textColor,
      ),
      decoration: InputDecoration(
        hintText: '어떤 메뉴를 찾고 있나요?',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF858585)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: IconButton(
          tooltip: '전체 메뉴 검색',
          onPressed: _openMenuSearch,
          icon: const Icon(Icons.search, size: 26, color: Color(0xFF666666)),
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
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRecommendButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openRandomRecommendation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.casino_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아무거나 추천',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          '고민될 땐, 오늘의 한 끼를 골라드려요.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            letterSpacing: -0.4,
                            color: Color(0xFFFFEBDD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Color(0xFFFFEBDD),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF0E5DC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openScreen(const FilterScreen()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 28,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '조건 골라 추천',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          '먹고 싶은 종류와 특징으로 찾아보세요.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            letterSpacing: -0.4,
                            color: Color(0xFF78716B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: _primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: _primary,
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
            listenable: _auth,
            builder: (context, _) {
              final loggedIn = _auth.hasSession;

              return IconButton(
                tooltip: loggedIn ? '내 정보' : '로그인',
                onPressed: () {
                  _openScreen(
                    loggedIn ? const AccountScreen() : const LoginScreen(),
                  );
                },
                icon: Icon(
                  loggedIn
                      ? Icons.account_circle
                      : Icons.person_outline_rounded,
                  size: 27,
                  color: loggedIn ? _primary : _textColor,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: '즐겨찾기',
              onPressed: _openFavorites,
              icon: const Icon(
                Icons.favorite_border,
                size: 30,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '오늘 ',
                          style: TextStyle(color: _textColor),
                        ),
                        TextSpan(
                          text: '뭐 먹지?',
                          style: TextStyle(color: _primary),
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
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  _buildRecommendButtons(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('카테고리', Icons.grid_view_rounded),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(),
                  const SizedBox(height: 30),

                  // 개인 영역은 회원에게만 표시한다.
                  if (_auth.hasSession) ...[
                    _buildSavedMenus(),
                    const SizedBox(height: 30),
                    _buildRecentRecipes(),
                  ] else
                    const MemberLoginCard(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
}
