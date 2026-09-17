import 'package:flutter/material.dart';

import '../../data/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  final ReviewModel review;

  final bool isOwner;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------
          // User Row
          // ---------------------------------------------------

          Row(
            children: [
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  "User ${review.userId.length >= 8 ? review.userId.substring(0, 8) : review.userId}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ------------------------------------------------
              // Owner Menu
              // ------------------------------------------------
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      onEdit?.call();
                    }

                    if (value == "delete") {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------------------------------------------------
          // Rating
          // ---------------------------------------------------
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber,
                );
              }),

              const SizedBox(width: 8),

              Text(
                "${review.rating}/5",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------
          // Comment
          // ---------------------------------------------------
          Text(review.comment ?? "", style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),

          // ---------------------------------------------------
          // Date
          // ---------------------------------------------------
          Text(
            _formatDate(review.createdAt ?? DateTime.now()),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return "${localDate.day.toString().padLeft(2, '0')}/"
        "${localDate.month.toString().padLeft(2, '0')}/"
        "${localDate.year}";
  }
}
