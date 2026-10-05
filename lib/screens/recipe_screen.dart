import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // 이번 테스트: Chrome은 localhost, Android 에뮬레이터는 10.0.2.2
  static const String serverUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  late Future<Map<String, dynamic>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = _fetchMenu();
  }

  Future<Map<String, dynamic>> _fetchMenu() async {
    final uri = Uri.parse('$serverUrl/api/menus/${widget.menuId}');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('메뉴 조회 실패: HTTP ${response.statusCode}');
    }

    // 한글이 깨지지 않도록 UTF-8로 디코딩
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  void _retry() {
    setState(() {
      _menuFuture = _fetchMenu();
    });
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

    // 현재 API의 재료와 조리순서는 배열이 아닌 문자열
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
        : Uri.parse('$serverUrl/').resolve(imagePath).toString();

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
                    if (progress == null) return child;

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

        // DB 문자열에 이미 번호와 줄바꿈이 있으므로 그대로 표시
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피'),
        actions: [
          IconButton(
            tooltip: '즐겨찾기는 추후 제공',
            icon: const Icon(Icons.favorite_border),
            onPressed: null,
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
                      const Text('레시피를 불러오지 못했어요.'),
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
    );
  }
}
