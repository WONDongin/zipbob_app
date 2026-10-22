import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../models/code.dart';
import '../services/all_menu_screen_service.dart';
import '../services/auth_service.dart';
import '../services/code_service.dart';
import '../services/like_service.dart';
import '../widgets/member_login_card.dart';
import 'recipe_screen.dart';

// 전체 메뉴 화면
class AllMenuScreen extends StatefulWidget {
  const AllMenuScreen({
    super.key,
    this.initialKeyword = '',
    this.initialCategory = '',
  });

  final String initialKeyword;
  final String initialCategory;

  @override
  State<AllMenuScreen> createState() => _AllMenuScreenState();
}

class _AllMenuScreenState extends State<AllMenuScreen> {
  static const Color _primary = Color(0xFFEF7544);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _softOrange = Color(0xFFFFEEE5);
  static const Color _border = Color(0xFFF0E5DC);
  static const Color _titleColor = Color(0xFF222222);
  static const Color _bodyColor = Color(0xFF78716B);

  final AuthService _auth = AuthService.instance;
  final AllMenuScreenService _menuService = AllMenuScreenService();
  final CodeService _codeService = CodeService();
  final LikeService _likeService = LikeService();

  final TextEditingController _searchController = TextEditingController();

  late Future<List<Code>> _categoriesFuture;
  late Future<List<AllMenuScreenModel>> _menusFuture;

  // 빈 문자열이면 전체 카테고리.
  String _selectedCategory = '';

  // 현재 로그인 계정이 저장한 메뉴 ID.
  final Set<int> _favoriteMenuIds = {};

  // 등록·해제 요청 중인 메뉴 ID.
  final Set<int> _updatingMenuIds = {};

  // 현재 계정의 즐겨찾기를 정상적으로 조회했는지 여부.
  bool _favoritesLoaded = false;

  // 즐겨찾기 조회 실패 안내용.
  bool _favoritesFailed = false;

  late int _sessionRevision;
  late bool _hadSession;

  // 이전 조회 응답이 최신 화면 상태를 덮어쓰지 않도록 구분.
  int _loadRevision = 0;

  @override
  void initState() {
    super.initState();

    _sessionRevision = _auth.sessionRevision;
    _hadSession = _auth.hasSession;

    _searchController.text = widget.initialKeyword.trim();
    _selectedCategory = widget.initialCategory;

    _categoriesFuture = _fetchCategories();
    _menusFuture = _fetchMenus();

    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _searchController.dispose();

    super.dispose();
  }

  // 로그인·로그아웃·계정 변경 시 개인 상태 초기화.
  void _onAuthChanged() {
    final nextRevision = _auth.sessionRevision;
    final nextHasSession = _auth.hasSession;

    if (_sessionRevision == nextRevision && _hadSession == nextHasSession) {
      return;
    }

    _sessionRevision = nextRevision;
    _hadSession = nextHasSession;

    if (!mounted) {
      return;
    }

    setState(() {
      _favoriteMenuIds.clear();
      _updatingMenuIds.clear();

      _favoritesLoaded = false;
      _favoritesFailed = false;

      _menusFuture = _fetchMenus();
    });
  }

  Future<List<Code>> _fetchCategories() {
    return _codeService.getCategoryCodes().timeout(const Duration(seconds: 15));
  }

  // 현재 화면·로그인 세션에서 시작한 요청인지 확인.
  bool _isCurrentSession(int session) {
    return mounted && session == _auth.sessionRevision;
  }

  bool _isCurrentLoad(int session, int loadRevision) {
    return _isCurrentSession(session) && loadRevision == _loadRevision;
  }

