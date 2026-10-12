import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../models/code.dart';
import '../services/all_menu_screen_service.dart';
import '../services/code_service.dart';
import '../services/like_service.dart';
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
  final _menuService = AllMenuScreenService();
  final _codeService = CodeService();
  final _likeService = LikeService();

  final _searchController = TextEditingController();

  // API 조회 결과
  late Future<List<Code>> _categoriesFuture;
  late Future<List<AllMenuScreenModel>> _menusFuture;

  // 빈 문자열이면 전체 카테고리
  String _selectedCategory = '';

  // 즐겨찾기에 등록된 메뉴 ID
  final Set<int> _favoriteMenuIds = {};

  // 등록·삭제 요청이 진행 중인 메뉴 ID
  final Set<int> _updatingMenuIds = {};

  bool _favoritesLoaded = false;

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.initialKeyword.trim();
    _selectedCategory = widget.initialCategory;

    _categoriesFuture = _fetchCategories();
    _menusFuture = _fetchMenus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 기존 공통코드 서비스를 재사용
  Future<List<Code>> _fetchCategories() {
    return _codeService.getCategoryCodes().timeout(const Duration(seconds: 15));
  }

  // 상세 화면에서 돌아오면 즐겨찾기 상태를 다시 조회
  Future<void> _openRecipe(AllMenuScreenModel menu) async {
    // 목록에서 진행 중인 변경 요청과 겹치지 않도록 처리
    if (_updatingMenuIds.isNotEmpty) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            RecipeScreen(menuId: menu.menuId, menuName: menu.menuName),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      // 다음 조회에서 메뉴와 즐겨찾기를 함께 다시 불러온다.
      _favoritesLoaded = false;
      _menusFuture = _fetchMenus();
    });
  }

  // 처음에는 메뉴 목록과 즐겨찾기 상태를 함께 조회한다.
  // 이후 검색에서는 메뉴 목록만 다시 조회한다.
  Future<List<AllMenuScreenModel>> _fetchMenus() async {
    final keyword = _searchController.text.trim();
    final category = _selectedCategory;

    if (_favoritesLoaded) {
      return _menuService.fetchMenus(keyword: keyword, category: category);
    }

    final results = await Future.wait<List<AllMenuScreenModel>>([
      _menuService.fetchMenus(keyword: keyword, category: category),
      _likeService.fetchFavorites(),
    ]);

    if (!mounted) {
      return results[0];
    }

    _favoriteMenuIds
      ..clear()
      ..addAll(results[1].map((menu) => menu.menuId));

    _favoritesLoaded = true;

    return results[0];
  }

  // 검색 및 메뉴 목록 재시도
  void _search() {
    FocusScope.of(context).unfocus();

    setState(() {
      _menusFuture = _fetchMenus();
    });
  }

  // 카테고리 선택 후 현재 검색어와 함께 조회
  void _selectCategory(String categoryId) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedCategory = categoryId;
      _menusFuture = _fetchMenus();
    });
  }

  // 검색어를 지우고 현재 카테고리로 다시 조회
  void _clearSearch() {
    _searchController.clear();
    _search();
  }

  // 카테고리 목록 조회 실패 시 재시도
  void _retryCategories() {
    setState(() {
      _categoriesFuture = _fetchCategories();
    });
  }

  // 현재 하트 상태에 따라 등록 또는 해제
  Future<void> _toggleFavorite(AllMenuScreenModel menu) async {
    final menuId = menu.menuId;

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

      if (!mounted) {
        return;
      }

      // 서버 요청 성공 후에만 하트 상태 변경
      setState(() {
        if (wasFavorite) {
          _favoriteMenuIds.remove(menuId);
        } else {
          _favoriteMenuIds.add(menuId);
        }
      });
    } catch (error) {
      if (!mounted) {
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
      if (mounted) {
        setState(() {
          _updatingMenuIds.remove(menuId);
        });
      }
    }
  }

  // 공통코드 API 응답으로 카테고리 버튼 생성
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(child: Text('카테고리를 불러오지 못했어요.')),
                TextButton(
                  onPressed: _retryCategories,
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
              // 전체는 카테고리 검색 조건을 해제하는 버튼
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('전체'),
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
                  child: ChoiceChip(
                    label: Text(category.codeName),
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

  // 이미지가 없거나 로딩에 실패했을 때 표시
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
                if (progress == null) {
                  return child;
                }

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
    // 음식 카드에는 메뉴 API의 categoryName을 사용
    final categoryName = menu.categoryName?.trim() ?? '';
    final description = menu.description?.trim() ?? '';

    final isFavorite = _favoriteMenuIds.contains(menu.menuId);
    final isUpdating = _updatingMenuIds.contains(menu.menuId);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecipe(menu),
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
              IconButton(
                tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 등록',
                onPressed: isUpdating ? null : () => _toggleFavorite(menu),
                icon: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black45,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return FutureBuilder<List<AllMenuScreenModel>>(
      future: _menusFuture,
      builder: (context, snapshot) {
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
                  const Text('메뉴 또는 즐겨찾기를 불러오지 못했어요.'),
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
                '검색 결과가 없습니다.\n'
                '검색어나 카테고리를 변경해보세요.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

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
            _buildCategoryFilters(),
            const SizedBox(height: 20),
            Expanded(child: _buildMenuList()),
          ],
        ),
      ),
    );
  }
}
