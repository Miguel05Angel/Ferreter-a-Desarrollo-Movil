import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/media_service.dart';

class GaleriaFotos extends StatefulWidget {
  final List<String> ids;
  final bool referencial;

  const GaleriaFotos({super.key, required this.ids, this.referencial = false});

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
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pagina,
            itemCount: widget.ids.length,
            onPageChanged: (i) => setState(() => _actual = i),
            itemBuilder: (context, i) {
              // Resuelve el ID de Drive o el enlace remoto del catálogo.
              final urlReal =
                  MediaService.urlImagen(widget.ids[i], ancho: 1200);


              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: urlReal,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48, color: Colors.black38),
                    );
                  },
                ),
              );
            },
          ),
          if (widget.referencial)
            const Positioned(
              top: 8,
              left: 8,
              child: Text('Foto referencial',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      backgroundColor: Colors.white)),
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
                        color: i == _actual ? AppTheme.primary : Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
