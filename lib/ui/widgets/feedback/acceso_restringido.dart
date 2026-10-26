import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../buttons/animated_button.dart';
import '../layout/appbar_taller.dart';

/// Pantalla que se muestra cuando el rol del usuario no tiene permiso.
class AccesoRestringido extends StatelessWidget {
  final String titulo;
  final String detalle;

  const AccesoRestringido({
    super.key,
    this.titulo = 'Acceso restringido',
    this.detalle = 'Esta seccion es solo para el Administrador.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarTaller(
        mostrarCarrito: false,
        subtitulo: 'Permisos',
        title: Text(titulo),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, v, child) {
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY((1 - v) * 2.4);
                  return Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: Transform.scale(
                        scale: v.clamp(0.0, 1.2).toDouble(), child: child),
                  );
                },
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: const ShapeDecoration(
                    color: AppTheme.grafito,
                    shape: BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(30)),
                      side: BorderSide(color: AppTheme.primary, width: 2.5),
                    ),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: AppTheme.primary, size: 52),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                titulo.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.5, height: 1.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 26),
              AnimatedButton(
                texto: 'Volver',
                icono: Icons.arrow_back,
                onPressed: () => Navigator.of(context).maybePop(),
                ancho: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
