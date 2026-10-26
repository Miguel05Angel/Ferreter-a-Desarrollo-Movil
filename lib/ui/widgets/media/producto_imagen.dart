import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';
import '../visual/producto_illustration.dart';

/// Imagen del producto: usa la fotografia real de Google Drive cuando existe
/// y, si no, la ilustracion 3D integrada.
class ProductoImagen extends StatelessWidget {
  final Producto producto;
  final double size;
  final bool sombra;

  const ProductoImagen({
    super.key,
    required this.producto,
    this.size = 64,
    this.sombra = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = context.watch<MediaProvider>().miniatura(producto.codigo);
    final ilustracion = ProductoEstatico(
      tipo: producto.tipoVisual,
      colorHex: producto.colorHex,
      size: size,
      sombra: sombra,
    );
    if (url == null) return ilustracion;

    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => ilustracion,
        errorWidget: (_, __, ___) => ilustracion,
      ),
    );
  }
}
