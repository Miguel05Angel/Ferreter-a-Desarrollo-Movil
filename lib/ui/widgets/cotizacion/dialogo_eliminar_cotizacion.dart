import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../visual/decor_industrial.dart';

/// Advertencia antes de eliminar una o varias cotizaciones.
/// Devuelve true solo si el usuario pulsa 'Confirmar'.
class DialogoEliminarCotizacion extends StatelessWidget {
  final int cantidad;
  const DialogoEliminarCotizacion({super.key, this.cantidad = 1});

  static Future<bool> mostrar(BuildContext context, {int cantidad = 1}) async {
    final r = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => DialogoEliminarCotizacion(cantidad: cantidad),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final varias = cantidad > 1;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: const Icon(Icons.delete_forever_outlined,
                      size: 52, color: AppTheme.danger),
                ),
                const SizedBox(height: 12),
                Text(
                  varias ? 'ELIMINAR $cantidad COTIZACIONES' : 'ELIMINAR COTIZACIÓN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),
                Text(
                  varias
                      ? '¿Deseas eliminar estas cotizaciones y sus datos asociados?'
                      : '¿Deseas eliminar esta cotización y sus datos asociados?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 4),
                Text('Esta acción no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('CONFIRMAR'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('REVISAR NUEVAMENTE'),
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
