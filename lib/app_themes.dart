// lib/app_themes.dart

import 'package:flutter/material.dart';
import 'design_system/modern_theme.dart';

enum AppThemePalette {
  modernPremium,
  defaultOrange,
  material3Dynamic,
  oceanBlue,
  forestGreen,
  sunsetGlow,
  mintyFresh,
  lavenderDream,
  graphiteNight,
  aiStudio,
}

String appThemePaletteToString(AppThemePalette palette) {
  return palette.toString().split('.').last;
}

AppThemePalette stringToAppThemePalette(String? paletteString) {
  if (paletteString == null) return AppThemePalette.modernPremium;
  try {
    return AppThemePalette.values.firstWhere(
      (e) => e.toString().split('.').last == paletteString,
    );
  } catch (e) {
    return AppThemePalette.modernPremium;
  }
}

class AppThemes {
  // DEĞİŞİKLİK: Arka plan rengi açık gri yapıldı.
  static const Color _lightScaffoldBackground = Color(0xFFF5F5F5);
  static const Color _darkScaffoldBackground = Color(0xFF000000);

  static ThemeData _buildThemeFromColorScheme(ColorScheme colorScheme, {
    String appBarTitleFontFamily = 'Roboto', 
    double appBarTitleFontSize = 22,
    bool useSpecialAppBar = false, 
    Color? appBarSolidColor, 
    Color? appBarForegroundColorOverride,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;
    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);

    TextTheme baseTextTheme = isLight ? Typography.blackMountainView : Typography.whiteMountainView;
    if (appBarTitleFontFamily != 'Roboto' && appBarTitleFontFamily.isNotEmpty) {
        baseTextTheme = baseTextTheme.apply(fontFamily: appBarTitleFontFamily);
    }

    TextTheme textTheme = baseTextTheme.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.87)),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: colorScheme.primary.withOpacity(isLight ? 0.87 : 0.95), fontWeight: FontWeight.w600),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold), 
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold), 
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(isLight ? 0.7 : 0.8), fontWeight: FontWeight.w500),
    );
    
    Color finalAppBarBackgroundColor;
    Color finalAppBarForegroundColor; 
    Color finalAppBarTitleColor;    

    if (useSpecialAppBar) { 
        finalAppBarBackgroundColor = Colors.transparent; 
        finalAppBarForegroundColor = isLight ? colorScheme.onSurface : colorScheme.onPrimaryContainer;
        finalAppBarTitleColor = isLight ? colorScheme.onSurface : colorScheme.onPrimaryContainer;
    } else {
        finalAppBarBackgroundColor = appBarSolidColor ?? (isLight ? colorScheme.primary : colorScheme.surfaceContainerHighest); 
        finalAppBarForegroundColor = appBarForegroundColorOverride ?? (isLight ? colorScheme.onPrimary : colorScheme.onSurfaceVariant);
        finalAppBarTitleColor = appBarForegroundColorOverride ?? (isLight ? colorScheme.onPrimary : colorScheme.onSurface); 
    }
    
    // DEĞİŞİKLİK: Kart rengi yeni açık gri arka plana göre ayarlandı.
    // Artık beyaz olacaklar.
    Color cardBackgroundColor = isLight 
        ? Colors.white
        : Color.alphaBlend(colorScheme.primary.withOpacity(0.08), colorScheme.surface); 

    Color inputFillColor = isLight
        ? colorScheme.surfaceContainerHighest.withOpacity(0.4) 
        : colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: isLight ? _lightScaffoldBackground : _darkScaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: finalAppBarBackgroundColor,
        foregroundColor: finalAppBarForegroundColor, 
        elevation: useSpecialAppBar ? 0 : (isLight ? 0.5 : 2), 
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.bold,
            color: finalAppBarTitleColor, 
            fontFamily: appBarTitleFontFamily.isNotEmpty ? appBarTitleFontFamily : null, 
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: inputFillColor,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.9)),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
        prefixIconColor: colorScheme.primary.withOpacity(isLight ? 0.7 : 0.8), 
        suffixIconColor: colorScheme.primary.withOpacity(isLight ? 0.7 : 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: colorScheme.primary, width: 2.0)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: colorScheme.error, width: 2.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: isLight ? 0.3 : 0.8, 
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), 
        surfaceTintColor: Colors.transparent, 
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
          elevation: 2,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, letterSpacing: 0.5),
        )
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, letterSpacing: 0.5),
        )
      ),
      bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: isLight ? Color.lerp(colorScheme.surface, Colors.white, 0.3) : Color.lerp(colorScheme.surface, Colors.black, 0.15), 
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
        elevation: 2, 
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: baseTheme.dividerTheme.copyWith(
        color: colorScheme.outlineVariant.withOpacity(isLight ? 0.3 : 0.4), 
        thickness: 0.5
      ),
