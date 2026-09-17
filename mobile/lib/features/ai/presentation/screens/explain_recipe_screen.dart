import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/widgets/food_watermark_background.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_request.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_response.dart';
import 'package:mobile/features/ai/presentation/providers/ai_provider.dart';

class ExplainRecipeScreen extends ConsumerStatefulWidget {
  const ExplainRecipeScreen({super.key});

  @override
  ConsumerState<ExplainRecipeScreen> createState() =>
      _ExplainRecipeScreenState();
}

class _ExplainRecipeScreenState extends ConsumerState<ExplainRecipeScreen> {
  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  final TextEditingController _questionController = TextEditingController();

  bool _isLoading = false;
  ExplainRecipeResponse? _response;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // =============================================================
  // ASK RASABAVARCHI
  // =============================================================

  Future<void> _askRasaBavarchi() async {
    if (_isLoading) {
      return;
    }

    final question = _questionController.text.trim();

    if (question.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question with at least 5 characters.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (question.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question must be 1000 characters or less.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final request = ExplainRecipeRequest(question: question);

      final response = await ref
          .read(aiRepositoryProvider)
          .explainRecipe(request);

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get an answer from RasaBavarchi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkTeal),
        ),
        title: const Text(
          'Ask RasaBavarchi',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FoodWatermarkBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // ===================================================
              // HEADER
              // ===================================================

              _buildHeaderCard(),

              const SizedBox(height: 24),

              // ===================================================
              // QUESTION
              // ===================================================
              const Text(
                'Your Question',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              _buildQuestionField(),

              const SizedBox(height: 22),

              // ===================================================
              // EXAMPLES
              // ===================================================
              const Text(
                'Example questions',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 11),

              _buildExampleQuestions(),

              const SizedBox(height: 26),

              // ===================================================
              // ASK BUTTON
              // ===================================================
              _buildAskButton(),

              // ===================================================
              // RESPONSE
              // ===================================================
              if (_response != null) ...[
                const SizedBox(height: 30),
                _buildResponseSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // HEADER CARD
  // =============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 21),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 31,
              color: _teal,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Ask RasaBavarchi about cooking',
            style: TextStyle(
              color: _darkTeal,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Ask about cooking techniques, ingredients, '
            'substitutions, preparation methods, or anything '
            'you want to understand better.',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // QUESTION FIELD
  // =============================================================

  Widget _buildQuestionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _questionController,
        minLines: 4,
        maxLines: 7,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(color: _darkTeal, fontSize: 15.5, height: 1.4),
        decoration: const InputDecoration(
          hintText: 'e.g. What can I use instead of butter?',
          hintStyle: TextStyle(color: _secondaryText, fontSize: 15),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 15, right: 10, bottom: 78),
            child: Icon(Icons.help_outline_rounded, color: _teal, size: 22),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(0, 17, 16, 17),
        ),
      ),
    );
  }

  // =============================================================
  // EXAMPLE QUESTIONS
  // =============================================================

  Widget _buildExampleQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionSuggestion(
          text: 'What can replace butter?',
          onTap: () {
            setState(() {
              _questionController.text = 'What can replace butter?';
              _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length),
              );
            });
          },
        ),
        const SizedBox(height: 9),
        _QuestionSuggestion(
          text: 'How do I make rice fluffy?',
          onTap: () {
            setState(() {
              _questionController.text = 'How do I make rice fluffy?';
              _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length),
              );
            });
          },
        ),
        const SizedBox(height: 9),
        _QuestionSuggestion(
          text: 'How can I reduce spice?',
          onTap: () {
            setState(() {
              _questionController.text = 'How can I reduce spice?';
              _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length),
              );
            });
          },
        ),
      ],
    );
  }

  // =============================================================
  // ASK BUTTON
  // =============================================================

  Widget _buildAskButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _askRasaBavarchi,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _darkTeal,
          disabledBackgroundColor: const Color(0xFFE3DED4),
          disabledForegroundColor: const Color(0xFF99948C),
          elevation: _isLoading ? 0 : 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(_darkTeal),
                ),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 21),
        label: Text(
          _isLoading ? 'RasaBavarchi is thinking...' : 'ASK RASABAVARCHI',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // RESPONSE
  // =============================================================

  Widget _buildResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F1EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: _teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'RasaBavarchi says',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 9,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            _response!.answer,
            style: const TextStyle(
              color: Color(0xFF3F403C),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildDisclaimer(),
      ],
    );
  }

  // =============================================================
  // DISCLAIMER
  // =============================================================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DE9B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF927100), size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'RasaBavarchi guidance may not be perfect. '
              'Use your cooking judgment and follow '
              'food-safety practices.',
              style: TextStyle(
                color: Color(0xFF735D12),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// QUESTION SUGGESTION
// =============================================================

class _QuestionSuggestion extends StatelessWidget {
  const _QuestionSuggestion({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 17,
                color: _teal,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
