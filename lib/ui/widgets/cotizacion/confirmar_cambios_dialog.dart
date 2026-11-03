import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../visual/decor_industrial.dart';

/// Doble confirmacion al editar una cotizacion: muestra un resumen visual
/// de lo modificado. Cada linea empieza con '+' (agregado), '-' (quitado) o
/// '~' (cambiado).
///
/// Devuelve 'aplicar', 'descartar' (solo si [permitirDescartar]) o null si
/// el usuario decide seguir editando.
class ConfirmarCambiosDialog extends StatelessWidget {
  final List<String> cambios;
  final bool permitirDescartar;

  const ConfirmarCambiosDialog({
    super.key,
    required this.cambios,
    required this.permitirDescartar,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required List<String> cambios,
    bool permitirDescartar = false,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => ConfirmarCambiosDialog(
          cambios: cambios, permitirDescartar: permitirDescartar),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );
  }

  static (IconData, Color) _estilo(String l) {
    if (l.startsWith('+')) return (Icons.add_circle_outline, const Color(0xFF2E7D32));
    if (l.startsWith('-')) return (Icons.remove_circle_outline, AppTheme.danger);
    return (Icons.change_circle_outlined, const Color(0xFFB87900));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: const Icon(Icons.fact_check_outlined,
                        size: 46, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '¿Estás seguro de que quieres aplicar estos cambios?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w900, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RESUMEN DE CAMBIOS',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        for (var i = 0; i < cambios.length; i++)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + 70 * i),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(
                                  offset: Offset(12 * (1 - v), 0), child: child),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(_estilo(cambios[i]).$1,
                                      size: 18, color: _estilo(cambios[i]).$2),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(cambios[i].substring(1).trim(),
                                        style: const TextStyle(
                                            fontSize: 13, height: 1.3)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop('aplicar'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Sí, estoy seguro'),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Seguir editando'),
                  ),
                  if (permitirDescartar)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('descartar'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                      child: const Text('Descartar cambios y salir'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
