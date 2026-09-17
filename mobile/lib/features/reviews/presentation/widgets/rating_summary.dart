import 'package:flutter/material.dart';

import '../../data/models/recipe_rating_model.dart';

class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.rating});

  final RecipeRatingModel rating;

  @override
  Widget build(BuildContext context) {
    final average = rating.averageRating;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // ---------------------------------------------------
          // Average Rating
          // ---------------------------------------------------

          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < average.round() ? Icons.star : Icons.star_border,
                    size: 20,
                    color: Colors.amber,
                  );
                }),
              ),

              const SizedBox(height: 4),

              Text(
                "${rating.totalReviews} reviews",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // ---------------------------------------------------
          // Rating Description
          // ---------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Community Rating",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  rating.totalReviews == 0
                      ? "Be the first to review this recipe."
                      : "Based on ratings from the RasaBavarchi community.",
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
