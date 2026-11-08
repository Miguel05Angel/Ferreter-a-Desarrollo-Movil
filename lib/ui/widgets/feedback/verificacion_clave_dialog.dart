import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../visual/decor_industrial.dart';

/// Pide la contrasena del usuario actual antes de una accion sensible.
/// Devuelve true solo si la clave es correcta. Si se equivoca, la ventana
/// vibra y muestra un aviso discreto sin cerrarse.
class VerificacionClaveDialog extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final String textoConfirmar;

  const VerificacionClaveDialog({
    super.key,
    this.titulo = 'Verificación de seguridad',
    this.subtitulo = 'Ingresa tu contraseña actual para confirmar la aprobación.',
    this.textoConfirmar = 'Autorizar cotización',
  });

  static Future<bool> mostrar(
    BuildContext context, {
    String titulo = 'Verificación de seguridad',
    String subtitulo = 'Ingresa tu contraseña actual para confirmar la aprobación.',
    String textoConfirmar = 'Autorizar cotización',
  }) async {
    final r = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Verificación',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => VerificacionClaveDialog(
        titulo: titulo,
        subtitulo: subtitulo,
        textoConfirmar: textoConfirmar,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );
    return r == true;
  }

  @override
  State<VerificacionClaveDialog> createState() =>
      _VerificacionClaveDialogState();
}

class _VerificacionClaveDialogState extends State<VerificacionClaveDialog>
    with SingleTickerProviderStateMixin {
  final _clave = TextEditingController();
  late final AnimationController _vibrar = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  bool _oculta = true;
  bool _verificando = false;
  String? _error;

  @override
  void dispose() {
    _clave.dispose();
    _vibrar.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_verificando) return;
    if (_clave.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña');
      _vibrar.forward(from: 0);
      return;
    }
    setState(() => _verificando = true);
    try {
      final valida = await context.read<AuthProvider>().verificarPassword(_clave.text);
      if (!mounted) return;
      if (valida) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Contraseña incorrecta');
        _vibrar.forward(from: 0);
        _clave.clear();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo verificar la contraseña');
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vibrar,
      builder: (context, child) {
        final dx = math.sin(_vibrar.value * math.pi * 6) * 10 * (1 - _vibrar.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FranjaPeligro(alto: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 44, color: AppTheme.primary),
                  const SizedBox(height: 10),
                  Text(widget.titulo.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(widget.subtitulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.4, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _clave,
                    obscureText: _oculta,
                    autofocus: true,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _confirmar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.key_outlined),
                      errorText: _error,
                      suffixIcon: IconButton(
                        icon: Icon(_oculta ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _oculta = !_oculta),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _verificando ? null : _confirmar,
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(widget.textoConfirmar),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
