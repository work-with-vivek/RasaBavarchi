import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/models/community_post_model.dart';
import '../providers/community_provider.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  static const Color _secondaryText = Color(0xFF77736A);

  static const Color _heart = Color(0xFFB04A3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Community',
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
              color: _teal,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  context.push('/community/create');
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.add_rounded, size: 24, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _teal,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(communityPostsProvider);
          await ref.read(communityPostsProvider.future);
        },
        child: postsAsync.when(
          loading: () => const _CommunityLoading(),

          error: (error, stackTrace) => _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(communityPostsProvider);
            },
          ),

          data: (posts) {
            if (posts.isEmpty) {
              return const _EmptyCommunityView();
            }

            final currentUserId = currentUserAsync.valueOrNull?.id;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                final isOwnPost =
                    currentUserId != null && post.author.id == currentUserId;

                return CommunityPostCard(
                  post: post,
                  isOwnPost: isOwnPost,
                  onTap: () {
                    context.push('/community/posts/${post.id}');
                  },
                  onLike: () {
                    _toggleLike(ref, post);
                  },
                  onDelete: () {
                    _confirmDeletePost(context, ref, post);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // =============================================================
  // LIKE / UNLIKE
  // =============================================================

  Future<void> _toggleLike(WidgetRef ref, CommunityPostModel post) async {
    final notifier = ref.read(communityNotifierProvider.notifier);

    if (post.isLiked) {
      await notifier.unlikePost(post.id);
    } else {
      await notifier.likePost(post.id);
    }
  }

  // =============================================================
  // DELETE POST
  // =============================================================

  Future<void> _confirmDeletePost(
    BuildContext context,
    WidgetRef ref,
    CommunityPostModel post,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Delete post?',
            style: TextStyle(color: _darkTeal, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This post will be permanently deleted.',
            style: TextStyle(color: _secondaryText, height: 1.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _heart,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(communityNotifierProvider.notifier).deletePost(post.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _darkTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Post deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _heart,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text('Unable to delete post: ${_cleanError(error)}'),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}

// =============================================================
// COMMUNITY POST CARD
// =============================================================

class CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final bool isOwnPost;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.isOwnPost,
    required this.onTap,
    required this.onLike,
    required this.onDelete,
  });

  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorRow(post: post, isOwnPost: isOwnPost, onDelete: onDelete),

              const SizedBox(height: 13),

              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: Color(0xFF35312E),
                ),
              ),

              if (post.recipe != null) ...[
                const SizedBox(height: 13),
                _RecipeAttachment(recipe: post.recipe!),
              ],

              const SizedBox(height: 10),

              _PostActions(post: post, onLike: onLike),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// AUTHOR ROW
// =============================================================

class _AuthorRow extends StatelessWidget {
  final CommunityPostModel post;
  final bool isOwnPost;
  final VoidCallback onDelete;

  const _AuthorRow({
    required this.post,
    required this.isOwnPost,
    required this.onDelete,
  });

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _cream = Color(0xFFFDF8ED);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _cream,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              post.author.username.isNotEmpty
                  ? post.author.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _teal,
              ),
            ),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _darkTeal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDate(post.createdAt),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF99928A),
                ),
              ),
            ],
          ),
        ),

        if (isOwnPost)
          PopupMenuButton<String>(
            tooltip: 'Post options',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF77736A),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFB04A3A),
                      ),
                      SizedBox(width: 12),
                      Text('Delete post'),
                    ],
                  ),
                ),
              ];
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }
}

// =============================================================
// POST ACTIONS
// =============================================================

class _PostActions extends StatelessWidget {
  const _PostActions({required this.post, required this.onLike});

  final CommunityPostModel post;
  final VoidCallback onLike;

  static const Color _teal = Color(0xFF00695C);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _heart = Color(0xFFB04A3A);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onLike,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Row(
                children: [
                  Icon(
                    post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 21,
                    color: post.isLiked ? _heart : _secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: _secondaryText,
        ),
        const SizedBox(width: 5),
        Text(
          '${post.commentCount}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _secondaryText,
          ),
        ),

        const Spacer(),

        Container(
          width: 34,
          height: 3,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 8),

        const Icon(Icons.people_outline_rounded, size: 17, color: _teal),
      ],
    );
  }
}

// =============================================================
// RECIPE ATTACHMENT
// =============================================================

class _RecipeAttachment extends StatelessWidget {
  final CommunityRecipeModel recipe;

  const _RecipeAttachment({required this.recipe});

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    final visualPath = RecipeVisualMapper.getVisual(recipeName: recipe.title);

    return Container(
      decoration: BoxDecoration(
        color: _cream,
        border: Border.all(color: _border, width: 0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
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
                          size: 36,
                          color: _teal,
                        ),
                      );
                    },
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 20,
                      color: _teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: _darkTeal,
                        ),
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
  }
}

// =============================================================
// EMPTY COMMUNITY
// =============================================================

class _EmptyCommunityView extends StatelessWidget {
  const _EmptyCommunityView();

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      Icons.people_outline_rounded,
                      size: 52,
                      color: _teal,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'No Community Posts Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkTeal,
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'Be the first to share something '
                    'delicious with the community!',
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
          ),
        ),
      ],
    );
  }
}

// =============================================================
// LOADING
// =============================================================

class _CommunityLoading extends StatelessWidget {
  const _CommunityLoading();

  static const Color _teal = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: _teal));
  }
}

// =============================================================
// ERROR
// =============================================================

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _teal.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 40,
                      color: _teal,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Unable to Load Community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: _darkTeal,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ],
    );
  }
}
