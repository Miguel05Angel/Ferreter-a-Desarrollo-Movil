import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../visual/decor_industrial.dart';

/// Dialog de exito con check animado.
class SuccessDialog extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoBoton;
  final VoidCallback? onCerrar;

  const SuccessDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.textoBoton = 'Aceptar',
    this.onCerrar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoBoton = 'Aceptar',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoBoton: textoBoton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
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
                    width: 84,
                    height: 84,
                    decoration: const ShapeDecoration(
                      color: AppTheme.success,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(24)),
                      ),
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 50),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCerrar?.call();
                    },
                    child: Text(textoBoton.toUpperCase()),
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

/// Dialog de confirmacion generico animado.
class ConfirmDialog extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoConfirmar;
  final VoidCallback onConfirmar;

  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.onConfirmar,
    this.textoConfirmar = 'Confirmar',
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required VoidCallback onConfirmar,
    String textoConfirmar = 'Confirmar',
  }) {
    return showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        titulo: titulo,
        mensaje: mensaje,
        onConfirmar: onConfirmar,
        textoConfirmar: textoConfirmar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.primary, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titulo.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  mensaje,
                  style: const TextStyle(fontSize: 14.5, height: 1.55),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirmar();
                      },
                      child: Text(textoConfirmar.toUpperCase()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
