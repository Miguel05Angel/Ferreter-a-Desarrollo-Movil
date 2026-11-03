import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cotizacion.dart';
import '../../../services/cotizacion_pdf.dart';
import '../visual/decor_industrial.dart';

/// Alerta de cotizacion confirmada. Ademas del mensaje ofrece:
///  - VER COTIZACION: abre el documento generado.
///  - COMPARTIR: PDF o imagen, igual que las boletas y facturas.
///
/// Devuelve 'ver' (abrir el documento), 'imagen' (abrir el documento y
/// compartirlo como imagen) o 'cerrar'.
class CotizacionListaDialog extends StatefulWidget {
  final Cotizacion cotizacion;
  final bool edicion;

  const CotizacionListaDialog({
    super.key,
    required this.cotizacion,
    required this.edicion,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required Cotizacion cotizacion,
    required bool edicion,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Cotización lista',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) =>
          CotizacionListaDialog(cotizacion: cotizacion, edicion: edicion),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<CotizacionListaDialog> createState() => _CotizacionListaDialogState();
}

class _CotizacionListaDialogState extends State<CotizacionListaDialog> {
  bool _pdf = false;

  Future<void> _compartir() async {
    final eleccion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: const Border(top: BorderSide(color: AppTheme.primary, width: 2.5)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('COMPARTIR COTIZACIÓN',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop('pdf'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop('imagen'),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('IMAGEN'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF263238),
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('COMPARTE POR WHATSAPP, CORREO O GUÁRDALO EN TU TELÉFONO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
    if (!mounted || eleccion == null) return;

    if (eleccion == 'imagen') {
      // La imagen se captura del documento en pantalla.
      Navigator.of(context).pop('imagen');
      return;
    }
    setState(() => _pdf = true);
    try {
      await CotizacionPdf.compartir(widget.cotizacion);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('No se pudo compartir el PDF. Intenta de nuevo.'),
        ));
      }
    }
    if (mounted) setState(() => _pdf = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    final m = Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY((1 - value) * 3.1);
                    return Transform(
                      alignment: Alignment.center,
                      transform: m,
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const ShapeDecoration(
                      color: AppTheme.success,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(22)),
                      ),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 46),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.edicion ? 'COTIZACIÓN ACTUALIZADA' : 'COTIZACIÓN CONFIRMADA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  '${CotizacionPdf.numero(c)}\n'
                  'Cliente: ${c.clienteNombre}\n'
                  'Total: ${Formatters.soles(c.total)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop('ver'),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('VER COTIZACIÓN'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pdf ? null : _compartir,
                    icon: _pdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share_outlined),
                    label: const Text('COMPARTIR'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cerrar'),
                  child: const Text('LISTO'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
