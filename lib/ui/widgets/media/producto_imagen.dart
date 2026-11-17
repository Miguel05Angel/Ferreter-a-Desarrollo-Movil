import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';

/// Imagen del producto: usa la fotografia real de Google Drive cuando existe.
/// Si no hay foto, muestra un aviso visual de "FALTA IMAGEN" en lugar de la
/// ilustracion 3D para alertar al administrador.
class ProductoImagen extends StatelessWidget {
  final Producto producto;
  final double size;
  final bool sombra; // Mantenemos el parametro por compatibilidad, aunque ya no se use

  const ProductoImagen({
    super.key,
    required this.producto,
    this.size = 64,
    this.sombra = false,
  });

  /// Widget de respaldo cuando no hay foto real en el sistema.
  Widget _faltaImagen() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.35,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          Text(
            'FALTA\nIMAGEN',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.13,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
              height: 1.1,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = context.watch<MediaProvider>().miniatura(producto.codigo);
    final fallback = _faltaImagen();

    if (url == null) return fallback;

    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}