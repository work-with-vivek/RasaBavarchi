import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/models/community_comment_model.dart';
import '../../data/models/community_post_model.dart';
import '../providers/community_provider.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  final _commentController = TextEditingController();

  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =============================================================
  // CREATE COMMENT
  // =============================================================

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      return;
    }

    if (content.length > 2000) {
      _showMessage('Comment cannot exceed 2000 characters.');
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await ref
          .read(communityNotifierProvider.notifier)
          .createComment(postId: widget.postId, content: content);

      _commentController.clear();

      if (!mounted) {
        return;
      }

      FocusScope.of(context).unfocus();

      _showMessage('Comment added.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to add comment: ${_cleanError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  // =============================================================
  // LIKE / UNLIKE
  // =============================================================

  Future<void> _toggleLike(bool isLiked) async {
    try {
      final notifier = ref.read(communityNotifierProvider.notifier);

      if (isLiked) {
        await notifier.unlikePost(widget.postId);
      } else {
        await notifier.likePost(widget.postId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to update like: ${_cleanError(error)}');
    }
  }

  // =============================================================
  // ERROR HANDLING
  // =============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Community Post')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(communityPostProvider(widget.postId));
          },
        ),
        data: (post) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityPostProvider(widget.postId));

                    await ref.read(communityPostProvider(widget.postId).future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // -------------------------------------------------
                      // AUTHOR
                      // -------------------------------------------------

                      _PostHeader(username: post.author.username),

                      const SizedBox(height: 16),

                      // -------------------------------------------------
                      // POST CONTENT
                      // -------------------------------------------------
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      // -------------------------------------------------
                      // ATTACHED RECIPE
                      // -------------------------------------------------
                      if (post.recipe != null) ...[
                        const SizedBox(height: 16),
                        _RecipeAttachment(recipe: post.recipe!),
                      ],

                      const SizedBox(height: 16),

                      // -------------------------------------------------
                      // LIKE / COMMENT COUNTS
                      // -------------------------------------------------
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _toggleLike(post.isLiked);
                            },
                            icon: Icon(
                              post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                          ),

                          Text('${post.likeCount}'),

                          const SizedBox(width: 20),

                          const Icon(Icons.comment_outlined),

                          const SizedBox(width: 6),

                          Text('${post.commentCount}'),
                        ],
                      ),

                      const Divider(height: 32),

                      // -------------------------------------------------
                      // COMMENTS TITLE
                      // -------------------------------------------------
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------------------------------------------------
                      // COMMENTS
                      // -------------------------------------------------
                      _CommentsSection(postId: widget.postId),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------
              // COMMENT COMPOSER
              // -------------------------------------------------------
              _CommentComposer(
                controller: _commentController,
                isSubmitting: _isSubmittingComment,
                onSubmit: _submitComment,
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================
// POST HEADER
// =============================================================

class _PostHeader extends StatelessWidget {
  final String username;

  const _PostHeader({required this.username});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?'),
        ),

        const SizedBox(width: 10),

        Text(
          username,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// =============================================================
// COMMENTS SECTION
// =============================================================

class _CommentsSection extends ConsumerWidget {
  final String postId;

  const _CommentsSection({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(communityCommentsProvider(postId));

    final currentUserAsync = ref.watch(currentUserProvider);

    final currentUserId = currentUserAsync.valueOrNull?.id;

    return commentsAsync.when(
      // -----------------------------------------------------------
      // LOADING
      // -----------------------------------------------------------

      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),

      // -----------------------------------------------------------
      // ERROR
      // -----------------------------------------------------------
      error: (error, stackTrace) => Column(
        children: [
          const Icon(Icons.error_outline, size: 40),

          const SizedBox(height: 8),

          const Text('Unable to load comments.', textAlign: TextAlign.center),

          TextButton(
            onPressed: () {
              ref.invalidate(communityCommentsProvider(postId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),

      // -----------------------------------------------------------
      // DATA
      // -----------------------------------------------------------
      data: (comments) {
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet.\nBe the first to comment!',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: comments
              .map(
                (comment) => _CommentCard(
                  comment: comment,
                  postId: postId,
                  isOwnComment:
                      currentUserId != null &&
                      comment.author.id == currentUserId,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// =============================================================
// COMMENT CARD
// =============================================================

class _CommentCard extends ConsumerWidget {
  final CommunityCommentModel comment;
  final String postId;
  final bool isOwnComment;

  const _CommentCard({
    required this.comment,
    required this.postId,
    required this.isOwnComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // AVATAR
            // -------------------------------------------------------

            CircleAvatar(
              radius: 18,
              child: Text(
                comment.author.username.isNotEmpty
                    ? comment.author.username[0].toUpperCase()
                    : '?',
              ),
            ),

            const SizedBox(width: 10),

            // -------------------------------------------------------
            // COMMENT CONTENT
            // -------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author.username,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(comment.content),
                ],
              ),
            ),

            // -------------------------------------------------------
            // DELETE MENU — OWN COMMENTS ONLY
            // -------------------------------------------------------
            if (isOwnComment)
              PopupMenuButton<String>(
                tooltip: 'Comment options',
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 12),
                          Text('Delete comment'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // DELETE COMMENT CONFIRMATION
  // =============================================================

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text('This comment will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref
          .read(communityNotifierProvider.notifier)
          .deleteComment(commentId: comment.id, postId: postId);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete comment: '
            '${_cleanError(error)}',
          ),
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
// COMMENT COMPOSER
// =============================================================

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // -----------------------------------------------------
              // TEXT FIELD
              // -----------------------------------------------------

              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // -----------------------------------------------------
              // SEND BUTTON
              // -----------------------------------------------------
              IconButton.filled(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// RECIPE ATTACHMENT
// =============================================================

class _RecipeAttachment extends StatelessWidget {
  final CommunityRecipeModel recipe;

  const _RecipeAttachment({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/recipe/${recipe.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // RECIPE IMAGE
            // -------------------------------------------------------

            if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
              Image.network(
                recipe.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Icon(Icons.restaurant, size: 48)),
                  );
                },
              ),

            // -------------------------------------------------------
            // RECIPE TITLE
            // -------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(Icons.chevron_right),
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
// ERROR VIEW
// =============================================================

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56),

            const SizedBox(height: 16),

            Text(
              'Unable to load post.',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
