import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/media_service.dart';

/// Modelo 3D real (.glb) del producto. Se descarga una sola vez, se guarda
/// en el telefono y se puede girar con el dedo y hacer zoom.
class VisorModelo3D extends StatefulWidget {
  final String codigo;
  final String idModelo;

  const VisorModelo3D({super.key, required this.codigo, required this.idModelo});

  @override
  State<VisorModelo3D> createState() => _VisorModelo3DState();
}

class _VisorModelo3DState extends State<VisorModelo3D> {
  String? _ruta;
  String? _error;
  double _progreso = 0;

  @override
  void initState() {
    super.initState();
    _descargar();
  }

  Future<void> _descargar() async {
    setState(() {
      _error = null;
      _progreso = 0;
    });
    try {
      final ruta = await MediaService.descargarModelo(
        widget.codigo,
        widget.idModelo,
        alProgresar: (v) {
          if (mounted) setState(() => _progreso = v);
        },
      );
      if (mounted) setState(() => _ruta = ruta);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'No se pudo descargar el modelo 3D. Revisa tu conexion.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar_outlined,
                size: 44, color: Color(0x80EDE8DF)),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xB3EDE8DF), fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _descargar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      );
    }

    if (_ruta == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                value: _progreso > 0 ? _progreso : null,
                minHeight: 5,
                backgroundColor: const Color(0xFF2E353B),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _progreso > 0
                  ? 'DESCARGANDO MODELO 3D  ${(_progreso * 100).round()}%'
                  : 'PREPARANDO MODELO 3D...',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1.2,
                color: Color(0xB3EDE8DF),
              ),
            ),
          ],
        ),
      );
    }

    return ModelViewer(
      src: 'file://$_ruta',
      alt: 'Modelo 3D del producto ${widget.codigo}',
      ar: false,
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      shadowIntensity: 1,
      backgroundColor: Colors.transparent,
    );
  }
}
