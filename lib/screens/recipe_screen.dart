import 'package:flutter/material.dart';

// 레시피 화면
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({
    super.key,
    required this.menuName,
    this.servings,
    this.cookingTime,
    this.difficulty,
    this.ingredients = const [],
    this.steps = const [],
    this.tip,
  });

  final String menuName;
  final String? servings;
  final String? cookingTime;
  final String? difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (servings != null && servings!.isNotEmpty) servings!,
      if (cookingTime != null && cookingTime!.isNotEmpty) cookingTime!,
      if (difficulty != null && difficulty!.isNotEmpty) difficulty!,
    ];

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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7D2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.soup_kitchen,
                size: 100,
                color: Color(0xFFB45A30),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              menuName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
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
            if (steps.isEmpty)
              const Text('등록된 조리 순서가 없습니다.')
            else
              for (var index = 0; index < steps.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('${index + 1}. ${steps[index]}'),
                ),
            if (tip != null && tip!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '요리 팁',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(tip!),
            ],
            const SizedBox(height: 28),
            const Text(
              '알레르기 성분은 사용한 제품의 표시를 확인하세요.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
