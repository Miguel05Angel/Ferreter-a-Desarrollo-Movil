import 'package:flutter/services.dart';

/// Formateadores de entrada reutilizables: limitan la cantidad de digitos y
/// el tipo de caracteres que se pueden escribir en cada campo.
class Formatos {
  Formatos._();

  /// Solo digitos, con un maximo de [max] (DNI = 8, RUC = 11, telefono = 9).
  static List<TextInputFormatter> digitos(int max) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(max),
      ];

  /// Texto libre con un maximo de caracteres.
  static List<TextInputFormatter> texto(int max) =>
      [LengthLimitingTextInputFormatter(max)];

  /// Codigo de producto: letras, numeros y guion, en mayusculas.
  static List<TextInputFormatter> codigo(int max) => [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
        LengthLimitingTextInputFormatter(max),
        _Mayusculas(),
      ];

  /// Nombres de personas o empresas: sin simbolos raros.
  static List<TextInputFormatter> nombre(int max) => [
        FilteringTextInputFormatter.allow(
            RegExp(r"[A-Za-z0-9 .,&'\-ÁÉÍÓÚáéíóúÑñÜü]")),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Importes: hasta [enteros] digitos y [decimales] decimales.
  static TextInputFormatter decimal({int enteros = 6, int decimales = 2}) =>
      _Decimal(enteros, decimales);

  /// Correo: sin espacios y con maximo de caracteres.
  static List<TextInputFormatter> correo(int max) => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(max),
      ];
}

class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    return nuevo.copyWith(text: nuevo.text.toUpperCase());
  }
}

class _Decimal extends TextInputFormatter {
  final int enteros;
  final int decimales;

  _Decimal(this.enteros, this.decimales);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    var t = nuevo.text.replaceAll(',', '.');
    if (t.isEmpty) return nuevo.copyWith(text: t);
    final ok = RegExp('^\\d{0,$enteros}(\\.\\d{0,$decimales})?\$').hasMatch(t);
    if (!ok) return anterior;
    return nuevo.copyWith(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
