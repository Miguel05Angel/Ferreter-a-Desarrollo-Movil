import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ferreteria_app/data/mock_data.dart';
import 'package:ferreteria_app/providers/media_provider.dart';
import 'package:ferreteria_app/ui/widgets/media/imagen_catalogo.dart';
import 'package:ferreteria_app/ui/widgets/media/producto_imagen.dart';
import 'package:ferreteria_app/ui/widgets/media/escenario_producto.dart';

void main() {
  final llaves = MockData.productos.firstWhere((p) => p.codigo == 'HER-002');
  final media = MediaProvider();
  final foto = media.fotoLocal('HER-002')!;

  void sinAvisos() {
    expect(find.textContaining('FALTA'), findsNothing);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  testWidgets(
      'HER-002 usa miniatura local también en pantalla de alta densidad',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => MediaProvider(),
      child: MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3),
        child: Center(child: ProductoImagen(producto: llaves, size: 100)),
      )),
    ));
    sinAvisos();
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect(resized.width, 192);
    expect((resized.imageProvider as AssetImage).assetName,
        contains('/mini/1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3.png'));
    expect(tester.getSize(find.byType(ProductoImagen)), const Size(100, 100));
    sinAvisos();
    expect(tester.takeException(), isNull);
  });

  for (final error in [false, true]) {
    testWidgets(
        error
            ? 'Si la descarga falla conserva la foto local del producto'
            : 'Mientras la descarga espera muestra la foto local del producto',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Center(child: Builder(
        builder: (context) {
          // Ejercita la salida de los callbacks sin iniciar una red real.
          final remote = ImagenCatalogo(
            imageUrl: 'https://example.invalid/foto-nueva.png',
            respaldoUrl: foto,
            width: 100,
            height: 100,
          ).build(context) as CachedNetworkImage;
          return error
              ? remote.errorWidget!(
                  context, remote.imageUrl, StateError('sin red'))
              : remote.placeholder!(context, remote.imageUrl);
        },
      ))));
      await tester.pumpAndSettle();
      final asset =
          tester.widget<Image>(find.byType(Image)).image as AssetImage;
      expect(asset.assetName,
          contains('/mini/1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3.png'));
      sinAvisos();
      expect(tester.takeException(), isNull);
    });
  }

  for (final url in [
    'https://drive.usercontent.google.com/download?id=1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3&export=download&confirm=t',
    'https://drive.google.com/thumbnail?id=1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3&sz=w500',
    'https://drive.google.com/file/d/1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3/view',
    'https://lh3.googleusercontent.com/d/1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3=w500',
  ]) {
    testWidgets('Reconoce foto local en formato Drive: $url', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Center(child: ImagenCatalogo(
        imageUrl: url, width: 100, height: 100,
      ))));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName,
        'assets/productos/mini/1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3.png');
      sinAvisos();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Producto nuevo sin foto mantiene el espacio sin cartel de error',
      (tester) async {
    final nuevo = llaves.copyWith(codigo: 'SIN-FOTO');
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => MediaProvider(),
      child: MaterialApp(
          home: Center(child: ProductoImagen(producto: nuevo, size: 100))),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ProductoImagen)), const Size(100, 100));
    sinAvisos();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detalle sin foto no muestra cartel de falta de imagen',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => MediaProvider(),
      child: MaterialApp(
          home: SizedBox(
              width: 300,
              height: 300,
              child: EscenarioProducto(
                  producto: llaves.copyWith(codigo: 'SIN-FOTO'),
                  colorHex: llaves.colorHex,
                  acento: Colors.orange))),
    ));
    await tester.pumpAndSettle();
    sinAvisos();
    expect(tester.takeException(), isNull);
  });
}
