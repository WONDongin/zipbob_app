import 'dart:async';

import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../services/all_menu_screen_service.dart';
import '../services/auth_service.dart';
import '../services/like_service.dart';
import '../widgets/member_login_card.dart';
import 'all_menu_screen.dart';
import 'recipe_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color _primary = Color(0xFFEF7544);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _softOrange = Color(0xFFFFEEE5);
  static const Color _border = Color(0xFFF0E5DC);
  static const Color _titleColor = Color(0xFF222222);
  static const Color _bodyColor = Color(0xFF78716B);

  final AuthService _auth = AuthService.instance;
  final LikeService _likeService = LikeService();

  List<AllMenuScreenModel> _favorites = [];

  // 삭제 요청 중인 메뉴 ID.
  final Set<int> _removingMenuIds = {};

  late int _sessionRevision;
  late bool _hadSession;

  // 이전 목록 조회 응답이 최신 목록을 덮어쓰지 않도록 구분.
  int _loadRevision = 0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _sessionRevision = _auth.sessionRevision;
    _hadSession = _auth.hasSession;

    _auth.addListener(_onAuthChanged);

    unawaited(_loadFavorites());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);

    super.dispose();
  }

  bool _isCurrentSession(int session) {
    return mounted && session == _auth.sessionRevision;
  }

  bool _isCurrentLoad(int session, int revision) {
    return _isCurrentSession(session) && revision == _loadRevision;
  }

  // 로그인·로그아웃·계정 변경 시 이전 개인 상태 제거.
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
      // 진행 중이던 이전 목록 조회 무효화.
      _loadRevision++;

      _favorites = [];
      _removingMenuIds.clear();

      _isLoading = false;
      _errorMessage = null;
    });

    unawaited(_loadFavorites());
  }

  // 현재 로그인 계정의 목록 조회.
  Future<void> _loadFavorites() async {
    if (!mounted || _removingMenuIds.isNotEmpty) {
      return;
    }

    final session = _auth.sessionRevision;
    final revision = ++_loadRevision;

    // 비회원은 회원 전용 API를 호출하지 않는다.
    if (!_auth.hasSession) {
      setState(() {
        _favorites = [];
        _isLoading = false;
        _errorMessage = null;
      });

      return;
    }

    setState(() {
      _favorites = [];
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final menus = await _likeService.fetchFavorites();

      if (!_isCurrentLoad(session, revision)) {
        return;
      }

      setState(() {
        _favorites = List<AllMenuScreenModel>.of(menus);
        _isLoading = false;
      });
    } catch (error) {
      if (!_isCurrentLoad(session, revision)) {
        return;
      }

      debugPrint('즐겨찾기 목록 조회 실패: $error');

      setState(() {
        _favorites = [];
        _isLoading = false;
        _errorMessage = '즐겨찾기를 불러오지 못했어요.';
      });
    }
  }

  // 상세 화면에서 변경한 즐겨찾기를 복귀 시 다시 반영.
  Future<void> _openRecipe(AllMenuScreenModel menu) async {
    if (!_auth.hasSession || _isLoading || _removingMenuIds.isNotEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecipeScreen(menuId: menu.menuId, menuName: menu.menuName),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadFavorites();
  }

  // 전체 메뉴는 비회원도 이동할 수 있다.
  Future<void> _openAllMenus() async {
    if (_isLoading || _removingMenuIds.isNotEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AllMenuScreen()),
    );

    if (!mounted) {
      return;
    }

    await _loadFavorites();
  }

  Future<void> _removeFavorite(AllMenuScreenModel menu) async {
    if (!_auth.hasSession ||
        _isLoading ||
        _removingMenuIds.contains(menu.menuId)) {
      return;
    }

    final session = _auth.sessionRevision;
    final menuId = menu.menuId;

    setState(() {
      _removingMenuIds.add(menuId);
    });

    try {
      await _likeService.removeFavorite(menuId);

      // 이전 계정의 삭제 응답을 현재 계정에 반영하지 않는다.
      if (!_isCurrentSession(session)) {
        return;
      }

      // 서버 삭제 성공 후 화면에서도 제거.
      setState(() {
        _favorites.removeWhere((item) => item.menuId == menuId);
      });
    } catch (error) {
      if (!_isCurrentSession(session)) {
        return;
      }

      debugPrint('즐겨찾기 해제 실패: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기를 해제하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      // 이전 요청이 새 계정의 로딩 상태를 변경하지 않도록 확인.
      if (_isCurrentSession(session)) {
        setState(() {
          _removingMenuIds.remove(menuId);
        });
      }
    }
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

  Widget _buildFavoriteCard(AllMenuScreenModel menu) {
    final categoryName = menu.categoryName?.trim() ?? '';
    final description = menu.description?.trim() ?? '';

    final isRemoving = _removingMenuIds.contains(menu.menuId);

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
        onTap: _removingMenuIds.isNotEmpty ? null : () => _openRecipe(menu),
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
                tooltip: '즐겨찾기 해제',
                onPressed: isRemoving ? null : () => _removeFavorite(menu),
                style: IconButton.styleFrom(
                  backgroundColor: _softOrange,
                  disabledBackgroundColor: _softOrange,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder(),
                ),
                icon: isRemoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : const Icon(
                        Icons.favorite_rounded,
                        size: 21,
                        color: _primary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: MemberLoginCard(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: _softOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        width: 58,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18EF7544),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 32,
                          color: _primary,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 5,
                      right: 3,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '저장한 메뉴가 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.7,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '마음에 드는 메뉴의 하트를 눌러\n'
                '나만의 맛있는 목록을 채워보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _removingMenuIds.isNotEmpty ? null : _openAllMenus,
                  style: _primaryButtonStyle(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('전체 메뉴 보러 가기', textAlign: TextAlign.center),
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

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _softOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  unawaited(_loadFavorites());
                },
                style: _primaryButtonStyle(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_auth.hasSession) {
      return _buildGuestState();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '다시 먹고 싶은,\n'),
                    TextSpan(
                      text: '나만의 메뉴 모음',
                      style: TextStyle(color: _primary),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 26,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '마음에 드는 메뉴를 모아두고 꺼내보세요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 17, color: _primary),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      '저장한 메뉴',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                        color: _titleColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _softOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_favorites.length}개',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFAA512B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: _favorites.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final menu = _favorites[index];

              // 항목 삭제 후에도 메뉴 ID로 카드를 식별.
              return KeyedSubtree(
                key: ValueKey(menu.menuId),
                child: _buildFavoriteCard(menu),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canOpenAllMenus = !_isLoading && _removingMenuIds.isEmpty;

    return PopScope<void>(
      // 삭제 완료 후 돌아가야 홈이 최신 목록을 조회할 수 있다.
      canPop: _removingMenuIds.isEmpty,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            '즐겨찾기',
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: '전체 메뉴 검색',
                onPressed: canOpenAllMenus ? _openAllMenus : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white,
                  shape: const CircleBorder(side: BorderSide(color: _border)),
                ),
                icon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }
}
