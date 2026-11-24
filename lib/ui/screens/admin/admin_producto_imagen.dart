import 'package:flutter/material.dart';
import '../../widgets/media/imagen_catalogo.dart';

import '../../../data/catalogo_fotos_drive.dart';
import '../../../data/catalogo_fotos_referencia.dart';

/// Resuelve la fotografía del catálogo compartido con Android.
String? urlFotoProductoAdmin(String codigo) {
  final key = codigo.trim().toUpperCase();
  final id = fotosReferenciaDrive[key] ??
      catalogoFotosDrive[equivalenciasFotosDrive[key] ?? key];
  if (id == null) return null;
  // s0 conserva el PNG y su canal alfa. Las variantes w500 lo convierten a
  // JPEG; el enlace de descarga original bloquea imágenes desde otras webs.
  return Uri.https('lh3.googleusercontent.com', '/d/$id=s0').toString();
}

class AdminProductoImagen extends StatelessWidget {
  const AdminProductoImagen({
    super.key,
    required this.codigo,
    required this.nombre,
    this.tamano = 72,
  });

  final String codigo;
  final String nombre;
  final double tamano;

  Widget _respaldo() => Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: tamano * 0.4, color: Colors.grey.shade500),
      );

  @override
  Widget build(BuildContext context) {
    final url = urlFotoProductoAdmin(codigo);
    return Semantics(
      image: true,
      label: 'Foto de $nombre',
      child: Container(
        width: tamano,
        height: tamano,
        padding: EdgeInsets.all(tamano * 0.06),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(tamano * 0.15),
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null
            ? _respaldo()
            : ImagenCatalogo(
                imageUrl: url,
                key: ValueKey(url),
                width: tamano,
                height: tamano,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _respaldo(),
              ),
      ),
    );
  }
}
