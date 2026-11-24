import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as im;
import 'package:ferreteria_app/data/catalogo_fotos_drive.dart';
import 'package:ferreteria_app/data/catalogo_fotos_referencia.dart';

// Quita sólo blanco casi neutro conectado al borde: conserva blancos interiores.
im.Image quitarFondo(im.Image source) {
  final out = source.convert(numChannels: 4);
  final w = out.width,
      h = out.height,
      seen = Uint8List(out.width * out.height),
      queue = <int>[];
  void add(int x, int y) {
    final i = y * w + x;
    if (seen[i] != 0) return;
    seen[i] = 1;
    final c = out.getPixel(x, y);
    final lo = math.min(c.r, math.min(c.g, c.b));
    final hi = math.max(c.r, math.max(c.g, c.b));
    if (c.a == 0 || lo >= 238 && hi - lo <= 14) queue.add(i);
  }

  for (var x = 0; x < w; x++) {
    add(x, 0);
    add(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    add(0, y);
    add(w - 1, y);
  }
  for (var n = 0; n < queue.length; n++) {
    final i = queue[n], x = i % w, y = i ~/ w;
    out.getPixel(x, y).a = 0;
    if (x > 0) add(x - 1, y);
    if (x + 1 < w) add(x + 1, y);
    if (y > 0) add(x, y - 1);
    if (y + 1 < h) add(x, y + 1);
  }
  return out;
}

im.Image recortarEspecial(im.Image source, String id) {
  // Contornos verificados para las dos fotos con fondo gris o texturizado.
  final points = switch (id) {
    '1GttgytC3J7menzhx5lbf-PB1S5AILvT_' => <(double, double)>[
        (264, 147),
        (275, 140),
        (352, 140),
        (367, 149),
        (370, 409),
        (356, 412),
        (357, 485),
        (350, 520),
        (334, 520),
        (330, 484),
        (299, 484),
        (298, 516),
        (278, 519),
        (273, 484),
        (273, 413),
        (261, 409)
      ],
    '1WSqNng75vVMmNBVSUmqgpACLwoLOyl6R' => <(double, double)>[
        (0, 70),
        (14, 88),
        (315, 403),
        (325, 417),
        (329, 439),
        (316, 451),
        (284, 460),
        (261, 436),
        (0, 145)
      ],
    _ => <(double, double)>[],
  };
  if (points.isEmpty) return source;
  final originalSize = id == '1WSqNng75vVMmNBVSUmqgpACLwoLOyl6R' ? 600 : 640;
  final out = source.convert(numChannels: 4);
  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final px = x * originalSize / out.width,
          py = y * originalSize / out.height;
      var inside = false;
      for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
        final a = points[i], b = points[j];
        if ((a.$2 > py) != (b.$2 > py) &&
            px < (b.$1 - a.$1) * (py - a.$2) / (b.$2 - a.$2) + a.$1) {
          inside = !inside;
        }
      }
      if (!inside) out.getPixel(x, y).a = 0;
    }
  }
  return out;
}

Future<void> main() async {
  final codes = RegExp(r"codigo: '([^']+)'")
      .allMatches(File('lib/data/mock_data.dart').readAsStringSync())
      .map((m) => m.group(1)!);
  final ids = <String>{
    for (final code in codes)
      if ((fotosReferenciaDrive[code] ??
              catalogoFotosDrive[equivalenciasFotosDrive[code] ?? code]) !=
          null)
        (fotosReferenciaDrive[code] ??
            catalogoFotosDrive[equivalenciasFotosDrive[code] ?? code])!
  };
  final done = <String>[], failed = <String>[];
  final pending = ids.toList();
  var next = 0;
  Future<void> worker() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      while (next < pending.length) {
        final id = pending[next++];
        final file = File('assets/productos/$id.png');
        try {
          if (!file.existsSync()) {
            final req = await client.getUrl(
                Uri.parse('https://lh3.googleusercontent.com/d/$id=s0'));
            final res = await req.close().timeout(const Duration(seconds: 40));
            if (res.statusCode != 200) {
              throw HttpException('HTTP ${res.statusCode}');
            }
            final bytes = BytesBuilder();
            await for (final c in res.timeout(const Duration(seconds: 40))) {
              bytes.add(c);
            }
            final src = im.decodeImage(bytes.takeBytes());
            if (src == null) throw StateError('No es imagen');
            final scale = math.min(1.0, 640 / math.max(src.width, src.height));
            final small = im.copyResize(src,
                width: (src.width * scale).round(),
                height: (src.height * scale).round());
            final out = recortarEspecial(quitarFondo(small), id);
            file.writeAsBytesSync(im.encodePng(out, level: 9));
            final miniScale =
                math.min(1.0, 192 / math.max(out.width, out.height));
            File('assets/productos/mini/$id.png').writeAsBytesSync(im.encodePng(
                im.copyResize(out,
                    width: (out.width * miniScale).round(),
                    height: (out.height * miniScale).round()),
                level: 9));
          }
          done.add(id);
          stdout.writeln('PNG ${done.length}/${ids.length} $id');
        } catch (e) {
          failed.add(id);
          stderr.writeln('ERROR $id $e');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  await Future.wait(List.generate(4, (_) => worker()));
  done.sort();
  File('lib/data/imagenes_locales.dart').writeAsStringSync(
      "const imagenesLocales = <String>{\n${done.map((s) => "  '$s',").join('\n')}\n};\n");
  stdout.writeln('Generadas ${done.length}; errores ${failed.length}');
  if (failed.isNotEmpty) exitCode = 1;
}
