import 'package:flutter/material.dart';

import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final String difficulty;
  final double rating;
  final String? category;
  final String? foodType;
  final VoidCallback? onTap;

  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback? onFavoriteTap;

  const RecipeCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.difficulty,
    required this.rating,
    this.category,
    this.foodType,
    this.onTap,
    this.isFavorite = false,
    this.isFavoriteLoading = false,
    this.onFavoriteTap,
  });

  static const Color _teal = Color(0xFF00695C);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _cream = Color(0xFFF8F0DF);
  static const Color _text = Color(0xFF242424);
  static const Color _secondaryText = Color(0xFF66615D);
  static const Color _metaText = Color(0xFF4A4541);
  static const Color _favoriteRed = Color(0xFFB04A3A);

  @override
  Widget build(BuildContext context) {
    final visualPath = RecipeVisualMapper.getVisual(
      recipeName: title,
      category: category,
      foodType: foodType,
    );

    return Card(
      elevation: 2.5,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIllustration(visualPath),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ILLUSTRATION
  // =========================================================

  Widget _buildIllustration(String visualPath) {
    return SizedBox(
      height: 138,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: _cream,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  visualPath,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 46,
                            color: _teal,
                          ),
                        );
                      },
                ),
              ),
            ),
          ),

          // ---------------------------------------------------
          // Favorite Button
          // ---------------------------------------------------
          Positioned(
            top: 9,
            right: 9,
            child: Material(
              color: Colors.white.withValues(alpha: 0.95),
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                onTap: isFavoriteLoading ? null : onFavoriteTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: isFavoriteLoading
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _teal,
                            ),
                          )
                        : Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 21,
                            color: isFavorite ? _favoriteRed : _text,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------
          // Title
          // ---------------------------------------------------

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),

          const SizedBox(height: 5),

          // ---------------------------------------------------
          // Description
          // ---------------------------------------------------
          Expanded(
            child: Text(
              description.trim().isEmpty
                  ? 'A delicious recipe to enjoy at home.'
                  : description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: _secondaryText,
              ),
            ),
          ),

          const SizedBox(height: 7),

          // ---------------------------------------------------
          // Metadata
          // ---------------------------------------------------
          _buildMetadata(),
        ],
      ),
    );
  }

  // =========================================================
  // METADATA
  // =========================================================

  Widget _buildMetadata() {
    return Row(
      children: [
        // ---------------------------------------------------
        // Duration
        // ---------------------------------------------------

        const Icon(Icons.timer_outlined, size: 15, color: _teal),

        const SizedBox(width: 3),

        Flexible(
          child: Text(
            duration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _metaText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 6),

        // ---------------------------------------------------
        // Difficulty
        // ---------------------------------------------------
        const Icon(
          Icons.local_fire_department_outlined,
          size: 15,
          color: _teal,
        ),

        const SizedBox(width: 3),

        Flexible(
          child: Text(
            difficulty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _metaText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 5),

        // ---------------------------------------------------
        // Rating
        // ---------------------------------------------------
        const Icon(Icons.star_rounded, size: 17, color: _yellow),

        const SizedBox(width: 2),

        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '—',
          style: const TextStyle(
            fontSize: 11,
            color: _metaText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
