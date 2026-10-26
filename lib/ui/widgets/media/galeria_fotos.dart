import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/media_service.dart';

/// Fotografias reales del producto (frontal, posterior y detalles). Se desliza
/// entre fotos y se hace zoom con dos dedos.
class GaleriaFotos extends StatefulWidget {
  final List<String> ids;

  const GaleriaFotos({super.key, required this.ids});

  @override
  State<GaleriaFotos> createState() => _GaleriaFotosState();
}

class _GaleriaFotosState extends State<GaleriaFotos> {
  final _pagina = PageController();
  int _actual = 0;

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pagina,
          itemCount: widget.ids.length,
          onPageChanged: (i) => setState(() => _actual = i),
          itemBuilder: (context, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: MediaService.urlImagen(widget.ids[i], ancho: 1200),
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 48, color: Color(0x80EDE8DF)),
              ),
            ),
          ),
        ),
        if (widget.ids.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.ids.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _actual ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _actual
                          ? AppTheme.primary
                          : const Color(0x66EDE8DF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
