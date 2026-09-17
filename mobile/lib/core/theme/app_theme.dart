import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

      scaffoldBackgroundColor: AppColors.background,

      textTheme: GoogleFonts.poppinsTextTheme(),

      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }
}
