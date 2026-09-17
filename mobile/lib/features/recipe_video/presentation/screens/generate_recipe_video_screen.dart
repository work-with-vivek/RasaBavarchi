import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_request.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_response.dart';
import 'package:mobile/features/recipe_video/presentation/providers/recipe_video_provider.dart';

import 'recipe_video_player_screen.dart';

class GenerateRecipeVideoScreen extends ConsumerStatefulWidget {
  const GenerateRecipeVideoScreen({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
  });

  final String recipeId;
  final String recipeTitle;

  @override
  ConsumerState<GenerateRecipeVideoScreen> createState() =>
      _GenerateRecipeVideoScreenState();
}

class _GenerateRecipeVideoScreenState
    extends ConsumerState<GenerateRecipeVideoScreen> {
  String _selectedLanguage = 'en';
  String _selectedVoice = 'female';

  bool _isGenerating = false;

  String? _errorMessage;

  RecipeVideoResponse? _result;

  // =========================================================
  // BUILD FULL VIDEO URL
  // =========================================================

  String _buildVideoUrl(String videoUrl) {
    var value = videoUrl.trim();

    if (value.isEmpty) {
      return value;
    }

    // Convert Windows path separators to URL separators.
    value = value.replaceAll(r'\', '/');

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final baseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    final path = value.startsWith('/') ? value : '/$value';

    return '$baseUrl$path';
  }
  // =========================================================
  // GENERATE VIDEO
  // =========================================================

  Future<void> _generateVideo() async {
    if (_isGenerating) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final repository = ref.read(recipeVideoRepositoryProvider);

      final result = await repository.generateVideo(
        recipeId: widget.recipeId,
        request: RecipeVideoRequest(
          language: _selectedLanguage,
          voice: _selectedVoice,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // =========================================================
  // OPEN VIDEO PLAYER
  // =========================================================

  void _openVideoPlayer() {
    final result = _result;

    if (result == null) {
      return;
    }

    final rawUrl = result.videoUrl;

    if (rawUrl == null || rawUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL is not available.')),
      );
      return;
    }

    final videoUrl = _buildVideoUrl(rawUrl);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeVideoPlayerScreen(
          videoUrl: videoUrl,
          recipeTitle: widget.recipeTitle,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Recipe Video')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.recipeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate an AI-powered explanation video '
                  'for this recipe.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // =====================================================
          // LANGUAGE
          // =====================================================
          Text(
            'Language',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.language),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('Hindi')),
            ],
            onChanged: _isGenerating
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedLanguage = value;
                    });
                  },
          ),

          const SizedBox(height: 20),

          // =====================================================
          // VOICE
          // =====================================================
          Text(
            'Voice',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedVoice,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.record_voice_over_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'male', child: Text('Male')),
            ],
            onChanged: _isGenerating
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedVoice = value;
                    });
                  },
          ),

          const SizedBox(height: 28),

          // =====================================================
          // GENERATE BUTTON
          // =====================================================
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateVideo,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.movie_creation_outlined),
              label: Text(
                _isGenerating ? 'Generating Video...' : 'GENERATE VIDEO',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =====================================================
          // ERROR
          // =====================================================
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // =====================================================
          // RESULT
          // =====================================================
          if (_result != null) ...[
            const SizedBox(height: 20),
            _VideoResultCard(result: _result!, onPlay: _openVideoPlayer),
          ],

          const SizedBox(height: 20),

          // =====================================================
          // AI NOTICE
          // =====================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI-generated video content may contain '
                    'mistakes. Check the recipe instructions '
                    'before cooking.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// VIDEO RESULT CARD
// =============================================================

class _VideoResultCard extends StatelessWidget {
  const _VideoResultCard({required this.result, required this.onPlay});

  final RecipeVideoResponse result;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final isCompleted = result.isCompleted;

    final hasVideo =
        result.videoUrl != null && result.videoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.info_outline,
                color: isCompleted
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCompleted ? 'Video Generated' : 'Video Status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(result.message, style: const TextStyle(height: 1.4)),

          const SizedBox(height: 12),

          Text(
            'Status: ${result.status}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          if (result.duration != null) ...[
            const SizedBox(height: 6),
            Text('Duration: ${result.duration} seconds'),
          ],

          if (hasVideo) ...[
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text(
                  'PLAY RECIPE VIDEO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Video URL',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),

            SelectableText(result.videoUrl!),
          ],
        ],
      ),
    );
  }
}
