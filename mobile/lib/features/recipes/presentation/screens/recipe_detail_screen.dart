import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorite_notifier.dart';
import '../../../order_ingredients/presentation/screens/cooking_servings_screen.dart';
import '../../../order_ingredients/presentation/screens/scaled_ingredients_screen.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_notifier.dart';
import '../../../reviews/presentation/widgets/rating_summary.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../../core/widgets/food_watermark_background.dart';
import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../data/models/recipe_model.dart';
import '../providers/recipe_detail_notifier.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _background = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // =============================================================
  // STATE
  // =============================================================

  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  String? _currentUserId;
  bool _isCurrentUserLoading = true;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) {
        return;
      }

      _loadRecipeData();
      _loadFavoriteStatus();
      _loadCurrentUser();
    });
  }

  // =============================================================
  // LOAD RECIPE
  // =============================================================

  void _loadRecipeData() {
    ref.read(recipeDetailNotifierProvider.notifier).loadRecipe(widget.recipeId);

    ref.read(reviewNotifierProvider.notifier).loadReviews(widget.recipeId);
  }

  // =============================================================
  // CURRENT USER
  // =============================================================

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ref.read(currentUserProvider.future);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = user?.id;
        _isCurrentUserLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = null;
        _isCurrentUserLoading = false;
      });
    }
  }

  // =============================================================
  // CURRENT USER REVIEW
  // =============================================================

  ReviewModel? _getCurrentUserReview(List<ReviewModel> reviews) {
    if (_currentUserId == null) {
      return null;
    }

    for (final review in reviews) {
      if (review.userId == _currentUserId) {
        return review;
      }
    }

    return null;
  }

  // =============================================================
  // FAVORITES
  // =============================================================

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
      });
    } catch (_) {
      // Ignore favorite loading errors.
    }
  }

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
      final notifier = ref.read(favoriteNotifierProvider.notifier);

      if (previousValue) {
        await notifier.removeFavorite(widget.recipeId);
      } else {
        await notifier.addFavorite(widget.recipeId);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = previousValue;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update favorite: $e')));
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavoriteLoading = false;
    });
  }

  // =============================================================
  // SELECT RECIPE
  // =============================================================

  Future<void> _selectRecipe(RecipeModel recipe) async {
    final selectedServings = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => CookingServingsScreen(recipe: recipe)),
    );

    if (!mounted || selectedServings == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScaledIngredientsScreen(
          recipe: recipe,
          selectedServings: selectedServings,
        ),
      ),
    );
  }

  // =============================================================
  // NUTRITION
  // =============================================================

  bool _hasNutrition(RecipeModel recipe) {
    return recipe.calories > 0 &&
        recipe.protein > 0 &&
        recipe.carbs > 0 &&
        recipe.fat > 0;
  }

  Future<void> _openNutrition(RecipeModel recipe) async {
    await context.push('/recipe/${recipe.id}/nutrition');

    if (!mounted) {
      return;
    }

    // Reload recipe because the nutrition screen may have
    // generated and saved new nutrition values.
    ref.read(recipeDetailNotifierProvider.notifier).loadRecipe(widget.recipeId);
  }

  // =============================================================
  // UI HELPERS
  // =============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _darkTeal,
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _teal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFE7F2EF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: _teal),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondaryText, fontSize: 12),
        ),
      ],
    );
  }

  // =============================================================
  // NUTRITION CARD
  // =============================================================

  Widget _buildNutritionSection(RecipeModel recipe) {
    final hasNutrition = _hasNutrition(recipe);

    if (!hasNutrition) {
      return _buildNutritionEmptyState(recipe);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Nutrition'),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _nutritionItem(
                  icon: Icons.local_fire_department_rounded,
                  value: recipe.calories.toStringAsFixed(0),
                  label: 'Calories',
                ),
              ),
              Expanded(
                child: _nutritionItem(
                  icon: Icons.fitness_center_rounded,
                  value: '${recipe.protein.toStringAsFixed(1)} g',
                  label: 'Protein',
                ),
              ),
              Expanded(
                child: _nutritionItem(
                  icon: Icons.grain_rounded,
                  value: '${recipe.carbs.toStringAsFixed(1)} g',
                  label: 'Carbs',
                ),
              ),
              Expanded(
                child: _nutritionItem(
                  icon: Icons.water_drop_outlined,
                  value: '${recipe.fat.toStringAsFixed(1)} g',
                  label: 'Fat',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _openNutrition(recipe),
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              side: const BorderSide(color: _teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text(
              'View Full Nutrition',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // NUTRITION EMPTY STATE
  // =============================================================

  Widget _buildNutritionEmptyState(RecipeModel recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Nutrition'),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F2EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _teal,
                  size: 28,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Nutrition not calculated yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Let RasaBavarchi calculate the nutrition '
                'for this recipe using its ingredients.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _openNutrition(recipe),
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _darkTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text(
                    'Calculate Nutrition',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // INGREDIENT ITEM
  // =============================================================

  Widget _buildIngredientItem(RecipeIngredientModel ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F2EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: _teal,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              ingredient.displayMeasurement,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // WRITE REVIEW
  // =============================================================

  Future<void> _showWriteReviewDialog() async {
    final result = await showDialog<ReviewFormResult>(
      context: context,
      builder: (_) {
        return const ReviewFormDialog(
          title: 'Write a Review',
          buttonText: 'Submit',
          initialRating: 5,
          initialComment: '',
        );
      },
    );

    if (result == null) {
      return;
    }

    await _submitReview(rating: result.rating, comment: result.comment);
  }

  Future<void> _submitReview({
    required int rating,
    required String comment,
  }) async {
    await ref
        .read(reviewNotifierProvider.notifier)
        .createReview(
          recipeId: widget.recipeId,
          rating: rating,
          comment: comment,
        );

    if (!mounted) {
      return;
    }

    final reviewState = ref.read(reviewNotifierProvider);

    if (reviewState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit review: ${reviewState.error}'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully!')),
    );

    ref.read(reviewNotifierProvider.notifier).loadReviews(widget.recipeId);
  }

  // =============================================================
  // EDIT REVIEW
  // =============================================================

  Future<void> _showEditReviewDialog(ReviewModel review) async {
    final result = await showDialog<ReviewFormResult>(
      context: context,
      builder: (_) {
        return ReviewFormDialog(
          title: 'Edit Review',
          buttonText: 'Save',
          initialRating: review.rating,
          initialComment: review.comment ?? '',
        );
      },
    );

    if (result == null) {
      return;
    }

    await _updateReview(
      reviewId: review.id,
      rating: result.rating,
      comment: result.comment,
    );
  }

  Future<void> _updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    await ref
        .read(reviewNotifierProvider.notifier)
        .updateReview(
          recipeId: widget.recipeId,
          reviewId: reviewId,
          rating: rating,
          comment: comment,
        );

    if (!mounted) {
      return;
    }

    final reviewState = ref.read(reviewNotifierProvider);

    if (reviewState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update review: ${reviewState.error}'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review updated successfully!')),
    );

    ref.read(reviewNotifierProvider.notifier).loadReviews(widget.recipeId);
  }

  // =============================================================
  // DELETE REVIEW
  // =============================================================

  Future<void> _confirmDeleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Review?'),
          content: const Text(
            'Are you sure you want to delete your review?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteReview(review.id);
  }

  Future<void> _deleteReview(String reviewId) async {
    await ref
        .read(reviewNotifierProvider.notifier)
        .deleteReview(recipeId: widget.recipeId, reviewId: reviewId);

    if (!mounted) {
      return;
    }

    final reviewState = ref.read(reviewNotifierProvider);

    if (reviewState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete review: ${reviewState.error}'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review deleted successfully!')),
    );

    ref.read(reviewNotifierProvider.notifier).loadReviews(widget.recipeId);
  }

  // =============================================================
  // REVIEW SECTION
  // =============================================================

  Widget _buildReviewSection(ReviewState reviewState) {
    final myReview = _getCurrentUserReview(reviewState.reviews);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ratings & Reviews'),

        const SizedBox(height: 14),

        if (reviewState.ratingSummary != null)
          RatingSummary(rating: reviewState.ratingSummary!),

        const SizedBox(height: 16),

        if (_isCurrentUserLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (myReview == null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: reviewState.isSubmitting
                  ? null
                  : _showWriteReviewDialog,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: reviewState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(
                reviewState.isSubmitting ? 'Submitting...' : 'Write a Review',
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F2EF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _teal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have already reviewed this recipe.',
                    style: TextStyle(
                      color: _darkTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 22),

        if (reviewState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (reviewState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(reviewState.error!, textAlign: TextAlign.center),
          )
        else if (reviewState.reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 45,
                  color: _secondaryText.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No reviews yet.',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Be the first to review this recipe!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _secondaryText),
                ),
              ],
            ),
          )
        else
          ...reviewState.reviews.map((review) {
            final isOwner =
                !_isCurrentUserLoading &&
                _currentUserId != null &&
                review.userId == _currentUserId;

            return ReviewCard(
              review: review,
              isOwner: isOwner,
              onEdit: isOwner ? () => _showEditReviewDialog(review) : null,
              onDelete: isOwner ? () => _confirmDeleteReview(review) : null,
            );
          }),
      ],
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final recipeState = ref.watch(recipeDetailNotifierProvider);

    final reviewState = ref.watch(reviewNotifierProvider);

    return Scaffold(
      backgroundColor: _background,

      // ===========================================================
      // APP BAR
      // ===========================================================
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _darkTeal,
            size: 28,
          ),
        ),

        title: const Text(
          'Recipe Details',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _isFavoriteLoading ? null : _toggleFavorite,
            icon: _isFavoriteLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _teal,
                    ),
                  )
                : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite ? const Color(0xFFB04A3A) : _teal,
                    size: 27,
                  ),
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),

      // ===========================================================
      // BODY
      // ===========================================================
      body: FoodWatermarkBackground(
        child: recipeState.when(
          // ---------------------------------------------------------
          // LOADING
          // ---------------------------------------------------------

          loading: () {
            return const Center(child: CircularProgressIndicator(color: _teal));
          },

          // ---------------------------------------------------------
          // ERROR
          // ---------------------------------------------------------
          error: (error, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _teal,
                      size: 50,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Unable to load this recipe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _darkTeal,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _secondaryText),
                    ),
                  ],
                ),
              ),
            );
          },

          // ---------------------------------------------------------
          // DATA
          // ---------------------------------------------------------
          data: (recipe) {
            if (recipe == null) {
              return const Center(child: Text('Recipe not found'));
            }

            final totalTime = recipe.prepTime + recipe.cookTime;

            final foodType = recipe.foodType.toUpperCase();

            final bool isVegan = foodType == 'VEGAN';

            final bool isVegetarian = foodType == 'VEGETARIAN';

            final bool isNonVegetarian = foodType == 'NON_VEGETARIAN';

            final Color foodTypeColor;
            final Color foodTypeBackgroundColor;
            final IconData foodTypeIcon;
            final String foodTypeLabel;

            if (isVegan) {
              foodTypeColor = Colors.green.shade700;
              foodTypeBackgroundColor = Colors.green.shade50;
              foodTypeIcon = Icons.eco_rounded;
              foodTypeLabel = 'Vegan';
            } else if (isVegetarian) {
              foodTypeColor = Colors.orange.shade700;
              foodTypeBackgroundColor = Colors.orange.shade50;
              foodTypeIcon = Icons.restaurant_menu_rounded;
              foodTypeLabel = 'Vegetarian';
            } else if (isNonVegetarian) {
              foodTypeColor = const Color(0xFF8D4538);
              foodTypeBackgroundColor = const Color(0xFFF9E8E2);
              foodTypeIcon = Icons.restaurant_rounded;
              foodTypeLabel = 'Non-Vegetarian';
            } else {
              foodTypeColor = Colors.grey.shade700;
              foodTypeBackgroundColor = Colors.grey.shade100;
              foodTypeIcon = Icons.help_outline_rounded;
              foodTypeLabel = 'Unknown';
            }

            final visualPath = RecipeVisualMapper.getVisual(
              recipeName: recipe.title,
              category: recipe.category.name,
              foodType: recipe.foodType,
            );

            return RefreshIndicator(
              color: _teal,
              onRefresh: () async {
                _loadRecipeData();
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                children: [
                  // =================================================
                  // RECIPE VISUAL
                  // =================================================

                  Container(
                    height: 205,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      visualPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 70,
                            color: _teal,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TITLE
                  // =================================================
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      color: _darkTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // DESCRIPTION
                  // =================================================
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // FOOD TYPE
                  // =================================================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: foodTypeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(foodTypeIcon, size: 17, color: foodTypeColor),
                        const SizedBox(width: 7),
                        Text(
                          foodTypeLabel,
                          style: TextStyle(
                            color: foodTypeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // RECIPE INFO
                  // =================================================
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(
                        icon: Icons.category_outlined,
                        label: recipe.category.name,
                      ),
                      _infoChip(
                        icon: Icons.public_rounded,
                        label: recipe.cuisine.name,
                      ),
                      _infoChip(
                        icon: Icons.speed_rounded,
                        label: recipe.difficulty.name,
                      ),
                      _infoChip(
                        icon: Icons.timer_outlined,
                        label: '$totalTime mins',
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // NUTRITION
                  // =================================================
                  _buildNutritionSection(recipe),

                  const SizedBox(height: 30),

                  // =================================================
                  // INGREDIENTS
                  // =================================================
                  _sectionTitle('Ingredients'),

                  const SizedBox(height: 12),

                  if (recipe.ingredients.isEmpty)
                    const Text(
                      'No ingredients available.',
                      style: TextStyle(color: _secondaryText),
                    )
                  else
                    ...recipe.ingredients.map(_buildIngredientItem),

                  const SizedBox(height: 18),

                  // =================================================
                  // SELECT RECIPE
                  // =================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: recipe.ingredients.isEmpty
                          ? null
                          : () => _selectRecipe(recipe),
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: const Icon(Icons.restaurant_menu_outlined),
                      label: const Text(
                        'Select Recipe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // GENERATE RECIPE VIDEO
                  // =================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '/recipe/${recipe.id}/video'
                          '?title=${Uri.encodeComponent(recipe.title)}',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: const BorderSide(color: _teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: const Icon(Icons.movie_creation_outlined),
                      label: const Text(
                        'Generate Recipe Video',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // INSTRUCTIONS
                  // =================================================
                  _sectionTitle('Instructions'),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      recipe.instructions,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 15.5,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =================================================
                  // REVIEWS
                  // =================================================
                  _buildReviewSection(reviewState),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================
// REVIEW FORM RESULT
// =============================================================

class ReviewFormResult {
  final int rating;
  final String comment;

  const ReviewFormResult({required this.rating, required this.comment});
}

// =============================================================
// REVIEW FORM DIALOG
// =============================================================

class ReviewFormDialog extends StatefulWidget {
  const ReviewFormDialog({
    super.key,
    required this.title,
    required this.buttonText,
    required this.initialRating,
    required this.initialComment,
  });

  final String title;
  final String buttonText;
  final int initialRating;
  final String initialComment;

  @override
  State<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<ReviewFormDialog> {
  // =========================================================
  // RASABAVARCHI THEME
  // =========================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);
  static const Color _lightTeal = Color(0xFFE8F3F1);

  late final TextEditingController _commentController;

  late int _selectedRating;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _selectedRating = widget.initialRating.clamp(1, 5);

    _commentController = TextEditingController(text: widget.initialComment);
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =========================================================
  // STAR SELECTOR
  // =========================================================

  Widget _starSelector() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final starNumber = index + 1;
          final isSelected = starNumber <= _selectedRating;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRating = starNumber;
              });
            },
            child: AnimatedScale(
              scale: isSelected ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                size: 38,
                color: _yellow,
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========================================================
  // COMMENT FIELD
  // =========================================================

  Widget _commentField() {
    return TextFormField(
      controller: _commentController,
      maxLines: 5,
      maxLength: 2000,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(color: _darkTeal, fontSize: 15.5, height: 1.4),
      decoration: InputDecoration(
        hintText: 'Share your experience...',
        hintStyle: const TextStyle(color: _secondaryText, fontSize: 15.5),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(color: _secondaryText, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _teal, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please write a comment.';
        }

        return null;
      },
    );
  }

  // =========================================================
  // SAVE
  // =========================================================

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ReviewFormResult(
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // HEADER
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: _darkTeal,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        splashRadius: 22,
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // RATING TITLE
                  // =================================================
                  const Text(
                    'How would you rate this recipe?',
                    style: TextStyle(
                      color: _darkTeal,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // STARS
                  // =================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _lightTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _starSelector(),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // COMMENT
                  // =================================================
                  _commentField(),

                  const SizedBox(height: 18),

                  // =================================================
                  // ACTIONS
                  // =================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 19),
                              const SizedBox(width: 7),
                              Text(
                                widget.buttonText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
