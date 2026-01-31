// lib/app/core/theme/theme.dart
// Defines app-wide light/dark ThemeData plus the shared design tokens.
// Keeps colors + typography consistent across all screens and widgets.
// RELEVANT FILES:lib/app/core/theme/app_canvas_background.dart,lib/main.dart,lib/app/root/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePreferenceKey = 'treesporapp_theme_mode';

final ThemeData lightTheme = _buildTheme(_lightColorScheme);
final ThemeData darkTheme = _buildTheme(_darkColorScheme);

final ColorScheme _lightColorScheme = ColorScheme.light(
  primary: const Color(0xFF0B1014),
  onPrimary: const Color(0xFFF5F5F5),
  secondary: const Color(0xFF2F7A5B),
  onSecondary: Colors.white,
  background: const Color(0xFFFAFAFA),
  onBackground: const Color(0xFF0B1014),
  surface: const Color(0xFFFFFFFF),
  onSurface: const Color(0xFF0B1014),
  surfaceVariant: const Color(0xFFE3EAF2),
  onSurfaceVariant: const Color(0xFF3D4955),
  outline: const Color(0xFFB7C2CD),
  outlineVariant: const Color(0xFFD2DCE6),
  inverseSurface: const Color(0xFF121820),
  onInverseSurface: const Color(0xFFEFF3F7),
  shadow: const Color(0x33000000),
);

final ColorScheme _darkColorScheme = ColorScheme.dark(
  primary: const Color(0xFFF5F5F5),
  onPrimary: const Color(0xFF0B1014),
  secondary: const Color(0xFF9DD7C0),
  onSecondary: const Color(0xFF0D1B15),
  background: const Color(0xFF0F151B),
  onBackground: const Color(0xFFF2F4F6),
  surface: const Color(0xFF151D24),
  onSurface: const Color(0xFFF2F4F6),
  surfaceVariant: const Color(0xFF151D24),
  onSurfaceVariant: const Color(0xFFB9C2CB),
  outline: const Color(0xFF34414D),
  outlineVariant: const Color(0xFF1E2730),
  inverseSurface: const Color(0xFFE6E9ED),
  onInverseSurface: const Color(0xFF0F151B),
  shadow: const Color(0xCC000000),
);

ThemeData _buildTheme(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final navBackground = Color.alphaBlend(
    Colors.white.withOpacity(isDark ? 0.04 : 0.22),
    colorScheme.background,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.background,
    textTheme: _createTextTheme(colorScheme),
  );

  return baseTheme.copyWith(
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      trackColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? colorScheme.primary
            : colorScheme.surfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withOpacity(isDark ? 0.12 : 0.10),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: navBackground,
      elevation: 0,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      space: 32,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: colorScheme.onSurface),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.surfaceVariant),
      ),
    ),
  );
}

TextTheme _createTextTheme(ColorScheme colorScheme) {
  const baseFont = 'Inter';
  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    headlineLarge: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onBackground,
    ),
    titleLarge: TextStyle(
      fontFamily: baseFont,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: baseFont,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleSmall: TextStyle(
      fontFamily: baseFont,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    bodyLarge: TextStyle(fontFamily: baseFont, color: colorScheme.onSurface),
    bodyMedium: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onSurfaceVariant,
    ),
    bodySmall: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontFamily: baseFont,
      fontWeight: FontWeight.w600,
      color: colorScheme.onPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: baseFont,
      color: colorScheme.onSurfaceVariant,
    ),
  );
}

class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs, this._themeMode);

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIndex = prefs.getInt(_themeModePreferenceKey);
    ThemeMode initialMode = ThemeMode.system;

    if (storedIndex != null &&
        storedIndex >= 0 &&
        storedIndex < ThemeMode.values.length) {
      initialMode = ThemeMode.values[storedIndex];
    }

    return ThemeController._(prefs, initialMode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) {
      return;
    }
    _themeMode = themeMode;
    notifyListeners();
    await _prefs.setInt(_themeModePreferenceKey, themeMode.index);
  }

  Future<void> cycleThemeMode() {
    final nextIndex =
        (ThemeMode.values.indexOf(_themeMode) + 1) % ThemeMode.values.length;
    return setThemeMode(ThemeMode.values[nextIndex]);
  }
}

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>()
        : context
                  .getElementForInheritedWidgetOfExactType<
                    ThemeControllerProvider
                  >()
                  ?.widget
              as ThemeControllerProvider?;
    assert(
      provider != null,
      'ThemeControllerProvider.of() called with no ThemeController in context',
    );
    return provider!.notifier!;
  }

  @override
  bool updateShouldNotify(
    covariant InheritedNotifier<ThemeController> oldWidget,
  ) => true;
}

class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.smartphone),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.wb_sunny_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.nights_stay_outlined),
            ),
          ],
          showSelectedIcon: false,
          selected: <ThemeMode>{controller.themeMode},
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            backgroundColor: colorScheme.surface,
            selectedBackgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onSurface,
            selectedForegroundColor: colorScheme.onPrimary,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          onSelectionChanged: (selection) {
            final mode = selection.first;
            controller.setThemeMode(mode);
          },
        );
      },
    );
  }
}
