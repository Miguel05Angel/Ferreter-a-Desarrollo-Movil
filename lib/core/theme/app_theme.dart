import 'package:flutter/material.dart';

/// Tema visual de la aplicacion (claro y oscuro).
///
/// Identidad "taller": grafito, naranja de seguridad, fondos calidos,
/// bordes finos en lugar de sombras difusas y esquinas biseladas en
/// botones y cuadros de dialogo.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFFF6D00);
  static const Color primaryLight = Color(0xFFFF9E40);
  static const Color secondary = Color(0xFF15181B);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
  static const Color fondoClaro = Color(0xFFF2EFE9);
  static const Color bordeClaro = Color(0xFFDDD7CC);
  static const Color fondoOscuro = Color(0xFF111417);
  static const Color superficieOscura = Color(0xFF1C2126);
  static const Color bordeOscuro = Color(0xFF30373E);
  static const Color grafito = Color(0xFF15181B);
  static const Color hueso = Color(0xFFEDE8DF);
  static const Color amarilloSenal = Color(0xFFFFC400);

  /// Esquina inferior derecha cortada, firma visual de la app.
  static const BeveledRectangleBorder biselado = BeveledRectangleBorder(
    borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
  );

  static ThemeData get light => _tema(Brightness.light);
  static ThemeData get dark => _tema(Brightness.dark);

  static ThemeData _tema(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    final fondo = oscuro ? fondoOscuro : fondoClaro;
    final superficie = oscuro ? superficieOscura : Colors.white;
    final borde = oscuro ? bordeOscuro : bordeClaro;
    final texto = oscuro ? hueso : const Color(0xFF1B1F23);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brillo,
    ).copyWith(
      primary: primary,
      onPrimary: grafito,
      secondary: oscuro ? const Color(0xFF78909C) : grafito,
      error: oscuro ? const Color(0xFFEF5350) : danger,
      surface: superficie,
      onSurface: texto,
    );

    OutlineInputBorder campo(Color color, double ancho) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: ancho),
        );

    const estiloBoton = TextStyle(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      fontSize: 14.5,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: scheme,
      scaffoldBackgroundColor: fondo,
      dividerColor: borde,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
        titleSmall: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: grafito,
        foregroundColor: hueso,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: primary, width: 3)),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: hueso,
        ),
        iconTheme: IconThemeData(color: hueso),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borde),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: campo(borde, 1.4),
        enabledBorder: campo(borde, 1.4),
        focusedBorder: campo(primary, 2),
        errorBorder: campo(scheme.error, 1.5),
        focusedErrorBorder: campo(scheme.error, 2),
        labelStyle: const TextStyle(fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: grafito,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: biselado,
          textStyle: estiloBoton,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: grafito,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: biselado,
          textStyle: estiloBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texto,
          side: BorderSide(color: borde, width: 1.6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: biselado,
          textStyle: estiloBoton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: oscuro ? primaryLight : const Color(0xFFD95800),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 0.4),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: grafito,
        elevation: 3,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(18)),
        ),
        extendedTextStyle:
            TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primary.withOpacity(0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(26)),
        ),
        titleTextStyle: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w800, color: texto),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borde),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? grafito : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : null),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
