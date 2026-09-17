import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/secure_storage_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const _AccountHeader(),

            const SizedBox(height: 28),

            // =====================================================
            // ORDERS
            // =====================================================
            const _SectionTitle(title: 'Orders'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle: 'View and track your ingredient orders',
              onTap: () {
                context.push('/orders');
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // SAVED
            // =====================================================
            const _SectionTitle(title: 'Saved'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.favorite_border_rounded,
              title: 'My Favorites',
              subtitle: 'View your saved recipes',
              iconColor: _teal,
              onTap: () {
                context.push('/favorites');
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // HEALTH & NUTRITION
            // =====================================================
            const _SectionTitle(title: 'Health & Nutrition'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.monitor_weight_outlined,
              title: 'Weight Loss',
              subtitle: 'Track your weight goal and estimated calorie needs',
              iconColor: _teal,
              onTap: () {
                context.push('/weight-loss');
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // SMART COOKING
            // =====================================================
            const _SectionTitle(title: 'Smart Cooking'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Recipe From Pantry',
              subtitle: 'Create a recipe using ingredients you already have',
              iconColor: _teal,
              onTap: () {
                context.push('/ai/generate-from-pantry');
              },
            ),

            const SizedBox(height: 12),

            _AccountOptionCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Explain Recipe',
              subtitle: 'Ask RasaBavarchi about cooking and recipe questions',
              iconColor: _teal,
              onTap: () {
                context.push('/ai/explain-recipe');
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // PANTRY
            // =====================================================
            const _SectionTitle(title: 'Pantry'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.kitchen_outlined,
              title: 'My Pantry',
              subtitle: 'View and manage your pantry ingredients',
              iconColor: _teal,
              onTap: () {
                context.push('/pantry');
              },
            ),

            const SizedBox(height: 12),

            _AccountOptionCard(
              icon: Icons.camera_alt_outlined,
              title: 'Scan Pantry',
              subtitle: 'Detect ingredients from a photo',
              iconColor: _teal,
              onTap: () {
                context.push('/pantry-scan');
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // ACCOUNT
            // =====================================================
            const _SectionTitle(title: 'Account'),
            const SizedBox(height: 10),

            _AccountOptionCard(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out from your RasaBavarchi account',
              iconColor: _teal,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // LOGOUT DIALOG
  // =============================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _darkTeal,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF77736A),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _teal, fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await SecureStorageService.clear();

                if (!context.mounted) {
                  return;
                }

                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB04A3A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// ACCOUNT HEADER
// =============================================================

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: _teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _darkTeal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your RasaBavarchi activity',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xFF77736A),
                  ),
                ),
                const SizedBox(height: 9),
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
        ],
      ),
    );
  }
}

// =============================================================
// SECTION TITLE
// =============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  static const Color _darkTeal = Color(0xFF064E46);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _darkTeal,
        letterSpacing: -0.2,
      ),
    );
  }
}

// =============================================================
// ACCOUNT OPTION CARD
// =============================================================

class _AccountOptionCard extends StatelessWidget {
  const _AccountOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = _teal,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: _border, width: 0.7),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _darkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Color(0xFF77736A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFF99928A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
