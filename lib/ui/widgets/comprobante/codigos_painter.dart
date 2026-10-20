import 'package:flutter/material.dart';

int _hash(String s) =>
    s.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

/// Genera una cadena hexadecimal estable a partir de un texto (hash visual
/// que se muestra en el comprobante).
String hashVisual(String semilla, {int largo = 32}) {
  var h = _hash(semilla);
  final b = StringBuffer();
  while (b.length < largo) {
    h = (h * 1103515245 + 12345) & 0x7fffffff;
    b.write(((h >> 8) & 0xFFFF).toRadixString(16).padLeft(4, '0'));
  }
  return b.toString().substring(0, largo);
}

/// Codigo QR ilustrativo: tiene la apariencia de un QR (marcadores de
/// esquina, lineas de temporizacion y modulos de datos) pero NO es
/// escaneable. Para cobros reales se debe reemplazar por el QR oficial de
/// Yape / Plin o por el de la factura electronica.
class QrIlustrativoPainter extends CustomPainter {
  final String semilla;
  final Color color;
  static const int _n = 29;

  QrIlustrativoPainter({required this.semilla, this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final cel = size.width / _n;
    final p = Paint()..color = color;

    bool reservado(int x, int y) =>
        (x < 8 && y < 8) || (x >= _n - 8 && y < 8) || (x < 8 && y >= _n - 8);

    var s = _hash(semilla);
    bool siguiente() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return ((s >> 16) & 1) == 1;
    }

    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        final dato = siguiente();
        if (reservado(x, y)) continue;
        var activo = dato;
        if (y == 6) activo = x.isEven;
        if (x == 6) activo = y.isEven;
        if (activo) {
          canvas.drawRect(
              Rect.fromLTWH(x * cel, y * cel, cel + 0.4, cel + 0.4), p);
        }
      }
    }

    void marcador(int ox, int oy) {
      final borde = Rect.fromLTWH(ox * cel, oy * cel, 7 * cel, 7 * cel);
      canvas.drawRect(borde, p);
      canvas.drawRect(borde.deflate(cel), Paint()..color = Colors.white);
      canvas.drawRect(borde.deflate(2 * cel), p);
    }

    marcador(0, 0);
    marcador(_n - 7, 0);
    marcador(0, _n - 7);
  }

  @override
  bool shouldRepaint(QrIlustrativoPainter old) =>
      old.semilla != semilla || old.color != color;
}

/// Codigo de barras decorativo (estilo Code 128) generado a partir de un
/// texto.
class CodigoBarrasPainter extends CustomPainter {
  final String semilla;

  CodigoBarrasPainter(this.semilla);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black;
    var s = _hash(semilla);
    var x = 0.0;
    var barra = true;
    while (x < size.width) {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      final ancho = 1.0 + ((s >> 16) % 3) * 1.1;
      if (barra) {
        canvas.drawRect(
            Rect.fromLTWH(x, 0, (x + ancho > size.width) ? size.width - x : ancho,
                size.height),
            p);
      }
      x += ancho;
      barra = !barra;
    }
  }

  @override
  bool shouldRepaint(CodigoBarrasPainter old) => old.semilla != semilla;
}
