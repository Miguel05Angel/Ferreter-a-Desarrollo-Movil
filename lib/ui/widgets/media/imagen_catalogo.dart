import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/imagenes_locales.dart';

/// Centraliza fotos locales, tamaño de decodificación y caché de fotos nuevas.
class ImagenCatalogo extends StatelessWidget {
  const ImagenCatalogo({
    super.key,
    required this.imageUrl,
    this.respaldoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.memCacheWidth,
    this.fadeInDuration = Duration.zero,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final String? respaldoUrl;
  final double? width, height;
  final BoxFit fit;
  final int? memCacheWidth;
  final Duration fadeInDuration;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  static final _driveId = RegExp(r'/d/([^=/]+)');

  String? _archivoLocal(String? url) {
    final uri = Uri.tryParse(url ?? '');
    final id = uri?.queryParameters['id'] ??
        _driveId.firstMatch(uri?.path ?? '')?.group(1);
    if (id == null || !imagenesLocales.contains(id)) return null;
    final pequena = width != null && width! <= 128 ||
        memCacheWidth != null && memCacheWidth! <= 256;
    return 'assets/productos/${pequena ? 'mini/' : ''}$id.png';
  }

  Widget _imagenLocal(String archivo, {ImageErrorWidgetBuilder? alFallar}) {
    final limite = archivo.contains('/mini/') ? 192 : 640;
    return Image.asset(
      archivo,
      width: width,
      height: height,
      fit: fit,
      cacheWidth:
          memCacheWidth == null ? null : math.min(memCacheWidth!, limite),
      gaplessPlayback: true,
      errorBuilder: alFallar ?? (_, __, ___) => const SizedBox.expand(),
    );
  }

  Widget _respaldo() {
    final archivo = _archivoLocal(respaldoUrl);
    return archivo == null ? const SizedBox.expand() : _imagenLocal(archivo);
  }

  @override
  Widget build(BuildContext context) {
    final archivo = _archivoLocal(imageUrl);
    if (archivo != null) {
      return _imagenLocal(archivo,
          alFallar: (c, e, s) =>
              errorWidget?.call(c, imageUrl, e) ?? _respaldo());
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: Duration.zero,
      placeholder: placeholder ?? (_, __) => _respaldo(),
      errorWidget: errorWidget ?? (_, __, ___) => _respaldo(),
    );
  }
}
