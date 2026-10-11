import 'package:flutter/material.dart';

import '../models/all_menu_screen_model.dart';
import '../services/all_menu_screen_service.dart';
import '../services/like_service.dart';
import 'all_menu_screen.dart';
import 'recipe_screen.dart';

// 즐겨찾기 화면
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _likeService = LikeService();

  List<AllMenuScreenModel> _favorites = [];

  // 해제 요청 중인 메뉴 ID
  final Set<int> _removingMenuIds = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 상세 화면에서 돌아오면 즐겨찾기 목록을 다시 조회
  Future<void> _openRecipe(AllMenuScreenModel menu) async {
    if (_isLoading || _removingMenuIds.isNotEmpty) {
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

    await _loadFavorites();
  }

  // 기기별 즐겨찾기 목록 조회
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final menus = await _likeService.fetchFavorites();

      if (!mounted) {
        return;
      }

      setState(() {
        _favorites = menus;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('즐겨찾기 목록 조회 실패: $error');

      setState(() {
        _isLoading = false;
        _errorMessage = '즐겨찾기를 불러오지 못했어요.';
      });
    }
  }

  // 전체 메뉴에서 돌아오면 즐겨찾기를 다시 조회
  Future<void> _openAllMenus() async {
    if (_isLoading || _removingMenuIds.isNotEmpty) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AllMenuScreen()),
    );

    if (!mounted) {
      return;
    }

    await _loadFavorites();
  }

  // 즐겨찾기 해제
  Future<void> _removeFavorite(AllMenuScreenModel menu) async {
    final menuId = menu.menuId;

    if (_removingMenuIds.contains(menuId)) {
      return;
    }

    setState(() {
      _removingMenuIds.add(menuId);
    });

    try {
      await _likeService.removeFavorite(menuId);

      if (!mounted) {
        return;
      }

      // 서버에서 삭제한 뒤 화면 목록에서도 제거
      setState(() {
        _favorites.removeWhere((item) => item.menuId == menuId);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('즐겨찾기 해제 실패: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기를 해제하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _removingMenuIds.remove(menuId);
        });
      }
    }
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

  Widget _buildFavoriteCard(AllMenuScreenModel menu) {
    final categoryName = menu.categoryName?.trim() ?? '';
    final description = menu.description?.trim() ?? '';
    final isRemoving = _removingMenuIds.contains(menu.menuId);

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
                tooltip: '즐겨찾기 해제',
                onPressed: isRemoving ? null : () => _removeFavorite(menu),
                icon: isRemoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              '저장한 메뉴가 없어요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '전체 메뉴에서 마음에 드는 음식의 하트를 눌러보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _removingMenuIds.isNotEmpty ? null : _openAllMenus,
              child: const Text('전체 메뉴 보러 가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.black54),
              const SizedBox(height: 12),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadFavorites,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _favorites.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final menu = _favorites[index];

        // 삭제 후에도 메뉴 ID로 카드를 식별
        return KeyedSubtree(
          key: ValueKey(menu.menuId),
          child: _buildFavoriteCard(menu),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canOpenAllMenus = !_isLoading && _removingMenuIds.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기'),
        actions: [
          IconButton(
            tooltip: '전체 메뉴 검색',
            onPressed: canOpenAllMenus ? _openAllMenus : null,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}
