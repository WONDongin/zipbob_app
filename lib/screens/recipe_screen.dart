import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/like_service.dart';

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

  // 기존 화면 호출 코드와의 호환을 위해 유지
  // 레시피 본문에는 API에서 받은 데이터를 사용
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
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  final _likeService = LikeService();

  late Future<Map<String, dynamic>> _menuFuture;

  // 현재 메뉴의 즐겨찾기 상태
  bool _isFavorite = false;

  // 레시피 및 즐겨찾기 상태 조회 완료 여부
  bool _isReady = false;

  // 등록·해제 요청 진행 여부
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _menuFuture = _fetchMenu();
  }

  // 레시피와 현재 메뉴의 즐겨찾기 상태 조회
  Future<Map<String, dynamic>> _fetchMenu() async {
    final uri = Uri.parse('$serverUrl/api/menus/${widget.menuId}');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('메뉴 조회 실패: HTTP ${response.statusCode}');
    }

    final menu =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final favorites = await _likeService.fetchFavorites();

    if (mounted) {
      setState(() {
        // 현재 메뉴의 ID가 즐겨찾기 목록에 포함됐는지 확인
        _isFavorite = favorites.any((item) => item.menuId == widget.menuId);

        _isReady = true;
      });
    }

    return menu;
  }

  void _retry() {
    setState(() {
      _isReady = false;
      _menuFuture = _fetchMenu();
    });
  }

  // 상세 화면의 하트 등록·해제
  Future<void> _toggleFavorite() async {
    if (!_isReady || _isUpdatingFavorite) {
      return;
    }

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

      if (!mounted) {
        return;
      }

      // API 성공 후에만 하트 상태 변경
      setState(() {
        _isFavorite = !wasFavorite;
      });
    } catch (error) {
      if (!mounted) {
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
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  Widget _imagePlaceholder(String message) {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFFFFE7D2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.soup_kitchen, size: 72, color: Color(0xFFB45A30)),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
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

    // API의 재료와 조리순서는 문자열
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

    final imageUrl = imagePath == null || imagePath.trim().isEmpty
        ? null
        : Uri.parse('$serverUrl/').resolve(imagePath.trim()).toString();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: imageUrl == null
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
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _imagePlaceholder('이미지를 불러오지 못했어요.');
                  },
                ),
        ),
        const SizedBox(height: 24),
        Text(
          menuName,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
        const SizedBox(height: 8),
        Text(
          details.isEmpty ? '레시피 정보를 준비 중입니다.' : details.join(' · '),
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 28),
        const Text(
          '재료',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (ingredients.isEmpty)
          const Text('등록된 재료가 없습니다.')
        else
          for (final ingredient in ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $ingredient'),
            ),
        const SizedBox(height: 28),
        const Text(
          '조리 순서',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          stepsText.trim().isEmpty ? '등록된 조리 순서가 없습니다.' : stepsText.trim(),
          style: const TextStyle(fontSize: 16, height: 1.7),
        ),
        if (widget.tip != null && widget.tip!.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            '요리 팁',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(widget.tip!),
        ],
        const SizedBox(height: 28),
        const Text(
          '알레르기 성분은 사용한 제품의 표시를 확인하세요.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      // 변경 요청이 끝나기 전에 이전 화면이 재조회하지 않도록 처리
      canPop: !_isUpdatingFavorite,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('레시피'),
          actions: [
            IconButton(
              tooltip: _isFavorite ? '즐겨찾기 해제' : '즐겨찾기 등록',
              onPressed: !_isReady || _isUpdatingFavorite
                  ? null
                  : _toggleFavorite,
              icon: _isUpdatingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: !_isReady
                          ? Colors.black26
                          : _isFavorite
                          ? Colors.red
                          : Colors.black45,
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('레시피 또는 즐겨찾기를 불러오지 못했어요.'),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _retry,
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
