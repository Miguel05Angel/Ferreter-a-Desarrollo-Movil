import 'package:flutter/material.dart';

import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';
import '../../../services/comprobante_export.dart';
import '../buttons/animated_button.dart';
import 'comprobante_view.dart';

/// Comprobante (boleta o factura) con los botones para compartirlo como
/// PDF o como imagen.
class ComprobanteCompartible extends StatefulWidget {
  final Venta venta;
  final Cliente? cliente;
  final String vendedor;

  const ComprobanteCompartible({
    super.key,
    required this.venta,
    this.cliente,
    this.vendedor = 'Caja 01',
  });

  @override
  State<ComprobanteCompartible> createState() =>
      _ComprobanteCompartibleState();
}

class _ComprobanteCompartibleState extends State<ComprobanteCompartible> {
  final GlobalKey _llave = GlobalKey();
  String? _ocupado; // 'pdf' | 'imagen'

  Future<void> _compartir(String formato) async {
    setState(() => _ocupado = formato);
    final mensajes = ScaffoldMessenger.of(context);
    try {
      if (formato == 'pdf') {
        await ComprobanteExport.compartirPdf(_llave, widget.venta);
      } else {
        await ComprobanteExport.compartirImagen(_llave, widget.venta);
      }
    } catch (e) {
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('No se pudo compartir el comprobante. Intenta de nuevo.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenue = (Theme.of(context).textTheme.bodyMedium?.color ??
            Colors.grey.shade700)
        .withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _llave,
          child: ComprobanteView(
            venta: widget.venta,
            cliente: widget.cliente,
            vendedor: widget.vendedor,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'COMPARTIR ${widget.venta.comprobante.toUpperCase()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
            color: tenue,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                texto: 'PDF',
                icono: Icons.picture_as_pdf_outlined,
                cargando: _ocupado == 'pdf',
                onPressed: _ocupado == null ? () => _compartir('pdf') : null,
                ancho: double.infinity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedButton(
                texto: 'Imagen',
                icono: Icons.image_outlined,
                color: const Color(0xFF263238),
                cargando: _ocupado == 'imagen',
                onPressed:
                    _ocupado == null ? () => _compartir('imagen') : null,
                ancho: double.infinity,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
