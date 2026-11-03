import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/media_service.dart';

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
          itemBuilder: (context, i) {
            // Aquí se obtiene el enlace de ImgBB desde el JSON
            final urlReal = MediaService.urlImagen(widget.ids[i], ancho: 1200);
            
            // ESPÍA: Esto nos dirá en la consola qué URL está usando la app
            print('🖼️ INTENTANDO CARGAR: $urlReal');
            
            return InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: urlReal,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  // ESTO NOS DIRÁ LA VERDAD EN LA CONSOLA
                  print('🚨 ERROR EN: $url');
                  print('🚨 DETALLE: $error');
                  return const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: Color(0x80EDE8DF)),
                  );
                },
              ),
            );
          },
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