import 'package:flutter_test/flutter_test.dart';

import 'package:ferreteria_app/data/catalogo_fotos_drive.dart';
import 'package:ferreteria_app/data/catalogo_fotos_referencia.dart';
import 'package:ferreteria_app/data/mock_data.dart';
import 'package:ferreteria_app/providers/media_provider.dart';

void main() {
  test('Las referencias son IDs de Drive únicos y no archivos incluidos', () {
    expect(catalogoFotosDrive.length, 43);
    expect(catalogoFotosDrive.values.toSet().length, 43);
    for (final id in catalogoFotosDrive.values) {
      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    }
  });

  test('Cada código usa su foto de Drive y conserva las equivalencias', () {
    final media = MediaProvider();
    for (final entry in catalogoFotosDrive.entries) {
      final uri = Uri.parse(media.miniatura(' ${entry.key.toLowerCase()} ')!);
      expect(uri.host, 'lh3.googleusercontent.com');
      expect(uri.path, '/d/${entry.value}=w500');
    }
    for (final entry in equivalenciasFotosDrive.entries) {
      final uri = Uri.parse(media.miniatura(entry.key)!);
      expect(uri.path, '/d/${catalogoFotosDrive[entry.value]}=w500');
    }
    // La cinta métrica usa su referencia nueva, nunca la cinta adhesiva mal archivada.
    expect(catalogoFotosDrive['HER-005'], isNull);
    expect(media.de('HER-005')!.fotos.single, fotosReferenciaDrive['HER-005']);
    expect(media.de('TUB-003')!.fotoReferencial, isTrue);
    expect(media.de('INEXISTENTE'), isNull);
    media.dispose();
  });

  test('Los 77 productos del catálogo tienen foto remota asignada', () {
    final media = MediaProvider();
    expect(MockData.productos.length, 77);
    expect(fotosReferenciaDrive.length, 51);
    for (final producto in MockData.productos) {
      final recurso = media.de(producto.codigo);
      expect(recurso?.tieneFotos, isTrue, reason: producto.codigo);
      expect(media.miniatura(producto.codigo),
          startsWith('https://lh3.googleusercontent.com/'));
      expect(recurso!.fotoReferencial,
          fotosReferenciaDrive.containsKey(producto.codigo));
    }
    media.dispose();
  });
}
