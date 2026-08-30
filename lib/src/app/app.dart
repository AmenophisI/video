import 'package:flutter/material.dart';

import '../modules/video/presentation/video_library_screen.dart';

class VideoLibraryApp extends StatelessWidget {
  const VideoLibraryApp({super.key});

  static const _background = Color(0xFF000000);
  static const _surfaceContainer = Color(0xFF1C1D20);
  static const _surfaceContainerHigh = Color(0xFF2B2C30);
  static const _onSurface = Color(0xFFF4F5F6);
  static const _onSurfaceVariant = Color(0xFFA9ADB3);
  static const _accent = Color(0xFF4D90FE);
  static const _accentContainer = Color(0xFF16324F);
  static const _divider = Color(0xFF2A2B2E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          onPrimary: Colors.white,
          primaryContainer: _accentContainer,
          onPrimaryContainer: _onSurface,
          secondary: _accent,
          onSecondary: Colors.white,
          secondaryContainer: _accentContainer,
          onSecondaryContainer: _onSurface,
          surface: _background,
          onSurface: _onSurface,
          surfaceContainer: _surfaceContainer,
          surfaceContainerHigh: _surfaceContainerHigh,
          surfaceContainerHighest: _surfaceContainer,
          onSurfaceVariant: _onSurfaceVariant,
          outline: _divider,
          error: Color(0xFFFF6B64),
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: _onSurface,
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _background,
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? _accent : _onSurfaceVariant,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? _accent : _onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceContainer,
          hintStyle: const TextStyle(color: _onSurfaceVariant),
          prefixIconColor: _onSurfaceVariant,
          suffixIconColor: _onSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: _accent),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: _surfaceContainerHigh,
          contentTextStyle: TextStyle(color: _onSurface),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: _surfaceContainer,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: _surfaceContainer,
          selectedColor: _accentContainer,
          secondarySelectedColor: _accentContainer,
          side: BorderSide.none,
          labelStyle: TextStyle(color: _onSurfaceVariant),
        ),
        useMaterial3: true,
      ),
      home: const VideoLibraryScreen(),
    );
  }
}
