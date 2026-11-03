import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/media_service.dart';

/// Vista 360: se arrastra horizontalmente para girar el producto, como un
/// plato giratorio. Usa la secuencia de fotos reales (24 a 36 tomas) y gira
/// sola hasta que el usuario la toca.
class Vista360 extends StatefulWidget {
  final List<String> ids;

  const Vista360({super.key, required this.ids});

  @override
  State<Vista360> createState() => _Vista360State();
}

class _Vista360State extends State<Vista360> {
  late final List<CachedNetworkImageProvider> _proveedores;
  int _frame = 0;
  double _acumulado = 0;
  int _cargadas = 0;
  bool _arrastrando = false;
  Timer? _auto;
  Timer? _reanudar;
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    _proveedores = widget.ids
        .map((id) => CachedNetworkImageProvider(
            MediaService.urlImagen(id, ancho: 900)))
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    for (final p in _proveedores) {
      precacheImage(p, context).whenComplete(() {
        if (mounted) setState(() => _cargadas++);
      });
    }
    _auto = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!_arrastrando && _cargadas >= _proveedores.length && mounted) {
        setState(() => _frame = (_frame + 1) % _proveedores.length);
      }
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _reanudar?.cancel();
    super.dispose();
  }

  void _mover(double dx) {
    _acumulado += dx;
    const paso = 9.0; // pixeles por cada foto
    var cambio = 0;
    while (_acumulado >= paso) {
      _acumulado -= paso;
      cambio--;
    }
    while (_acumulado <= -paso) {
      _acumulado += paso;
      cambio++;
    }
    if (cambio != 0) {
      setState(() {
        _frame = (_frame + cambio) % _proveedores.length;
        if (_frame < 0) _frame += _proveedores.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _proveedores.length;
    final listo = _cargadas >= n;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _reanudar?.cancel();
        _arrastrando = true;
      },
      onHorizontalDragUpdate: (d) => _mover(d.delta.dx),
      onHorizontalDragEnd: (_) {
        _reanudar = Timer(const Duration(seconds: 2), () {
          _arrastrando = false;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image(
              image: _proveedores[_frame],
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Color(0x80EDE8DF)),
            ),
          ),
          if (!listo)
            Positioned(
              bottom: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.grafito.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'CARGANDO VISTA 360  $_cargadas/$n',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppTheme.hueso,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.threesixty,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'ARRASTRA PARA GIRAR   ${_frame + 1}/$n',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Color(0xB3EDE8DF),
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
