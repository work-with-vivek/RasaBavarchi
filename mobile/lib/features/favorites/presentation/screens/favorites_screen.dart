import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../recipes/presentation/providers/recipe_detail_provider.dart';
import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../data/models/favorite_model.dart';
import '../providers/favorite_notifier.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(favoriteNotifierProvider.notifier).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoriteNotifierProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  ref.read(favoriteNotifierProvider.notifier).loadFavorites();
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.refresh_rounded, size: 21, color: _teal),
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const _FavoritesLoading(),

        error: (error, _) => _FavoritesError(
          message: error.toString(),
          onRetry: () {
            ref.read(favoriteNotifierProvider.notifier).loadFavorites();
          },
        ),

        data: (favorites) {
          if (favorites.isEmpty) {
            return const _EmptyFavorites();
          }

          return RefreshIndicator(
            color: _teal,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await ref.read(favoriteNotifierProvider.notifier).loadFavorites();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];

                return _FavoriteRecipeCard(favorite: favorite);
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// FAVORITE RECIPE CARD
// =============================================================

class _FavoriteRecipeCard extends ConsumerWidget {
  const _FavoriteRecipeCard({required this.favorite});

  final FavoriteModel favorite;

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useCase = ref.read(getRecipeUseCaseProvider);

    return FutureBuilder(
      future: useCase(favorite.recipeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FavoriteCardLoading();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _UnavailableRecipeCard(recipeId: favorite.recipeId);
        }

        final recipe = snapshot.data!;

        final visualPath = RecipeVisualMapper.getVisual(
          recipeName: recipe.title,
          category: recipe.category.name,
          foodType: recipe.foodType,
        );

        final totalMinutes = recipe.prepTime + recipe.cookTime;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 1.5,
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _border, width: 0.7),
          ),
          child: InkWell(
            onTap: () {
              context.push('/recipe/${recipe.id}');
            },
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVisual(visualPath),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.18,
                                  fontWeight: FontWeight.w700,
                                  color: _darkTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 21,
                              color: Color(0xFFB04A3A),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        Text(
                          _buildDescription(recipe),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: _secondaryText,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: _teal,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$totalMinutes mins',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryText,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            const Icon(
                              Icons.local_fire_department_outlined,
                              size: 16,
                              color: _teal,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                recipe.difficulty.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Container(
                          height: 3,
                          width: 42,
                          decoration: BoxDecoration(
                            color: _yellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisual(String visualPath) {
    return SizedBox(
      width: 112,
      height: 132,
      child: Container(
        color: _cream,
        child: Image.asset(
          visualPath,
          fit: BoxFit.contain,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Center(
                  child: Icon(Icons.restaurant_rounded, size: 40, color: _teal),
                );
              },
        ),
      ),
    );
  }

  String _buildDescription(dynamic recipe) {
    final categoryName = recipe.category.name;

    if (categoryName.trim().isNotEmpty) {
      return categoryName;
    }

    return 'Saved recipe';
  }
}

// =============================================================
// LOADING CARD
// =============================================================

class _FavoriteCardLoading extends StatelessWidget {
  const _FavoriteCardLoading();

  static const Color _cream = Color(0xFFFDF8ED);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        height: 132,
        child: Row(
          children: [
            Container(width: 112, height: 132, color: _cream),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 16,
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: 120,
                      height: 12,
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// UNAVAILABLE RECIPE
// =============================================================

class _UnavailableRecipeCard extends StatelessWidget {
  const _UnavailableRecipeCard({required this.recipeId});

  final String recipeId;

  static const Color _teal = Color(0xFF00695C);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF8ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.restaurant_rounded, color: _teal),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipe unavailable',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unable to load this saved recipe.',
                    style: const TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    recipeId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// EMPTY FAVORITES
// =============================================================

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _yellow.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 52,
                color: _teal,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No Favorites Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: _darkTeal,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'Tap the heart on a recipe to save '
              'your favorite dishes here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _secondaryText,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: 44,
              height: 3,
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// LOADING STATE
// =============================================================

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  static const Color _teal = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: _teal));
  }
}

// =============================================================
// ERROR STATE
// =============================================================

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _teal.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: _teal,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to Load Favorites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _darkTeal,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _secondaryText,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
