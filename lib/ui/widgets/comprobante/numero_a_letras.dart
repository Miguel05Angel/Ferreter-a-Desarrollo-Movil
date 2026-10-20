/// Convierte un monto a letras al estilo de los comprobantes peruanos:
/// "DOSCIENTOS VEINTITRES CON 96/100 SOLES".
String montoEnLetras(double monto) {
  var entero = monto.floor();
  var centimos = ((monto - entero) * 100).round();
  if (centimos == 100) {
    entero += 1;
    centimos = 0;
  }
  final letras = _letras(entero).toUpperCase();
  return '$letras CON ${centimos.toString().padLeft(2, '0')}/100 SOLES';
}

const _unidades = [
  '', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho',
  'nueve', 'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciseis',
  'diecisiete', 'dieciocho', 'diecinueve', 'veinte', 'veintiuno', 'veintidos',
  'veintitres', 'veinticuatro', 'veinticinco', 'veintiseis', 'veintisiete',
  'veintiocho', 'veintinueve',
];

const _decenas = [
  '', '', '', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta',
  'ochenta', 'noventa',
];

const _centenas = [
  '', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos',
  'seiscientos', 'setecientos', 'ochocientos', 'novecientos',
];

String _menorMil(int n) {
  if (n == 0) return '';
  if (n == 100) return 'cien';
  final c = n ~/ 100;
  final r = n % 100;
  final partes = <String>[];
  if (c > 0) partes.add(_centenas[c]);
  if (r > 0) {
    if (r < 30) {
      partes.add(_unidades[r]);
    } else {
      final d = r ~/ 10;
      final u = r % 10;
      partes.add(u == 0 ? _decenas[d] : '${_decenas[d]} y ${_unidades[u]}');
    }
  }
  return partes.join(' ');
}

/// "uno" -> "un" cuando acompana a "mil" o "millones".
String _apocope(String s) =>
    s.endsWith('uno') ? '${s.substring(0, s.length - 3)}un' : s;

String _letras(int n) {
  if (n == 0) return 'cero';
  final millones = n ~/ 1000000;
  final miles = (n % 1000000) ~/ 1000;
  final resto = n % 1000;
  final partes = <String>[];
  if (millones > 0) {
    partes.add(millones == 1
        ? 'un millon'
        : '${_apocope(_menorMil(millones))} millones');
  }
  if (miles > 0) {
    partes.add(miles == 1 ? 'mil' : '${_apocope(_menorMil(miles))} mil');
  }
  if (resto > 0) partes.add(_menorMil(resto));
  return partes.join(' ');
}
