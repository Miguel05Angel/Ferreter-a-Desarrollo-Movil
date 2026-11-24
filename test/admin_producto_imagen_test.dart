import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ferreteria_app/data/catalogo_fotos_drive.dart';
import 'package:ferreteria_app/data/catalogo_fotos_referencia.dart';
import 'package:ferreteria_app/data/mock_data.dart';
import 'package:ferreteria_app/ui/screens/admin/admin_producto_imagen.dart';

void main() {
  test('Los 77 productos usan la misma foto remota que el catálogo móvil', () {
    for (final producto in MockData.productos) {
      final codigo = producto.codigo;
      final id = fotosReferenciaDrive[codigo] ??
          catalogoFotosDrive[equivalenciasFotosDrive[codigo] ?? codigo];
      expect(id, isNotNull, reason: codigo);
      final uri = Uri.parse(urlFotoProductoAdmin(' ${codigo.toLowerCase()} ')!);
      expect(uri.host, 'lh3.googleusercontent.com');
      expect(uri.path, '/d/$id=s0', reason: codigo);
    }
    expect(urlFotoProductoAdmin('INEXISTENTE'), isNull);
  });

  testWidgets('Un producto sin foto conserva su espacio en una fila pequeña',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
          child: AdminProductoImagen(
        codigo: 'SIN-FOTO',
        nombre: 'Producto nuevo',
        tamano: 36,
      )),
    ));
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(
        tester.getSize(find.byType(AdminProductoImagen)), const Size(36, 36));
    expect(tester.takeException(), isNull);
  });
}
