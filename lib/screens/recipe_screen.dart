import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/all_menu_screen_service.dart';
import '../services/auth_service.dart';
import '../services/like_service.dart';
import '../services/recent_recipe_service.dart';
import '../services/user_device_service.dart';
import '../widgets/member_login_card.dart';

// 레시피 화면
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({
    super.key,
    required this.menuName,
    this.menuId = 1,
    this.servings,
    this.cookingTime,
    this.difficulty,
    this.ingredients = const [],
    this.steps = const [],
    this.tip,
  });

  final int menuId;
  final String menuName;

  // 기존 화면에서 전달하는 인자와의 호환을 위해 유지.
  // 레시피 본문은 API 응답을 사용한다.
  final String? servings;
  final String? cookingTime;
  final String? difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String? tip;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  static const Color _primary = Color(0xFFEF7544);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _softOrange = Color(0xFFFFEEE5);
  static const Color _border = Color(0xFFF0E5DC);
  static const Color _titleColor = Color(0xFF222222);
  static const Color _bodyColor = Color(0xFF78716B);

  final AuthService _auth = AuthService.instance;
  final LikeService _likeService = LikeService();
  final RecentRecipeService _recentRecipeService = RecentRecipeService();

  late Future<Map<String, dynamic>> _menuFuture;

  late int _sessionRevision;
  late bool _hadSession;

  // 공개 레시피 조회 완료 여부.
  bool _menuLoaded = false;

  // 현재 계정의 즐겨찾기 상태.
  bool _isFavorite = false;
  bool _favoritesLoaded = false;
  bool _isLoadingFavorites = false;
  bool _favoritesFailed = false;

  // 즐겨찾기 변경 진행 여부.
  bool _isUpdatingFavorite = false;

  // 현재 화면·계정에서 최근 조회 저장 성공 여부.
  bool _hasRecordedRecent = false;
  bool _isRecordingRecent = false;
  bool _recentFailed = false;
  int? _recordingSession;

  // 늦게 도착한 이전 조회 응답 구분.
  int _menuLoadRevision = 0;
  int _favoriteLoadRevision = 0;

  @override
  void initState() {
    super.initState();

    _sessionRevision = _auth.sessionRevision;
    _hadSession = _auth.hasSession;

    _menuFuture = _fetchMenu();

    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);

    super.dispose();
  }

  bool _isCurrentSession(int session) {
    return mounted && session == _auth.sessionRevision;
  }

  bool _isCurrentFavoriteLoad(int session, int revision) {
    return _isCurrentSession(session) && revision == _favoriteLoadRevision;
  }

  // 로그인·로그아웃·계정 변경 시 이전 개인 상태 초기화.
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
      // 진행 중이던 이전 즐겨찾기 조회 무효화.
      _favoriteLoadRevision++;

      _menuLoaded = false;

      _isFavorite = false;
      _favoritesLoaded = false;
      _isLoadingFavorites = false;
      _favoritesFailed = false;
      _isUpdatingFavorite = false;

      _hasRecordedRecent = false;
      _isRecordingRecent = false;
      _recentFailed = false;
      _recordingSession = null;

      _menuFuture = _fetchMenu();
    });
  }

  // 공개 레시피 조회.
  //
  // 개인 기능의 응답을 기다리지 않고 레시피를 반환한다.
  Future<Map<String, dynamic>> _fetchMenu() async {
    final revision = ++_menuLoadRevision;
    final session = _auth.sessionRevision;

    final uri = Uri.parse(
      '${UserDeviceService.serverUrl}/api/menus/${widget.menuId}',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('메뉴 조회 실패: HTTP ${response.statusCode}');
    }

    final menu =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (!_isCurrentSession(session) || revision != _menuLoadRevision) {
      return menu;
    }

    setState(() {
      _menuLoaded = true;
    });

    // 비회원은 개인 API를 호출하지 않는다.
    if (_auth.hasSession) {
      // 두 메서드는 내부에서 오류를 처리한다.
      // 개인 기능 실패가 레시피 표시를 막지 않도록 별도로 실행.
      unawaited(_loadFavoriteStatus(session));
      unawaited(_recordRecentRecipe(session));
    }

    return menu;
  }

  // 현재 계정의 즐겨찾기 목록으로 이 메뉴의 하트 상태 확인.
  Future<void> _loadFavoriteStatus(int session) async {
    if (!_isCurrentSession(session) ||
        !_auth.hasSession ||
        !_menuLoaded ||
        _isLoadingFavorites) {
      return;
    }

    final revision = ++_favoriteLoadRevision;

    setState(() {
      _isLoadingFavorites = true;
      _favoritesLoaded = false;
      _favoritesFailed = false;
    });

    try {
      final favorites = await _likeService.fetchFavorites();

      if (!_isCurrentFavoriteLoad(session, revision)) {
        return;
      }

      setState(() {
        _isFavorite = favorites.any((menu) => menu.menuId == widget.menuId);

        _favoritesLoaded = true;
        _favoritesFailed = false;
      });
    } catch (error) {
      if (!_isCurrentFavoriteLoad(session, revision)) {
        return;
      }

      debugPrint('레시피 즐겨찾기 조회 실패: $error');

      setState(() {
        _isFavorite = false;
        _favoritesLoaded = false;
        _favoritesFailed = true;
      });
    } finally {
      if (_isCurrentFavoriteLoad(session, revision)) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  // 현재 화면·계정에서 최근 본 레시피를 한 번 저장한다.
  Future<void> _recordRecentRecipe(int session) async {
    if (!_isCurrentSession(session) ||
        !_auth.hasSession ||
        !_menuLoaded ||
        _hasRecordedRecent ||
        _isRecordingRecent) {
      return;
    }

    setState(() {
      _isRecordingRecent = true;
      _recordingSession = session;
      _recentFailed = false;
    });

    try {
      await _recentRecipeService.recordView(widget.menuId);

      if (!_isCurrentSession(session)) {
        return;
      }

      setState(() {
        _hasRecordedRecent = true;
        _recentFailed = false;
      });
    } catch (error) {
      if (!_isCurrentSession(session)) {
        return;
      }

      debugPrint('최근 본 레시피 저장 실패: $error');

      setState(() {
        _recentFailed = true;
      });
    } finally {
      if (_isCurrentSession(session) && _recordingSession == session) {
        setState(() {
          _isRecordingRecent = false;
          _recordingSession = null;
        });
      }
    }
  }

  // 공개 레시피 조회 실패 시 재시도.
  void _retryMenu() {
    setState(() {
      _menuLoaded = false;
      _menuFuture = _fetchMenu();
    });
  }

  void _retryFavorites() {
    unawaited(_loadFavoriteStatus(_auth.sessionRevision));
  }

  void _retryRecent() {
    unawaited(_recordRecentRecipe(_auth.sessionRevision));
  }

  Future<void> _toggleFavorite() async {
    if (!_menuLoaded) {
      return;
    }

    if (!_auth.hasSession) {
      await showMemberLogin(context);
      return;
    }

    if (!_favoritesLoaded || _isLoadingFavorites || _isUpdatingFavorite) {
      return;
    }

    final session = _auth.sessionRevision;
    final wasFavorite = _isFavorite;

    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      if (wasFavorite) {
        await _likeService.removeFavorite(widget.menuId);
      } else {
        await _likeService.addFavorite(widget.menuId);
      }

      if (!_isCurrentSession(session)) {
        return;
      }

      // 서버 저장 성공 후에만 하트 상태 변경.
      setState(() {
        _isFavorite = !wasFavorite;
      });
    } catch (error) {
      if (!_isCurrentSession(session)) {
        return;
      }

      debugPrint('레시피 즐겨찾기 변경 실패: $error');

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
      if (_isCurrentSession(session)) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  Widget _buildStatusNotice({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAA512B),
              ),
              child: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(String message) {
    return Container(
      height: 220,
      width: double.infinity,
      color: _softOrange,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: _bodyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: _primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // 조리 순서 원문을 줄 시작의 번호 기준으로 나누어 표시한다.
  // 번호 형식이 없거나 앞에 별도 안내문이 있으면 원문으로 표시한다.
  Widget _buildCookingSteps(String stepsText) {
    final text = stepsText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (text.isEmpty) {
      return const Text(
        '등록된 조리 순서가 없습니다.',
        style: TextStyle(
          fontSize: 14,
          height: 1.8,
          letterSpacing: -0.4,
          color: _bodyColor,
        ),
      );
    }

    final pattern = RegExp(r'^[ \t]*(\d+)[.)][ \t]+', multiLine: true);

    final matches = pattern.allMatches(text).toList();

    if (matches.isEmpty || matches.first.start != 0) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.9,
          letterSpacing: -0.3,
          color: _titleColor,
        ),
      );
    }

    // 내용 없는 단계가 있으면 번호나 원문이 사라지지 않도록 그대로 표시.
    final hasEmptyStep = List.generate(matches.length, (index) {
      final start = matches[index].end;
      final end = index + 1 < matches.length
          ? matches[index + 1].start
          : text.length;

      return text.substring(start, end).trim().isEmpty;
    }).any((isEmpty) => isEmpty);

    if (hasEmptyStep) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.9,
          letterSpacing: -0.3,
          color: _titleColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < matches.length; index++) ...[
          if (index > 0) ...[
            const SizedBox(height: 22),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 22),
          ],
          _buildCookingStep(
            number: matches[index].group(1)!,
            content: text
                .substring(
                  matches[index].end,
                  index + 1 < matches.length
                      ? matches[index + 1].start
                      : text.length,
                )
                .trim(),
          ),
        ],
      ],
    );
  }

  // "감자 볶기: 설명" 형태는 제목과 설명을 나누어 표시한다.
  // 짧은 제목이 없는 단계는 내용 전체를 일반 설명으로 표시한다.
  Widget _buildCookingStep({required String number, required String content}) {
    final separator = RegExp(r'[:：]').firstMatch(content);

    final hasTitle =
        separator != null &&
        separator.start > 0 &&
        separator.start <= 40 &&
        !content.substring(0, separator.start).contains('\n') &&
        content.substring(separator.end).trim().isNotEmpty;

    final title = hasTitle
        ? content.substring(0, separator!.start).trim()
        : null;

    final description = hasTitle
        ? content.substring(separator!.end).trim()
        : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _softOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  title ?? '조리 단계 $number',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: _titleColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.85,
            letterSpacing: -0.2,
            color: Color(0xFF57534E),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipe(Map<String, dynamic> menu) {
    final menuName = menu['menuName'] as String? ?? widget.menuName;

    final description = menu['description'] as String? ?? '';

    final servings = menu['servings'] as int?;
    final hours = menu['cookTime'] as int? ?? 0;
    final minutes = menu['cookMinute'] as int? ?? 0;

    final difficulty = menu['difficultyLvl'] as String? ?? '';

    final imagePath = menu['imageUrl'] as String?;

    final ingredientsText = menu['ingredients'] as String? ?? '';

    final stepsText = menu['steps'] as String? ?? '';

    final ingredients = ingredientsText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final timeParts = [if (hours > 0) '$hours시간', if (minutes > 0) '$minutes분'];

    final details = [
      if (servings != null) '$servings인분',
      if (timeParts.isNotEmpty) timeParts.join(' '),
      if (difficulty.isNotEmpty) difficulty,
    ];

    final imageUrl = AllMenuScreenService.resolveImageUrl(imagePath);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      children: [
        if (_auth.hasSession && _favoritesFailed)
          _buildStatusNotice(
            message: '즐겨찾기 상태를 불러오지 못했어요.',
            onRetry: _retryFavorites,
          ),

        if (_auth.hasSession && _recentFailed)
          _buildStatusNotice(
            message: '최근 본 레시피에 저장하지 못했어요.',
            onRetry: _retryRecent,
          ),

        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                imageUrl == null || imageUrl.isEmpty
                    ? _imagePlaceholder('등록된 이미지가 없습니다.')
                    : Image.network(
                        imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return const SizedBox(
                            height: 220,
                            child: ColoredBox(
                              color: _softOrange,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _imagePlaceholder('이미지를 불러오지 못했어요.');
                        },
                      ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _softOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              size: 14,
                              color: _primary,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '맛있는 집밥 한 끼',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: -0.4,
                                color: Color(0xFFAA512B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        menuName,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: -0.9,
                          color: _titleColor,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.8,
                            letterSpacing: -0.4,
                            color: _bodyColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: _background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          details.isEmpty
                              ? '레시피 정보를 준비 중입니다.'
                              : details.join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            letterSpacing: -0.4,
                            color: Color(0xFFAA512B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildSectionCard(
          title: '재료',
          icon: Icons.shopping_basket_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ingredients.isEmpty)
                const Text(
                  '등록된 재료가 없습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: _bodyColor,
                  ),
                )
              else
                for (final ingredient in ingredients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '• $ingredient',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          letterSpacing: -0.4,
                          color: _titleColor,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        _buildSectionCard(
          title: '조리 순서',
          icon: Icons.soup_kitchen_outlined,
          child: _buildCookingSteps(stepsText),
        ),

        if (widget.tip != null && widget.tip!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildSectionCard(
            title: '요리 팁',
            icon: Icons.lightbulb_outline_rounded,
            child: Text(
              widget.tip!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.9,
                letterSpacing: -0.4,
                color: _bodyColor,
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: _bodyColor,
              ),
            ),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                '알레르기 성분은 사용한 제품의 표시를 확인하세요.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteBusy = _isLoadingFavorites || _isUpdatingFavorite;

    final canToggle =
        _menuLoaded &&
        !_isUpdatingFavorite &&
        (!_auth.hasSession || (_favoritesLoaded && !_isLoadingFavorites));

    final tooltip = !_auth.hasSession
        ? '로그인 후 즐겨찾기'
        : !_favoritesLoaded
        ? '즐겨찾기 상태 확인 중'
        : _isFavorite
        ? '즐겨찾기 해제'
        : '즐겨찾기 등록';

    return PopScope<void>(
      // 저장 중 바로 돌아가면 이전 화면이 저장 전 목록을
      // 조회할 수 있으므로 쓰기 요청이 끝날 때까지 대기.
      canPop: !_isUpdatingFavorite && !_isRecordingRecent,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            '레시피',
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
                tooltip: tooltip,
                onPressed: canToggle ? _toggleFavorite : null,
                style: IconButton.styleFrom(
                  backgroundColor: _isFavorite ? _softOrange : Colors.white,
                  disabledBackgroundColor: Colors.white,
                  shape: const CircleBorder(side: BorderSide(color: _border)),
                ),
                icon: favoriteBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 22,
                        color: !canToggle
                            ? const Color(0xFFD0C7BF)
                            : _isFavorite
                            ? _primary
                            : const Color(0xFFAAA097),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            key: ValueKey('recipe-$_sessionRevision-$_hadSession'),
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 3,
                  ),
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
                          '레시피를 불러오지 못했어요.',
                          style: TextStyle(fontSize: 14, color: _bodyColor),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _retryMenu,
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

              return _buildRecipe(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }
}
