import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Boton de esquina biselada con sombra solida que se "hunde" al
/// presionarlo, como una tecla de maquina. Admite estado de carga.
class AnimatedButton extends StatefulWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;
  final bool cargando;
  final Color? color;
  final Color? colorSecundario;
  final double alto;
  final double? ancho;

  const AnimatedButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.cargando = false,
    this.color,
    this.colorSecundario,
    this.alto = 54,
    this.ancho,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _presionado = false;

  bool get _deshabilitado => widget.onPressed == null || widget.cargando;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppTheme.primary;
    final color = _deshabilitado ? Colors.grey.shade400 : base;
    final fondoSombra = Color.lerp(color, Colors.black, 0.45)!;
    final tinta = widget.color == null ? AppTheme.grafito : Colors.white;

    return GestureDetector(
      onTapDown: _deshabilitado ? null : (_) => setState(() => _presionado = true),
      onTapUp: _deshabilitado
          ? null
          : (_) {
              setState(() => _presionado = false);
              widget.onPressed!();
            },
      onTapCancel:
          _deshabilitado ? null : () => setState(() => _presionado = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform:
              Matrix4.translationValues(0, _presionado ? 4 : 0, 0),
          width: widget.ancho,
          height: widget.alto,
          decoration: ShapeDecoration(
            color: color,
            shape: const BeveledRectangleBorder(
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(18)),
            ),
            shadows: _deshabilitado
                ? null
                : [
                    BoxShadow(
                      color: fondoSombra,
                      offset: Offset(0, _presionado ? 1 : 5),
                    ),
                  ],
          ),
          child: Center(
            child: widget.cargando
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: tinta),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icono != null) ...[
                        Icon(widget.icono, color: tinta, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.texto.toUpperCase(),
                        style: TextStyle(
                          color: tinta,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
