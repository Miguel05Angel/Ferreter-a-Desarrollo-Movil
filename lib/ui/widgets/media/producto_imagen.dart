import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';
import 'imagen_catalogo.dart';

/// Foto local inmediata, con respaldo para las actualizaciones remotas.
class ProductoImagen extends StatelessWidget {
  const ProductoImagen({
    super.key,
    required this.producto,
    this.size = 64,
    this.sombra = false,
  });

  final Producto producto;
  final double size;
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    final media = context.watch<MediaProvider>();
    final respaldo = media.fotoLocal(producto.codigo);
    final url = media.miniatura(producto.codigo) ?? respaldo;

    return SizedBox(
      width: size,
      height: size,
      child: url == null
          ? null
          : ImagenCatalogo(
              imageUrl: url,
              respaldoUrl: respaldo,
              width: size,
              height: size,
              memCacheWidth:
                  (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
            ),
    );
  }
}
