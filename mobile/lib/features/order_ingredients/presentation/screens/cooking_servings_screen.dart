import 'package:flutter/material.dart';

import 'package:mobile/features/recipes/data/models/recipe_model.dart';
import 'package:mobile/core/widgets/food_watermark_background.dart';

class CookingServingsScreen extends StatefulWidget {
  const CookingServingsScreen({super.key, required this.recipe});

  final RecipeModel recipe;

  @override
  State<CookingServingsScreen> createState() => _CookingServingsScreenState();
}

class _CookingServingsScreenState extends State<CookingServingsScreen> {
  // =============================================================
  // RASABAVARCHI THEME
  // =============================================================

  static const Color _background = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // =============================================================
  // SERVINGS
  // =============================================================

  late int _servings;

  static const int _minServings = 1;
  static const int _maxServings = 20;

  @override
  void initState() {
    super.initState();

    final originalServings = widget.recipe.servings;

    _servings = originalServings.clamp(_minServings, _maxServings);
  }

  // =============================================================
  // INCREMENT
  // =============================================================

  void _incrementServings() {
    if (_servings >= _maxServings) {
      return;
    }

    setState(() {
      _servings++;
    });
  }

  // =============================================================
  // DECREMENT
  // =============================================================

  void _decrementServings() {
    if (_servings <= _minServings) {
      return;
    }

    setState(() {
      _servings--;
    });
  }

  // =============================================================
  // CONTINUE
  // =============================================================

  void _continue() {
    Navigator.of(context).pop(_servings);
  }

  // =============================================================
  // SERVING LABEL
  // =============================================================

  String get _servingLabel {
    return _servings == 1 ? 'person' : 'people';
  }

  String get _originalServingLabel {
    return widget.recipe.servings == 1 ? 'person' : 'people';
  }

  // =============================================================
  // HEADER ICON
  // =============================================================

  Widget _buildHeaderIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF),
        shape: BoxShape.circle,
        border: Border.all(color: _teal.withValues(alpha: 0.10), width: 1),
      ),
      child: const Icon(Icons.people_alt_rounded, size: 42, color: _teal),
    );
  }

  // =============================================================
  // SERVINGS SELECTOR
  // =============================================================

  Widget _buildServingsSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // -------------------------------------------------------
          // DECREASE
          // -------------------------------------------------------

          _buildCounterButton(
            icon: Icons.remove_rounded,
            enabled: _servings > _minServings,
            onPressed: _decrementServings,
          ),

          // -------------------------------------------------------
          // VALUE
          // -------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_servings',
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _servingLabel,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------
          // INCREASE
          // -------------------------------------------------------
          _buildCounterButton(
            icon: Icons.add_rounded,
            enabled: _servings < _maxServings,
            onPressed: _incrementServings,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // COUNTER BUTTON
  // =============================================================

  Widget _buildCounterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFE7F2EF) : const Color(0xFFF3F0EA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? _teal : const Color(0xFFB8B2A8),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // CONTINUE BUTTON
  // =============================================================

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _continue,
        style: FilledButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _darkTeal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 22),
        label: const Text(
          'Continue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
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
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _darkTeal,
            size: 27,
          ),
        ),

        title: const Text(
          'Select Servings',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // ===========================================================
      // BODY
      // ===========================================================
      body: FoodWatermarkBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  child: Column(
                    children: [
                      // -------------------------------------------------
                      // HEADER ICON
                      // -------------------------------------------------

                      _buildHeaderIcon(),

                      const SizedBox(height: 30),

                      // -------------------------------------------------
                      // MAIN HEADING
                      // -------------------------------------------------
                      const Text(
                        'How many people are\nyou cooking for?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -------------------------------------------------
                      // RECIPE NAME
                      // -------------------------------------------------
                      Text(
                        widget.recipe.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // -------------------------------------------------
                      // ORIGINAL SERVINGS
                      // -------------------------------------------------
                      Text(
                        'Serves ${widget.recipe.servings} '
                        '$_originalServingLabel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondaryText.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 58),

                      // -------------------------------------------------
                      // SERVING SELECTOR
                      // -------------------------------------------------
                      _buildServingsSelector(),

                      const SizedBox(height: 22),

                      // -------------------------------------------------
                      // INFORMATION
                      // -------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 17,
                            color: _teal.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "We'll adjust the ingredient quantities for you.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _secondaryText,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // -------------------------------------------------
                      // CURRENT SELECTION
                      // -------------------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Cooking for $_servings $_servingLabel',
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // BOTTOM BUTTON
              // =========================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