  // 공개 메뉴 목록 조회.
  //
  // 즐겨찾기 조회에 실패하더라도 공개 메뉴는 반환한다.
  Future<List<AllMenuScreenModel>> _fetchMenus() async {
    final loadRevision = ++_loadRevision;
    final session = _auth.sessionRevision;

    final keyword = _searchController.text.trim();
    final category = _selectedCategory;

    final menus = await _menuService.fetchMenus(
      keyword: keyword,
      category: category,
    );

    if (!_isCurrentLoad(session, loadRevision)) {
      return menus;
    }

    // 비회원은 즐겨찾기 API를 호출하지 않는다.
    if (!_auth.hasSession) {
      _favoriteMenuIds.clear();
      _favoritesLoaded = false;
      _favoritesFailed = false;

      return menus;
    }

    // 같은 계정에서 검색 조건만 바꾼 경우 기존 하트 상태 재사용.
    if (_favoritesLoaded) {
      return menus;
    }

    try {
      final favorites = await _likeService.fetchFavorites();

      if (!_isCurrentLoad(session, loadRevision)) {
        return menus;
      }

      _favoriteMenuIds
        ..clear()
        ..addAll(favorites.map((menu) => menu.menuId));

      _favoritesLoaded = true;
      _favoritesFailed = false;
    } catch (error) {
      if (!_isCurrentLoad(session, loadRevision)) {
        return menus;
      }

      debugPrint('즐겨찾기 조회 실패: $error');

      _favoriteMenuIds.clear();
      _favoritesLoaded = false;
      _favoritesFailed = true;
    }

    return menus;
  }

