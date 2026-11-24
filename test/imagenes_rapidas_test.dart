import 'package:flutter_test/flutter_test.dart';
import 'package:ferreteria_app/data/producto_visible.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'package:ferreteria_app/data/mock_data.dart';
import 'package:ferreteria_app/data/imagenes_locales.dart';
import 'package:ferreteria_app/ui/screens/admin/admin_producto_imagen.dart';
import 'package:ferreteria_app/ui/widgets/media/imagen_catalogo.dart';
import '../tool/preparar_imagenes.dart' as preparar;

void main() {
  test('Visibilidad refleja desactivar, papelera y restaurar en la web', () {
    expect(productoVisible({}), isTrue);
    expect(productoVisible({'activo': false}), isFalse);
    expect(productoVisible({'activo': true, 'eliminadoEn': 'fecha'}), isFalse);
    expect(productoVisible({'activo': true}), isTrue);
  });
  test('Recorte conserva el blanco encerrado dentro del producto', () {
    final image = im.Image(width: 7, height: 7, numChannels: 4);
    im.fill(image, color: im.ColorRgba8(255, 255, 255, 255));
    for (var i = 1; i < 6; i++) {
      image.setPixelRgba(i, 1, 0, 0, 0, 255);
      image.setPixelRgba(i, 5, 0, 0, 0, 255);
      image.setPixelRgba(1, i, 0, 0, 0, 255);
      image.setPixelRgba(5, i, 0, 0, 0, 255);
    }
    final out = preparar.quitarFondo(image);
    expect(out.getPixel(0, 0).a, 0);
    expect(out.getPixel(3, 3).a, 255);
    expect(out.getPixel(1, 1).a, 255);
  });
  test('Catálogo completo tiene PNG local', () {
    for (final p in MockData.productos) {
      final url = urlFotoProductoAdmin(p.codigo)!;
      final id = RegExp(r'/d/([^=/]+)').firstMatch(url)!.group(1)!;
      expect(imagenesLocales.contains(id), isTrue, reason: p.codigo);
    }
  });
  testWidgets('Foto de catálogo abre desde assets sin solicitud a Drive',
      (t) async {
    await t.pumpWidget(MaterialApp(
        home: ImagenCatalogo(
            imageUrl: urlFotoProductoAdmin(MockData.productos.first.codigo)!,
            width: 64,
            height: 64)));
    await t.pumpAndSettle();
    final image = t.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(t.takeException(), isNull);
  });
}
