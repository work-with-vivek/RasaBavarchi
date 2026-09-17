import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../../recipes/data/models/recipe_model.dart';
import '../../../recipes/presentation/providers/recipe_provider.dart';

class RecipePicker extends ConsumerStatefulWidget {
  final String? selectedRecipeId;
  final ValueChanged<RecipeModel?> onRecipeSelected;

  const RecipePicker({
    super.key,
    this.selectedRecipeId,
    required this.onRecipeSelected,
  });

  @override
  ConsumerState<RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends ConsumerState<RecipePicker> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  String? _selectedRecipeId;

  AsyncValue<List<RecipeModel>> _recipesState = const AsyncLoading();

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  void initState() {
    super.initState();

    _selectedRecipeId = widget.selectedRecipeId;

    Future.microtask(_loadRecipes);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // LOAD RECIPES
  // =============================================================

  Future<void> _loadRecipes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _recipesState = const AsyncLoading();
    });

    try {
      final recipes = await ref
          .read(getRecipesUseCaseProvider)
          .call(page: 1, pageSize: 10);

      if (!mounted) {
        return;
      }

      setState(() {
        _recipesState = AsyncData(recipes);
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recipesState = AsyncError(error, stackTrace);
      });
    }
  }

  // =============================================================
  // SEARCH
  // =============================================================

  void _search(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 300), _loadRecipes);

      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchRecipes(query),
    );
  }

  Future<void> _searchRecipes(String query) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _recipesState = const AsyncLoading();
    });

    try {
      final recipes = await ref
          .read(searchRecipesUseCaseProvider)
          .call(title: query, page: 1, pageSize: 10);

      if (!mounted) {
        return;
      }

      setState(() {
        _recipesState = AsyncData(recipes);
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recipesState = AsyncError(error, stackTrace);
      });
    }
  }

  // =============================================================
  // SELECTION
  // =============================================================

  void _selectRecipe(RecipeModel recipe) {
    setState(() {
      _selectedRecipeId = recipe.id;
    });

    widget.onRecipeSelected(recipe);
  }

  void _clearSelection() {
    setState(() {
      _selectedRecipeId = null;
    });

    widget.onRecipeSelected(null);
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================================================
        // SEARCH FIELD
        // =========================================================

        TextField(
          controller: _searchController,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          cursorColor: _teal,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF35312E)),
          decoration: InputDecoration(
            hintText: 'Search recipes...',
            hintStyle: const TextStyle(color: _secondaryText, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _teal,
              size: 23,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();

                      setState(() {});

                      _loadRecipes();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _secondaryText,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
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
          ),
        ),

        const SizedBox(height: 12),

        // =========================================================
        // RESULTS
        // =========================================================
        _buildRecipeResults(),

        if (_selectedRecipeId != null) ...[
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearSelection,
              style: TextButton.styleFrom(
                foregroundColor: _secondaryText,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.close_rounded, size: 17),
              label: const Text(
                'Remove attached recipe',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecipeResults() {
    return _recipesState.when(
      loading: () {
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator(color: _teal)),
        );
      },

      error: (error, stackTrace) {
        return SizedBox(
          height: 210,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: _teal,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Unable to load recipes.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _darkTeal,
                  ),
                ),

                const SizedBox(height: 4),

                TextButton(
                  onPressed: _loadRecipes,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: _teal, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },

      data: (recipes) {
        if (recipes.isEmpty) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 38, color: _teal),
                  SizedBox(height: 9),
                  Text(
                    'No recipes found.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkTeal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              final isSelected = recipe.id == _selectedRecipeId;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == recipes.length - 1 ? 0 : 10,
                ),
                child: _RecipePickerCard(
                  recipe: recipe,
                  isSelected: isSelected,
                  onTap: () => _selectRecipe(recipe),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================
// RECIPE PICKER CARD
// =============================================================

class _RecipePickerCard extends StatelessWidget {
  final RecipeModel recipe;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipePickerCard({
    required this.recipe,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  static const Color _border = Color(0xFFE5D8C8);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final visualPath = RecipeVisualMapper.getVisual(
      recipeName: recipe.title,
      category: recipe.category.name,
      foodType: recipe.foodType,
    );

    return SizedBox(
      width: 190,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: isSelected ? 3 : 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? _teal : _border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // LOCAL RECIPE VISUAL
                  // =================================================

                  SizedBox(
                    height: 140,
                    width: double.infinity,
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
                                  size: 40,
                                  color: _teal,
                                ),
                              );
                            },
                      ),
                    ),
                  ),

                  // =================================================
                  // RECIPE TITLE
                  // =================================================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: _darkTeal,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

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

              // =====================================================
              // SELECTED INDICATOR
              // =====================================================
              if (isSelected)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: Colors.white,
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
