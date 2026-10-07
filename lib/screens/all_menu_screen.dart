import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../services/all_menu_screen_service.dart';
import 'recipe_screen.dart';

// 전체 메뉴 화면
class AllMenuScreen extends StatefulWidget {
  const AllMenuScreen({super.key});

  @override
  State<AllMenuScreen> createState() => _AllMenuScreenState();
}

class _AllMenuScreenState extends State<AllMenuScreen> {
  final _service = AllMenuScreenService();

  // 검색창에 입력된 값 읽기·지우기
  final _searchController = TextEditingController();

  late Future<List<AllMenuScreenModel>> _menusFuture;

  // 빈 문자열은 전체 카테고리
  String _selectedCategory = '';

  // 상단 버튼 목록: 추후 공통코드 목록 API로 변경
  static const _categories = <String, String>{
    '': '전체',
    'rice_bowl': '덮밥·비빔밥',
    'fried_rice': '볶음밥',
    'noodle': '면 요리',
    'soup_stew': '국·찌개',
    'stir_fry_grill': '볶음·구이',
    'steam_braise': '찜·조림',
    'toast_sandwich': '토스트·샌드위치',
    'salad_simple': '샐러드·간편식',
  };

  @override
  void initState() {
    super.initState();

    // 화면을 처음 열면 전체 메뉴 조회
    _menusFuture = _service.fetchMenus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();

    setState(() {
      _menusFuture = _service.fetchMenus(
        keyword: _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  void _selectCategory(String category) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedCategory = category;
      _menusFuture = _service.fetchMenus(
        keyword: _searchController.text,
        category: category,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _search();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFFFE7D2),
      child: const Icon(Icons.restaurant, color: Color(0xFFB45A30), size: 32),
    );
  }

  Widget _buildMenuImage(String? imagePath) {
    final imageUrl = AllMenuScreenService.resolveImageUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl == null
          ? _imagePlaceholder()
          : Image.network(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
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
    // API에서 받은 한글 카테고리 이름 사용
    final categoryName = menu.categoryName?.trim() ?? '';
    final description = menu.description?.trim() ?? '';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // 선택한 메뉴 ID를 레시피 화면에 전달
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  RecipeScreen(menuId: menu.menuId, menuName: menu.menuName),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildMenuImage(menu.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.menuName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (categoryName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45A30),
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    // API의 로딩·실패·성공에 맞는 화면 표시
    return FutureBuilder<List<AllMenuScreenModel>>(
      future: _menusFuture,
      builder: (context, snapshot) {
        // 새 검색 중에는 이전 목록 대신 로딩 표시
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 12),
                  const Text('메뉴를 불러오지 못했어요.'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _search, child: const Text('다시 시도')),
                ],
              ),
            ),
          );
        }

        final menus = snapshot.data ?? [];

        if (menus.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '검색 결과가 없습니다.\n검색어나 카테고리를 변경해보세요.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 필요한 목록 항목을 생성하며 스크롤 제공
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: menus.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            return _buildMenuCard(menus[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전체 메뉴')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: '메뉴명을 검색하세요',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    tooltip: '검색',
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                  ),
                  suffixIcon: IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (final category in _categories.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.value),
                        selected: _selectedCategory == category.key,
                        onSelected: (selected) {
                          if (selected) {
                            _selectCategory(category.key);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildMenuList()),
          ],
        ),
      ),
    );
  }
}
