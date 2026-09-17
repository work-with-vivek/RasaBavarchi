import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/food_watermark_background.dart';
import '../providers/weight_loss_provider.dart';

class WeightLossProfileScreen extends ConsumerStatefulWidget {
  const WeightLossProfileScreen({super.key});

  @override
  ConsumerState<WeightLossProfileScreen> createState() =>
      _WeightLossProfileScreenState();
}

class _WeightLossProfileScreenState
    extends ConsumerState<WeightLossProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';
  bool _isSaving = false;

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfile();
    });
  }

  Future<void> _loadExistingProfile() async {
    final profile = await ref.read(weightLossProfileProvider.future);

    if (!mounted || profile == null) {
      return;
    }

    setState(() {
      _ageController.text = profile.age.toString();
      _heightController.text = profile.heightCm.toString();
      _weightController.text = profile.weightKg.toString();
      _goalWeightController.text = profile.goalWeightKg.toString();
      _gender = profile.gender;
      _activityLevel = profile.activityLevel;
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(weightLossRepositoryProvider);

      await repository.saveProfile(
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        heightCm: double.parse(_heightController.text.trim()),
        weightKg: double.parse(_weightController.text.trim()),
        activityLevel: _activityLevel,
        goalWeightKg: double.parse(_goalWeightController.text.trim()),
      );

      ref.invalidate(weightLossProfileProvider);
      ref.invalidate(weightLossCalculationProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight loss profile saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());

    if (age == null || age < 13 || age > 100) {
      return 'Enter an age between 13 and 100';
    }

    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Height is required';
    }

    final height = double.tryParse(value.trim());

    if (height == null || height <= 50 || height > 300) {
      return 'Enter a valid height';
    }

    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }

    final weight = double.tryParse(value.trim());

    if (weight == null || weight <= 20 || weight > 500) {
      return 'Enter a valid weight';
    }

    return null;
  }

  String? _validateGoalWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Goal weight is required';
    }

    final goalWeight = double.tryParse(value.trim());

    if (goalWeight == null || goalWeight <= 20 || goalWeight > 500) {
      return 'Enter a valid goal weight';
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      prefixIcon: Icon(icon, color: _teal, size: 21),
      labelStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _teal,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      suffixStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB04A3A), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB04A3A), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal, size: 21),
      labelStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _teal,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(weightLossProfileProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _darkTeal),
          tooltip: 'Back',
        ),
        title: const Text(
          'Weight Loss Profile',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _teal)),
        error: (error, stackTrace) => _buildForm(),
        data: (_) => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return FoodWatermarkBackground(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              const Text(
                'Your Weight Loss Profile',
                style: TextStyle(
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: _darkTeal,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your basic details so RasaBavarchi can calculate '
                'your BMI, estimated energy needs, and weight-loss target.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: _secondaryText,
                ),
              ),
              const SizedBox(height: 13),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),

              // Age
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  suffixText: 'years',
                ),
                validator: _validateAge,
              ),
              const SizedBox(height: 13),

              // Gender
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _dropdownDecoration(
                  label: 'Gender',
                  icon: Icons.person_outline_rounded,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _secondaryText,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 13),

              // Height
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Height',
                  icon: Icons.height_rounded,
                  suffixText: 'cm',
                ),
                validator: _validateHeight,
              ),
              const SizedBox(height: 13),

              // Current Weight
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Current Weight',
                  icon: Icons.monitor_weight_outlined,
                  suffixText: 'kg',
                ),
                validator: _validateWeight,
              ),
              const SizedBox(height: 13),

              // Activity Level
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: _dropdownDecoration(
                  label: 'Activity Level',
                  icon: Icons.directions_run_rounded,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _secondaryText,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('Sedentary'),
                  ),
                  DropdownMenuItem(
                    value: 'light',
                    child: Text('Lightly Active'),
                  ),
                  DropdownMenuItem(
                    value: 'moderate',
                    child: Text('Moderately Active'),
                  ),
                  DropdownMenuItem(value: 'active', child: Text('Very Active')),
                  DropdownMenuItem(
                    value: 'very_active',
                    child: Text('Extremely Active'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activityLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 13),

              // Goal Weight
              TextFormField(
                controller: _goalWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(
                  label: 'Goal Weight',
                  icon: Icons.flag_outlined,
                  suffixText: 'kg',
                ),
                validator: _validateGoalWeight,
                onFieldSubmitted: (_) {
                  if (!_isSaving) {
                    _saveProfile();
                  }
                },
              ),

              const SizedBox(height: 21),

              // Save button
              SizedBox(
                height: 53,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    disabledBackgroundColor: _teal.withValues(alpha: 0.55),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'The calculations are estimates for informational purposes '
                'and are not medical advice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