iconTheme: baseTheme.iconTheme.copyWith(
  color: isLight 
    ? colorScheme.primary.withOpacity(0.8) 
    : colorScheme.onPrimary.withOpacity(0.95),
  size: isLight ? 24.0 : 28.0,
  fill: isLight ? 0.7 : 0.85,
  opacity: isLight ? 0.9 : 1.0,
  weight: isLight ? 400 : 500,
),
      listTileTheme: baseTheme.listTileTheme.copyWith( 
        iconColor: colorScheme.primary.withOpacity(isLight ? 0.8 : 0.9),
      ),
      dialogTheme: baseTheme.dialogTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLowest, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), 
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.primary),
      )
    );
  }

  // --- Geri kalan tema tanımlamaları aynı ---
  static final ColorScheme _defaultOrangeLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.orange.shade700, brightness: Brightness.light,).copyWith(surface: Colors.white, surfaceContainerLowest: const Color(0xFFFDFCFB),surfaceContainerHighest: Colors.orange.shade100,primaryContainer: Colors.orange.shade200, );
  static ThemeData get defaultOrangeLight => _buildThemeFromColorScheme(_defaultOrangeLightColorScheme,appBarSolidColor: Colors.orange.shade700,appBarForegroundColorOverride: Colors.white,appBarTitleFontSize: 24,);
  static final ColorScheme _defaultOrangeDarkColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepOrange.shade600, brightness: Brightness.dark,).copyWith(surface: const Color(0xFF1E1E1E), surfaceContainerLowest: const Color(0xFF1A1A1A),surfaceContainerHighest: Colors.deepOrange.shade900.withOpacity(0.8),primaryContainer: Colors.deepOrange.shade800,);
  static ThemeData get defaultOrangeDark => _buildThemeFromColorScheme(_defaultOrangeDarkColorScheme,appBarSolidColor: Colors.deepOrange.shade800, appBarForegroundColorOverride: Colors.white,appBarTitleFontSize: 24,);
  static ThemeData get material3DynamicLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light).copyWith(surface: _lightScaffoldBackground),appBarTitleFontSize: 24);
  static ThemeData get material3DynamicDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark).copyWith(surface: _darkScaffoldBackground),appBarTitleFontSize: 24);
  static final Color _oceanSeedLight = const Color(0xFF0077B6);
  static ThemeData get oceanBlueLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _oceanSeedLight, secondary: const Color(0xFF00B4D8), brightness: Brightness.light).copyWith(surface: const Color(0xFFF0F8FF)),appBarSolidColor: _oceanSeedLight, appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _oceanSeedDark = const Color(0xFF47A5D8); 
  static ThemeData get oceanBlueDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _oceanSeedDark, secondary: const Color(0xFF7AD8F0), brightness: Brightness.dark).copyWith(surface: const Color(0xFF011F3A)),appBarSolidColor: const Color(0xFF023E8A), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _forestSeedLight = const Color(0xFF2d6a4f);
  static ThemeData get forestGreenLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _forestSeedLight, secondary: const Color(0xFF74c69d), brightness: Brightness.light).copyWith(surface: const Color(0xFFF0FFF0)),appBarSolidColor: _forestSeedLight, appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _forestSeedDark = const Color(0xFF52b788);
  static ThemeData get forestGreenDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _forestSeedDark, secondary: const Color(0xFF95d5b2), brightness: Brightness.dark).copyWith(surface: const Color(0xFF0F2A1E)),appBarSolidColor: const Color(0xFF1b4332), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _sunsetSeedLight = const Color(0xFFFF6B6B);
  static ThemeData get sunsetGlowLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _sunsetSeedLight, secondary: const Color(0xFFFFD166), brightness: Brightness.light).copyWith(surface: const Color(0xFFFFF5E1)),appBarSolidColor: _sunsetSeedLight, appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _sunsetSeedDark = const Color(0xFFFFA07A); 
  static ThemeData get sunsetGlowDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _sunsetSeedDark, secondary: const Color(0xFFFFE4B5), brightness: Brightness.dark).copyWith(surface: const Color(0xFF3D1B0B)),appBarSolidColor: const Color(0xFFD2691E), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _mintySeedLight = const Color(0xFF50C878); 
  static ThemeData get mintyFreshLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _mintySeedLight, secondary: const Color(0xFFA0E6C8), brightness: Brightness.light).copyWith(surface: const Color(0xFFF5FFFA)),appBarSolidColor: _mintySeedLight, appBarForegroundColorOverride: Colors.black87, appBarTitleFontSize: 24);
  static final Color _mintySeedDark = const Color(0xFF7FFFD4); 
  static ThemeData get mintyFreshDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _mintySeedDark, secondary: const Color(0xFFB2DFDB), brightness: Brightness.dark).copyWith(surface: const Color(0xFF103A30)),appBarSolidColor: const Color(0xFF00796B), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _lavenderSeedLight = const Color(0xFF6A5BE8); 
  static ThemeData get lavenderDreamLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _lavenderSeedLight, secondary: const Color(0xFF9D8BEA), brightness: Brightness.light).copyWith(surface: const Color(0xFFF8F7FF)),appBarSolidColor: _lavenderSeedLight, appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _lavenderSeedDark = const Color(0xFF9575CD); 
  static ThemeData get lavenderDreamDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _lavenderSeedDark, secondary: const Color(0xFFB39DDB), brightness: Brightness.dark).copyWith(surface: const Color(0xFF231B3E)),appBarSolidColor: const Color(0xFF5341A1), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _graphiteSeedLight = const Color(0xFF607D8B); 
  static ThemeData get graphiteNightLight => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _graphiteSeedLight, secondary: const Color(0xFF90A4AE), brightness: Brightness.light).copyWith(surface: const Color(0xFFECEFF1)),appBarSolidColor: _graphiteSeedLight, appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final Color _graphiteSeedDark = const Color(0xFFB0BEC5); 
  static ThemeData get graphiteNightDark => _buildThemeFromColorScheme(ColorScheme.fromSeed(seedColor: _graphiteSeedDark, secondary: const Color(0xFFCFD8DC), brightness: Brightness.dark).copyWith(surface: const Color(0xFF263238)),appBarSolidColor: const Color(0xFF37474F), appBarForegroundColorOverride: Colors.white, appBarTitleFontSize: 24);
  static final ColorScheme aiStudioLightColorScheme = ColorScheme(brightness: Brightness.light,primary: const Color(0xFF4A80FF), onPrimary: Colors.white,primaryContainer: const Color(0xFFDCE1FF), onPrimaryContainer: const Color(0xFF001849),secondary: const Color(0xFFA0A8C0), onSecondary: const Color(0xFF2B3042), secondaryContainer: const Color(0xFFE0E2F5), onSecondaryContainer: const Color(0xFF181A24), tertiary: const Color(0xFF77536F), onTertiary: Colors.white,tertiaryContainer: const Color(0xFFFFD7F1), onTertiaryContainer: const Color(0xFF2E112A),error: const Color(0xFFBA1A1A), onError: Colors.white,errorContainer: const Color(0xFFFFDAD6), onErrorContainer: const Color(0xFF410002),surface: const Color(0xFFFAF9FF), onSurface: const Color(0xFF1A1B1F), surfaceContainerHighest: const Color(0xFFE1E2EC), onSurfaceVariant: const Color(0xFF44464F),outline: const Color(0xFF767680), outlineVariant: const Color(0xFFC6C6D0),shadow: Colors.black, scrim: Colors.black,inverseSurface: const Color(0xFF2F3034), onInverseSurface: const Color(0xFFF1F0F7),inversePrimary: const Color(0xFFB4C5FF), surfaceTint: const Color(0xFF4A80FF));
  static ThemeData get aiStudioLight => _buildThemeFromColorScheme(aiStudioLightColorScheme, appBarTitleFontSize: 24, useSpecialAppBar: true);
  static final ColorScheme aiStudioDarkColorScheme = ColorScheme(brightness: Brightness.dark,primary: const Color(0xFFB4C5FF), onPrimary: const Color(0xFF172B77),primaryContainer: const Color(0xFF2F428E), onPrimaryContainer: const Color(0xFFDCE1FF),secondary: const Color(0xFFC1C6DD), onSecondary: const Color(0xFF2C3042),secondaryContainer: const Color(0xFF424659), onSecondaryContainer: const Color(0xFFDDE2FF),tertiary: const Color(0xFFE6BAD9), onTertiary: const Color(0xFF46263F),tertiaryContainer: const Color(0xFF5F3C57), onTertiaryContainer: const Color(0xFFFFD7F1),error: const Color(0xFFFFB4AB), onError: const Color(0xFF690005),errorContainer: const Color(0xFF93000A), onErrorContainer: const Color(0xFFFFDAD6),surface: const Color(0xFF1A1B1F), onSurface: const Color(0xFFE4E2E6), surfaceContainerHighest: const Color(0xFF46464F), onSurfaceVariant: const Color(0xFFC6C6D0),outline: const Color(0xFF90909A), outlineVariant: const Color(0xFF46464F),shadow: Colors.black, scrim: Colors.black,inverseSurface: const Color(0xFFE4E2E6), onInverseSurface: const Color(0xFF1A1B1F),inversePrimary: const Color(0xFF4A80FF), surfaceTint: const Color(0xFFB4C5FF));
  

