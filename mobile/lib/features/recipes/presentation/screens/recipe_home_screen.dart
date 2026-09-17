import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/food_watermark_background.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../favorites/presentation/providers/favorite_notifier.dart';
import '../../../reviews/data/models/recipe_rating_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../providers/recipe_notifier.dart';
import '../widgets/category_chip.dart';
import '../widgets/food_type_slider.dart';
import '../widgets/recipe_card.dart';

// =========================================================
// Recipe Rating Provider
// =========================================================

final recipeRatingProvider = FutureProvider.autoDispose
    .family<RecipeRatingModel, String>((ref, recipeId) async {
      return ref.read(getRatingSummaryUseCaseProvider).call(recipeId);
    });

// =========================================================
// Recipe Home Screen
// =========================================================

class RecipeHomeScreen extends ConsumerStatefulWidget {
  const RecipeHomeScreen({super.key});

  @override
  ConsumerState<RecipeHomeScreen> createState() => _RecipeHomeScreenState();
}

class _RecipeHomeScreenState extends ConsumerState<RecipeHomeScreen> {
  late final TextEditingController _searchController;

  // =========================================================
  // RasaBavarchi Theme
  // =========================================================

  static const Color _background = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // =========================================================
  // Init
  // =========================================================

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // Search
  // =========================================================

  Future<void> _searchRecipes() async {
    final query = _searchController.text.trim();

    await ref.read(recipeNotifierProvider.notifier).searchRecipes(query);
  }

  // =========================================================
  // Clear Search
  // =========================================================

  Future<void> _clearSearch() async {
    _searchController.clear();

    await ref.read(recipeNotifierProvider.notifier).searchRecipes('');

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // Select Category
  // =========================================================

  Future<void> _selectCategory(String? categoryId) async {
    _searchController.clear();

    await ref.read(recipeNotifierProvider.notifier).selectCategory(categoryId);

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // Select Food Type
  // =========================================================

  Future<void> _selectFoodType(String? foodType) async {
    await ref.read(recipeNotifierProvider.notifier).selectFoodType(foodType);

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(recipeNotifierProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final recipeNotifier = ref.read(recipeNotifierProvider.notifier);

    final selectedCategoryId = recipeNotifier.selectedCategoryId;
    final selectedFoodType = recipeNotifier.selectedFoodType;

    return Scaffold(
      backgroundColor: _background,

      // =======================================================
      // APP BAR
      // =======================================================
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'RasaBavarchi',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Favorites',
              onPressed: () {
                context.push('/favorites');
              },
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: _darkTeal,
                size: 27,
              ),
            ),
          ),
        ],
      ),

      // =======================================================
      // BODY
      // =======================================================
      body: FoodWatermarkBackground(
        child: Column(
          children: [
            // =====================================================
            // SEARCH
            // =====================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: _buildSearchField(),
            ),

            // =====================================================
            // MAIN CONTENT
            // =====================================================
            Expanded(
              child: RefreshIndicator(
                color: _teal,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await ref.read(recipeNotifierProvider.notifier).refresh();
                  ref.invalidate(recipeRatingProvider);
                },
                child: recipesState.when(
                  // =================================================
                  // LOADING
                  // =================================================

                  loading: () {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: CircularProgressIndicator(color: _teal),
                          ),
                        ),
                      ],
                    );
                  },