  // 상세 화면에서 돌아오면 하트 상태 다시 조회.
  Future<void> _openRecipe(AllMenuScreenModel menu) async {
    // 목록의 변경 요청과 상세 화면의 변경 요청이 겹치지 않도록 처리.
    if (_updatingMenuIds.isNotEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecipeScreen(menuId: menu.menuId, menuName: menu.menuName),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _favoritesLoaded = false;
      _favoritesFailed = false;

      _menusFuture = _fetchMenus();
    });
  }

  void _search() {
    FocusScope.of(context).unfocus();

    setState(() {
      _menusFuture = _fetchMenus();
    });
  }

  void _selectCategory(String categoryId) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedCategory = categoryId;
      _menusFuture = _fetchMenus();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _search();
  }

  void _retryCategories() {
    setState(() {
      _categoriesFuture = _fetchCategories();
    });
  }

  void _retryFavorites() {
    setState(() {
      _favoritesLoaded = false;
      _favoritesFailed = false;

      _menusFuture = _fetchMenus();
    });
  }

  Future<void> _toggleFavorite(AllMenuScreenModel menu) async {
    // 비회원은 저장 요청 대신 로그인 안내.
    if (!_auth.hasSession) {
      await showMemberLogin(context);
      return;
    }

    // 현재 상태를 모르면 등록/해제를 정확히 결정할 수 없으므로 대기.
    if (!_favoritesLoaded) {
      return;
    }

    final menuId = menu.menuId;
    final session = _auth.sessionRevision;

    if (_updatingMenuIds.contains(menuId)) {
      return;
    }

    final wasFavorite = _favoriteMenuIds.contains(menuId);

    setState(() {
      _updatingMenuIds.add(menuId);
    });

    try {
      if (wasFavorite) {
        await _likeService.removeFavorite(menuId);
      } else {
        await _likeService.addFavorite(menuId);
      }

      // 요청 중 계정이 바뀌었다면 이전 계정의 결과를 반영하지 않는다.
      if (!_isCurrentSession(session)) {
        return;
      }

      // 서버 저장 성공 후 하트 상태 변경.
      setState(() {
        if (wasFavorite) {
          _favoriteMenuIds.remove(menuId);
        } else {
          _favoriteMenuIds.add(menuId);
        }
      });
    } catch (error) {
      if (!_isCurrentSession(session)) {
        return;
      }

      debugPrint('즐겨찾기 변경 실패: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '즐겨찾기를 해제하지 못했어요. 다시 시도해 주세요.'
                : '즐겨찾기를 등록하지 못했어요. 다시 시도해 주세요.',
          ),
        ),
      );
    } finally {
      // 이전 계정의 요청이 새 계정의 처리 상태를 변경하지 않도록 확인.
      if (_isCurrentSession(session)) {
        setState(() {
          _updatingMenuIds.remove(menuId);
        });
      }
    }
  }

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: _primary,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: -0.4,
        color: selected ? Colors.white : _bodyColor,
      ),
      side: BorderSide(color: selected ? _primary : _border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildCategoryFilters() {
    return FutureBuilder<List<Code>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '카테고리를 불러오지 못했어요.',
                    style: TextStyle(fontSize: 12, color: _bodyColor),
                  ),
                ),
                TextButton(
                  onPressed: _retryCategories,
                  style: TextButton.styleFrom(foregroundColor: _primary),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final categories = snapshot.data ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  label: '전체',
                  selected: _selectedCategory.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      _selectCategory('');
                    }
                  },
                ),
              ),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(
                    label: category.codeName,
                    selected: _selectedCategory == category.codeId,
                    onSelected: (selected) {
                      if (selected) {
                        _selectCategory(category.codeId);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: _softOrange,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_rounded, color: _primary, size: 30),
    );
  }

  Widget _buildMenuImage(String? imagePath) {
    final imageUrl = AllMenuScreenService.resolveImageUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl == null || imageUrl.isEmpty
          ? _imagePlaceholder()
          : Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(
                    color: _softOrange,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _imagePlaceholder();
              },
            ),
    );
  }

  Widget _buildMenuCard(AllMenuScreenModel menu) {
    final categoryName = menu.categoryName?.trim() ?? '';
    final description = menu.description?.trim() ?? '';

    final isFavorite = _favoriteMenuIds.contains(menu.menuId);
    final isUpdating = _updatingMenuIds.contains(menu.menuId);

    // 비회원은 버튼을 눌러 로그인 안내를 볼 수 있다.
    // 회원은 하트 상태 조회를 완료한 뒤 변경할 수 있다.
    final canToggle = !_auth.hasSession || _favoritesLoaded;

    final tooltip = !_auth.hasSession
        ? '로그인 후 즐겨찾기'
        : !_favoritesLoaded
        ? '즐겨찾기 상태 확인 필요'
        : isFavorite
        ? '즐겨찾기 해제'
        : '즐겨찾기 등록';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecipe(menu),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildMenuImage(menu.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _softOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                            color: Color(0xFFAA512B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      menu.menuName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: _titleColor,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          letterSpacing: -0.4,
                          color: _bodyColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: tooltip,
                onPressed: isUpdating || !canToggle
                    ? null
                    : () => _toggleFavorite(menu),
                style: IconButton.styleFrom(
                  backgroundColor: isFavorite
                      ? _softOrange
                      : const Color(0xFFF8F5F2),
                  disabledBackgroundColor: const Color(0xFFF8F5F2),
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder(),
                ),
                icon: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 21,
                        color: !canToggle
                            ? const Color(0xFFD0C7BF)
                            : isFavorite
                            ? _primary
                            : const Color(0xFFAAA097),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softOrange,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFDCC9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _primary, size: 21),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '즐겨찾기 상태를 불러오지 못했어요.\n'
                '다시 조회한 후 하트를 사용할 수 있어요.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _retryFavorites,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAA512B),
              ),
              child: const Text('재시도', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return FutureBuilder<List<AllMenuScreenModel>>(
      key: ValueKey('menus-$_sessionRevision-$_hadSession'),
      future: _menusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: _softOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 34,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '메뉴를 불러오지 못했어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _search,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        final menus = snapshot.data ?? [];

        return Column(
          children: [
            if (_auth.hasSession && _favoritesFailed) _buildFavoritesError(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 17,
                    color: _primary,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      '메뉴 목록',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                        color: _titleColor,
                      ),
                    ),
                  ),
                  Text(
                    '${menus.length}개',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAA512B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: menus.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: _softOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 34,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '검색 결과가 없습니다.\n'
                              '검색어나 카테고리를 변경해보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.9,
                                letterSpacing: -0.4,
                                color: _bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: menus.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        return _buildMenuCard(menus[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          '전체 메뉴',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '오늘의 한 끼,\n'),
                        TextSpan(
                          text: '여기서 찾아보세요.',
                          style: TextStyle(color: _primary),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '먹고 싶은 메뉴를 검색하거나 골라보세요.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      letterSpacing: -0.4,
                      color: _bodyColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    cursorColor: _primary,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.5,
                      color: _titleColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '메뉴명을 검색하세요',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        letterSpacing: -0.4,
                        color: Color(0xFFAAA097),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _primary,
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: IconButton(
                        tooltip: '검색',
                        onPressed: _search,
                        icon: const Icon(
                          Icons.search_rounded,
                          size: 24,
                          color: _primary,
                        ),
                      ),
                      suffixIcon: IconButton(
                        tooltip: '검색어 지우기',
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Color(0xFFAAA097),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildCategoryFilters(),
            const SizedBox(height: 20),
            Expanded(child: _buildMenuList()),
          ],
        ),
      ),
    );
  }
}
