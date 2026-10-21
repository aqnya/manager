import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _fontFamily = 'sans-serif';

  static ThemeData build(ColorScheme scheme) {
    final textTheme = _buildTextTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainer,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = Typography.material2021(platform: TargetPlatform.android).black
        .apply(
          fontFamily: _fontFamily,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        height: 1.27,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}