                  // =================================================
                  // ERROR
                  // =================================================
                  error: (error, stackTrace) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 48,
                                    color: _teal,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    ApiErrorHandler.getMessage(error),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _secondaryText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },

                  // =================================================
                  // DATA
                  // =================================================
                  data: (recipes) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      children: [
                        // ===========================================
                        // CATEGORIES
                        // ===========================================

                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _darkTeal,
                            letterSpacing: -0.4,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ===========================================
                        // CATEGORY LIST
                        // ===========================================
                        categoriesState.when(
                          loading: () {
                            return const SizedBox(
                              height: 44,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _teal,
                                  ),
                                ),
                              ),
                            );
                          },

                          error: (error, stackTrace) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                ApiErrorHandler.getMessage(error),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },

                          data: (categories) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  CategoryChip(
                                    title: 'All',
                                    selected: selectedCategoryId == null,
                                    onTap: () {
                                      _selectCategory(null);
                                    },
                                  ),
                                  ...categories.map((category) {
                                    return CategoryChip(
                                      title: category.name,
                                      selected:
                                          selectedCategoryId == category.id,
                                      onTap: () {
                                        _selectCategory(category.id);
                                      },
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 26),

                        // ===========================================
                        // FOOD TYPE
                        // ===========================================
                        FoodTypeSlider(
                          value: selectedFoodType,
                          onChanged: _selectFoodType,
                        ),

                        const SizedBox(height: 28),

                        // ===========================================
                        // RECIPE HEADING
                        // ===========================================
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _searchController.text.trim().isEmpty
                                    ? 'Recipes'
                                    : 'Search Results',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: _darkTeal,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            if (recipes.isNotEmpty)
                              Text(
                                '${recipes.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _secondaryText,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ===========================================
                        // EMPTY STATE
                        // ===========================================
                        if (recipes.isEmpty) _buildEmptyState(),

                        // ===========================================
                        // RECIPE GRID
                        // ===========================================
                        if (recipes.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: recipes.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.sizeOf(context).width >= 700
                                      ? 3
                                      : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.60,
                                ),
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];

                              return _RecipeCardWithRating(
                                recipeId: recipe.id,
                                title: recipe.title,
                                description: recipe.description,
                                imageUrl: recipe.imageUrl ?? '',
                                duration:
                                    '${recipe.prepTime + recipe.cookTime} mins',
                                difficulty: recipe.difficulty.name,
                                category: recipe.category.name,
                                foodType: recipe.foodType,
                                onTap: () {
                                  context.push('/recipe/${recipe.id}');
                                },
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Search Field
  // =========================================================

  Widget _buildSearchField() {
    final hasText = _searchController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          _searchRecipes();
        },
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          hintStyle: const TextStyle(color: _secondaryText, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: _teal, size: 24),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded, color: _secondaryText),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _teal, width: 1.4),
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  // =========================================================
  // Empty State
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 65, bottom: 90),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9C7),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.search_off_rounded, size: 40, color: _teal),
          ),
          const SizedBox(height: 18),
          const Text(
            'No recipes found',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _darkTeal,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Try another recipe name or choose a different category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Recipe Card With Rating + Favorite
// =========================================================

class _RecipeCardWithRating extends ConsumerStatefulWidget {
  const _RecipeCardWithRating({
    required this.recipeId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.difficulty,
    required this.category,
    required this.foodType,
    required this.onTap,
  });

  final String recipeId;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final String difficulty;
  final String category;
  final String foodType;
  final VoidCallback onTap;

  @override
  ConsumerState<_RecipeCardWithRating> createState() =>
      _RecipeCardWithRatingState();
}

class _RecipeCardWithRatingState extends ConsumerState<_RecipeCardWithRating> {
  bool _isFavorite = false;
  bool _isFavoriteLoading = true;

  // =========================================================
  // Init
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  // =========================================================
  // Load Favorite
  // =========================================================

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorite = await ref
          .read(favoriteNotifierProvider.notifier)
          .isFavorite(widget.recipeId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  // =========================================================
  // Toggle Favorite
  // =========================================================

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) {
      return;
    }

    final previousValue = _isFavorite;

    setState(() {
      _isFavorite = !previousValue;
      _isFavoriteLoading = true;
    });

    try {
      await ref
          .read(favoriteNotifierProvider.notifier)
          .toggleFavorite(widget.recipeId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = previousValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorHandler.getMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteLoading = false;
        });
      }
    }
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(recipeRatingProvider(widget.recipeId));

    return ratingState.when(
      // =======================================================
      // Rating Loading
      // =======================================================

      loading: () {
        return RecipeCard(
          title: widget.title,
          description: widget.description,
          imageUrl: widget.imageUrl,
          duration: widget.duration,
          difficulty: widget.difficulty,
          rating: 0.0,
          category: widget.category,
          foodType: widget.foodType,
          isFavorite: _isFavorite,
          isFavoriteLoading: _isFavoriteLoading,
          onFavoriteTap: _toggleFavorite,
          onTap: widget.onTap,
        );
      },

      // =======================================================
      // Rating Error
      // =======================================================
      error: (error, stackTrace) {
        return RecipeCard(
          title: widget.title,
          description: widget.description,
          imageUrl: widget.imageUrl,
          duration: widget.duration,
          difficulty: widget.difficulty,
          rating: 0.0,
          category: widget.category,
          foodType: widget.foodType,
          isFavorite: _isFavorite,
          isFavoriteLoading: _isFavoriteLoading,
          onFavoriteTap: _toggleFavorite,
          onTap: widget.onTap,
        );
      },

      // =======================================================
      // Rating Data
      // =======================================================
      data: (ratingSummary) {
        return RecipeCard(
          title: widget.title,
          description: widget.description,
          imageUrl: widget.imageUrl,
          duration: widget.duration,
          difficulty: widget.difficulty,
          rating: ratingSummary.averageRating,
          category: widget.category,
          foodType: widget.foodType,
          isFavorite: _isFavorite,
          isFavoriteLoading: _isFavoriteLoading,
          onFavoriteTap: _toggleFavorite,
          onTap: widget.onTap,
        );
      },
    );
  }
}
