import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile/core/widgets/food_watermark_background.dart';
import 'package:mobile/features/pantry/presentation/providers/pantry_scan_api_provider.dart';
import 'package:mobile/features/pantry/presentation/screens/detected_ingredients_screen.dart';

class PantryScanScreen extends ConsumerStatefulWidget {
  const PantryScanScreen({super.key});

  @override
  ConsumerState<PantryScanScreen> createState() => _PantryScanScreenState();
}

class _PantryScanScreenState extends ConsumerState<PantryScanScreen> {
  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = image;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _chooseFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _detectIngredients() async {
    final image = _selectedImage;

    if (image == null || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ref
          .read(pantryScanRepositoryProvider)
          .scanPantry(image);

      if (!mounted) {
        return;
      }

      final ingredients = response.ingredients
          .map((ingredient) => ingredient.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _isLoading = false;
      });

      if (ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No ingredients were detected. '
              'Try another photo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetectedIngredientsScreen(ingredients: ingredients),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not detect ingredients: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkTeal),
          tooltip: 'Back',
        ),
        title: const Text(
          'Scan Pantry',
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
              const Text(
                'Scan your pantry',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of your fridge or pantry and '
                'we will identify the ingredients.',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _selectedImage == null
                    ? _ScanOptionsCard(
                        key: const ValueKey('scan-options'),
                        isLoading: _isLoading,
                        onTakePhoto: _takePhoto,
                        onGallery: _chooseFromGallery,
                      )
                    : _SelectedImageCard(
                        key: const ValueKey('selected-image'),
                        image: _selectedImage!,
                        onRemove: _removeImage,
                      ),
              ),
              const SizedBox(height: 18),
              _buildTipCard(),
              const SizedBox(height: 24),
              _buildDetectButton(),
              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                _buildAnotherPhotoButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D8C7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFE2D4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: _teal,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'For better detection, use a clear photo with '
                'good lighting and keep the ingredients visible.',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectButton() {
    final enabled = _selectedImage != null && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: enabled ? _detectIngredients : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _darkTeal,
          disabledBackgroundColor: const Color(0xFFE1DED8),
          disabledForegroundColor: const Color(0xFF9C9993),
          elevation: enabled ? 2 : 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(_darkTeal),
                ),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 21),
        label: Text(
          _isLoading ? 'Detecting Ingredients...' : 'Detect Ingredients',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAnotherPhotoButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _takePhoto,
        style: OutlinedButton.styleFrom(
          foregroundColor: _teal,
          side: const BorderSide(color: _teal, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        label: const Text(
          'Take Another Photo',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ScanOptionsCard extends StatelessWidget {
  const _ScanOptionsCard({
    super.key,
    required this.isLoading,
    required this.onTakePhoto,
    required this.onGallery,
  });

  final bool isLoading;
  final VoidCallback onTakePhoto;
  final VoidCallback onGallery;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F1EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.kitchen_outlined, size: 44, color: _teal),
          ),
          const SizedBox(height: 18),
          const Text(
            'Show us what you have',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _darkTeal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Take a picture or choose one from your gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTakePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE1DED8),
                disabledForegroundColor: const Color(0xFF9C9993),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text(
                'Take Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text(
                'Choose from Gallery',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 18),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_teal),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedImageCard extends StatelessWidget {
  const _SelectedImageCard({
    super.key,
    required this.image,
    required this.onRemove,
  });

  final XFile image;
  final VoidCallback onRemove;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Image.file(
                  File(image.path),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFF2EEE7),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 44,
                          color: _secondaryText,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Remove image',
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F1EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _teal,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pantry photo selected',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ready to detect ingredients',
                        style: TextStyle(color: _secondaryText, fontSize: 13),
                      ),
                    ],
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
