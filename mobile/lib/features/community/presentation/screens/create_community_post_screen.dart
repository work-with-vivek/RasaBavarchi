import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../../recipes/data/models/recipe_model.dart';
import '../providers/community_provider.dart';
import '../widgets/recipe_picker.dart';

class CreateCommunityPostScreen extends ConsumerStatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  ConsumerState<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends ConsumerState<CreateCommunityPostScreen> {
  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);
  static const Color _heart = Color(0xFFB04A3A);

  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  bool _isSubmitting = false;

  RecipeModel? _selectedRecipe;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // =============================================================
  // CREATE POST
  // =============================================================

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final content = _contentController.text.trim();

      await ref
          .read(communityNotifierProvider.notifier)
          .createPost(content: content, recipeId: _selectedRecipe?.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _darkTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Post created successfully.'),
        ),
      );

      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _heart,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text('Unable to create post: ${_cleanError(error)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _darkTeal),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              // ===================================================
              // INTRO
              // ===================================================

              const Text(
                'Share with the community',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: _darkTeal,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Share your cooking experience, tips, ideas, '
                'or recipes.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _secondaryText,
                ),
              ),

              const SizedBox(height: 22),

              // ===================================================
              // POST CONTENT
              // ===================================================
              const Text(
                'Your Post',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _darkTeal,
                ),
              ),

              const SizedBox(height: 9),

              TextFormField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 5000,
                textInputAction: TextInputAction.newline,
                cursorColor: _teal,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: Color(0xFF35312E),
                ),
                decoration: InputDecoration(
                  hintText: 'What would you like to share?',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8B837B),
                    fontSize: 14,
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
                  counterStyle: const TextStyle(
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _teal, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _heart),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _heart, width: 1.5),
                  ),
                ),
                validator: (value) {
                  final content = value?.trim() ?? '';

                  if (content.isEmpty) {
                    return 'Post content cannot be empty.';
                  }

                  if (content.length > 5000) {
                    return 'Post cannot exceed 5000 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 23),

              // ===================================================
              // RECIPE PICKER
              // ===================================================
              const Text(
                'Attach Recipe',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _darkTeal,
                ),
              ),

              const SizedBox(height: 9),

              RecipePicker(
                selectedRecipeId: _selectedRecipe?.id,
                onRecipeSelected: (recipe) {
                  setState(() {
                    _selectedRecipe = recipe;
                  });
                },
              ),

              // ===================================================
              // SELECTED RECIPE
              // ===================================================
              if (_selectedRecipe != null) ...[
                const SizedBox(height: 18),
                _SelectedRecipePreview(recipe: _selectedRecipe!),
              ],

              const SizedBox(height: 28),

              // ===================================================
              // CREATE BUTTON
              // ===================================================
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _createPost,
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _teal.withValues(alpha: 0.45),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Posting...' : 'Create Post',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SELECTED RECIPE PREVIEW
// =============================================================

class _SelectedRecipePreview extends StatelessWidget {
  final RecipeModel recipe;

  const _SelectedRecipePreview({required this.recipe});

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final visualPath = RecipeVisualMapper.getVisual(
      recipeName: recipe.title,
      category: recipe.category.name,
      foodType: recipe.foodType,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _teal.withValues(alpha: 0.35), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // =======================================================
          // LOCAL RECIPE VISUAL
          // =======================================================

          SizedBox(
            width: 100,
            height: 100,
            child: Container(
              color: _cream,
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
          ),

          // =======================================================
          // RECIPE INFORMATION
          // =======================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: _teal,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Recipe attached',
                          style: TextStyle(
                            fontSize: 12,
                            color: _teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _darkTeal,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Container(
                    width: 34,
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
        ],
      ),
    );
  }
}