static ThemeData get aiStudioDark => _buildThemeFromColorScheme(aiStudioDarkColorScheme, appBarTitleFontSize: 24, useSpecialAppBar: true);

  static ThemeData getThemeData(AppThemePalette palette, Brightness brightness) {
    bool isLight = brightness == Brightness.light;
    switch (palette) {
      case AppThemePalette.modernPremium: return isLight ? ModernTheme.lightTheme : ModernTheme.darkTheme;
      case AppThemePalette.defaultOrange: return isLight ? defaultOrangeLight : defaultOrangeDark;
      case AppThemePalette.material3Dynamic: return isLight ? material3DynamicLight : material3DynamicDark;
      case AppThemePalette.oceanBlue: return isLight ? oceanBlueLight : oceanBlueDark;
      case AppThemePalette.forestGreen: return isLight ? forestGreenLight : forestGreenDark;
      case AppThemePalette.sunsetGlow: return isLight ? sunsetGlowLight : sunsetGlowDark;
      case AppThemePalette.mintyFresh: return isLight ? mintyFreshLight : mintyFreshDark;
      case AppThemePalette.lavenderDream: return isLight ? lavenderDreamLight : lavenderDreamDark;
      case AppThemePalette.graphiteNight: return isLight ? graphiteNightLight : graphiteNightDark;
      case AppThemePalette.aiStudio: return isLight ? aiStudioLight : aiStudioDark;
    }
  }
}
