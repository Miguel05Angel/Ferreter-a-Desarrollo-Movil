import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Envuelve el numero de una cantidad: con doble toque abre un campo para
/// escribir la cantidad exacta (por ejemplo 30) sin pulsar "+" treinta veces.
class EditableCantidad extends StatelessWidget {
  final int valor;
  final int maximo;
  final ValueChanged<int> onCambio;
  final Widget child;
  final String titulo;

  const EditableCantidad({
    super.key,
    required this.valor,
    required this.maximo,
    required this.onCambio,
    required this.child,
    this.titulo = 'Cantidad exacta',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () async {
        final n = await DialogoCantidad.mostrar(
          context,
          valor: valor,
          maximo: maximo,
          titulo: titulo,
        );
        if (n != null && n != valor) onCambio(n);
      },
      child: child,
    );
  }
}

/// Ventana pequena con un campo numerico para la cantidad exacta.
class DialogoCantidad extends StatefulWidget {
  final int valor;
  final int maximo;
  final String titulo;

  const DialogoCantidad({
    super.key,
    required this.valor,
    required this.maximo,
    required this.titulo,
  });

  static Future<int?> mostrar(
    BuildContext context, {
    required int valor,
    required int maximo,
    String titulo = 'Cantidad exacta',
  }) {
    return showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) =>
          DialogoCantidad(valor: valor, maximo: maximo, titulo: titulo),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.88, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<DialogoCantidad> createState() => _DialogoCantidadState();
}

class _DialogoCantidadState extends State<DialogoCantidad> {
  late final TextEditingController _c =
      TextEditingController(text: '${widget.valor}');
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _aplicar() {
    final n = int.tryParse(_c.text.trim());
    if (n == null || n < 1) {
      setState(() => _error = 'Escribe una cantidad de 1 o más');
      return;
    }
    if (n > widget.maximo) {
      setState(() => _error = 'Máximo ${widget.maximo} unidades');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titulo.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _aplicar(),
              decoration: InputDecoration(
                errorText: _error,
                helperText: 'Máximo ${widget.maximo}',
                suffixText: 'und',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _aplicar,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.grafito),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
