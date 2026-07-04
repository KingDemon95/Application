import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── LIGHT COLORS ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color background   = Color(0xFFF8FAFB);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color primary      = Color(0xFF2D9B8A);
  static const Color primaryDark  = Color(0xFF1E7A6B);
  static const Color primaryLight = Color(0xFF4DB8A4);
  static const Color accent       = Color(0xFF3AAFA9);
  static const Color textDark     = Color(0xFF1A2E35);
  static const Color textMedium   = Color(0xFF4A6572);
  static const Color textLight    = Color(0xFF8FA8B2);
  static const Color inputBorder  = Color(0xFFDDE8EC);
  static const Color inputFill    = Color(0xFFF5F9FA);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color cardBorder   = Color(0xFFEAF2F5);
  static const Color chipTeal     = Color(0xFFE0F5F2);
  static const Color chipTealIcon = Color(0xFF2D9B8A);
}

// ─── DARK COLORS ──────────────────────────────────────────────────────────────
class DarkColors {
  static const Color background  = Color(0xFF0D1B1E); // hitam kehijauan gelap
  static const Color surface     = Color(0xFF132226); // card background
  static const Color surface2    = Color(0xFF1A2F35); // input / secondary card
  static const Color primary     = Color(0xFF2EC4A9); // teal lebih terang di dark
  static const Color primaryDark = Color(0xFF1E9E8A);
  static const Color accent      = Color(0xFF3AAFA9);
  static const Color textDark    = Color(0xFFE8F4F1); // teks utama (hampir putih)
  static const Color textMedium  = Color(0xFF8BBFB8); // teks sekunder
  static const Color textLight   = Color(0xFF4E7A74); // teks tersier
  static const Color inputBorder = Color(0xFF1E3A40);
  static const Color inputFill   = Color(0xFF132226);
  static const Color cardBorder  = Color(0xFF1E3A40);
  static const Color chipTeal    = Color(0xFF0E2E2A); // chip teal gelap
}

// ─── THEME PROVIDER (pakai ValueNotifier, tidak perlu package tambahan) ───────
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark(bool val) {
    _mode = val ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// ─── LIGHT THEME ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
        cardColor: AppColors.white,
        dividerColor: AppColors.cardBorder,
        inputDecorationTheme: _inputTheme(
          fill: AppColors.inputFill,
          border: AppColors.inputBorder,
          hint: AppColors.textLight,
          focused: AppColors.primary,
        ),
        elevatedButtonTheme: _elevatedBtn(AppColors.primary),
        textTheme: GoogleFonts.poppinsTextTheme(),
        extensions: const [ValenxColors.light],
      );

  // ─── DARK THEME ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DarkColors.background,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: DarkColors.primary,
          secondary: DarkColors.accent,
          surface: DarkColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: DarkColors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: DarkColors.textDark),
        ),
        cardColor: DarkColors.surface,
        dividerColor: DarkColors.cardBorder,
        inputDecorationTheme: _inputTheme(
          fill: DarkColors.inputFill,
          border: DarkColors.inputBorder,
          hint: DarkColors.textLight,
          focused: DarkColors.primary,
        ),
        elevatedButtonTheme: _elevatedBtn(DarkColors.primary),
        textTheme:
            GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        extensions: const [ValenxColors.dark],
      );

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
    required Color focused,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: focused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
        hintStyle: GoogleFonts.poppins(color: hint, fontSize: 14),
        prefixIconColor: hint,
        suffixIconColor: hint,
      );

  static ElevatedButtonThemeData _elevatedBtn(Color color) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─── ThemeExtension — akses warna adaptif dari mana saja ─────────────────────
// Cara pakai: context.vx.primary, context.vx.cardBg, dll
class ValenxColors extends ThemeExtension<ValenxColors> {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color primary;
  final Color primaryDark;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final Color inputBorder;
  final Color inputFill;
  final Color cardBorder;
  final Color chipTeal;
  final Color white;

  const ValenxColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.primary,
    required this.primaryDark,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    required this.inputBorder,
    required this.inputFill,
    required this.cardBorder,
    required this.chipTeal,
    required this.white,
  });

  // Light preset
  static const light = ValenxColors(
    background:  AppColors.background,
    surface:     AppColors.white,
    surface2:    AppColors.inputFill,
    primary:     AppColors.primary,
    primaryDark: AppColors.primaryDark,
    textDark:    AppColors.textDark,
    textMedium:  AppColors.textMedium,
    textLight:   AppColors.textLight,
    inputBorder: AppColors.inputBorder,
    inputFill:   AppColors.inputFill,
    cardBorder:  AppColors.cardBorder,
    chipTeal:    AppColors.chipTeal,
    white:       AppColors.white,
  );

  // Dark preset
  static const dark = ValenxColors(
    background:  DarkColors.background,
    surface:     DarkColors.surface,
    surface2:    DarkColors.surface2,
    primary:     DarkColors.primary,
    primaryDark: DarkColors.primaryDark,
    textDark:    DarkColors.textDark,
    textMedium:  DarkColors.textMedium,
    textLight:   DarkColors.textLight,
    inputBorder: DarkColors.inputBorder,
    inputFill:   DarkColors.inputFill,
    cardBorder:  DarkColors.cardBorder,
    chipTeal:    DarkColors.chipTeal,
    white:       DarkColors.surface, // di dark mode "white" = surface gelap
  );

  @override
  ValenxColors copyWith({
    Color? background, Color? surface, Color? surface2,
    Color? primary, Color? primaryDark,
    Color? textDark, Color? textMedium, Color? textLight,
    Color? inputBorder, Color? inputFill, Color? cardBorder,
    Color? chipTeal, Color? white,
  }) =>
      ValenxColors(
        background:  background  ?? this.background,
        surface:     surface     ?? this.surface,
        surface2:    surface2    ?? this.surface2,
        primary:     primary     ?? this.primary,
        primaryDark: primaryDark ?? this.primaryDark,
        textDark:    textDark    ?? this.textDark,
        textMedium:  textMedium  ?? this.textMedium,
        textLight:   textLight   ?? this.textLight,
        inputBorder: inputBorder ?? this.inputBorder,
        inputFill:   inputFill   ?? this.inputFill,
        cardBorder:  cardBorder  ?? this.cardBorder,
        chipTeal:    chipTeal    ?? this.chipTeal,
        white:       white       ?? this.white,
      );

  @override
  ValenxColors lerp(ValenxColors? other, double t) {
    if (other == null) return this;
    return ValenxColors(
      background:  Color.lerp(background,  other.background,  t)!,
      surface:     Color.lerp(surface,     other.surface,     t)!,
      surface2:    Color.lerp(surface2,    other.surface2,    t)!,
      primary:     Color.lerp(primary,     other.primary,     t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      textDark:    Color.lerp(textDark,    other.textDark,    t)!,
      textMedium:  Color.lerp(textMedium,  other.textMedium,  t)!,
      textLight:   Color.lerp(textLight,   other.textLight,   t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFill:   Color.lerp(inputFill,   other.inputFill,   t)!,
      cardBorder:  Color.lerp(cardBorder,  other.cardBorder,  t)!,
      chipTeal:    Color.lerp(chipTeal,    other.chipTeal,    t)!,
      white:       Color.lerp(white,       other.white,       t)!,
    );
  }
}

// ─── Extension shortcut: context.vx.primary ───────────────────────────────────
extension ValenxThemeX on BuildContext {
  ValenxColors get vx =>
      Theme.of(this).extension<ValenxColors>() ?? ValenxColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}