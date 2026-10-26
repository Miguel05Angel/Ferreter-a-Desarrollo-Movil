import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';
import '../../../services/comprobante_exportador.dart';
import '../buttons/animated_button.dart';
import 'comprobante_view.dart';

/// Comprobante con los botones para compartirlo como PDF o como imagen.
class ComprobanteConAcciones extends StatefulWidget {
  final Venta venta;
  final Cliente? cliente;
  final String vendedor;

  const ComprobanteConAcciones({
    super.key,
    required this.venta,
    this.cliente,
    this.vendedor = 'Caja 01',
  });

  @override
  State<ComprobanteConAcciones> createState() =>
      _ComprobanteConAccionesState();
}

class _ComprobanteConAccionesState extends State<ComprobanteConAcciones> {
  final GlobalKey _llave = GlobalKey();
  String? _ocupado; // 'pdf' | 'imagen'

  Future<void> _ejecutar(String tipo, Future<void> Function() accion) async {
    if (_ocupado != null) return;
    setState(() => _ocupado = tipo);
    try {
      await accion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('No se pudo compartir el comprobante. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // El fondo hueso hace que la imagen compartida se vea limpia
        RepaintBoundary(
          key: _llave,
          child: Container(
            color: const Color(0xFFEDE8DF),
            padding: const EdgeInsets.all(14),
            child: ComprobanteView(
              venta: widget.venta,
              cliente: widget.cliente,
              vendedor: widget.vendedor,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                texto: 'PDF',
                icono: Icons.picture_as_pdf_outlined,
                cargando: _ocupado == 'pdf',
                onPressed: _ocupado == null
                    ? () => _ejecutar(
                          'pdf',
                          () => ComprobanteExportador.compartirPdf(
                            widget.venta,
                            widget.cliente,
                            widget.vendedor,
                          ),
                        )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedButton(
                texto: 'Imagen',
                icono: Icons.image_outlined,
                cargando: _ocupado == 'imagen',
                onPressed: _ocupado == null
                    ? () => _ejecutar(
                          'imagen',
                          () => ComprobanteExportador.compartirImagen(
                            _llave,
                            widget.venta,
                          ),
                        )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'COMPARTE POR WHATSAPP, CORREO O GUARDALO EN TU TELEFONO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            letterSpacing: 0.8,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
