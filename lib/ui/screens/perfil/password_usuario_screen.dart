import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/layout/appbar_taller.dart';

class PasswordUsuarioScreen extends StatefulWidget {
  final Usuario usuario;
  const PasswordUsuarioScreen({super.key, required this.usuario});

  @override
  State<PasswordUsuarioScreen> createState() => _PasswordUsuarioScreenState();
}

class _PasswordUsuarioScreenState extends State<PasswordUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.usuarioActual?.rol != 'Administrador') return;
    final propia = auth.usuarioActual?.id == widget.usuario.id;
    if (propia && _actual.text == _nueva.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Elige una contraseña diferente a la actual.'),
      ));
      return;
    }
    setState(() => _guardando = true);
    try {
      if (propia) {
        await auth.cambiarMiPassword(
          passwordActual: _actual.text,
          nuevaPassword: _nueva.text,
        );
      } else {
        await auth.restablecerPasswordUsuario(
          usuarioId: widget.usuario.id,
          passwordActual: _actual.text,
          nuevaPassword: _nueva.text,
        );
      }
      if (!mounted) return;
      _actual.clear();
      _nueva.clear();
      _confirmar.clear();
      // Se permite cerrar la ruta una vez finalizada la operación.
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(propia
            ? 'Tu contraseña fue actualizada.'
            : 'Contraseña de ${widget.usuario.nombre} restablecida.'),
      ));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is AuthError
            ? error.mensaje
            : 'No se pudo confirmar el cambio de contraseña.'),
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actual = context.watch<AuthProvider>().usuarioActual;
    final propia = actual?.id == widget.usuario.id;
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        appBar: AppBarTaller(
          mostrarCarrito: false,
          subtitulo: 'Administración',
          title:
              Text(propia ? 'Cambiar mi contraseña' : 'Restablecer contraseña'),
        ),
        body: actual?.rol != 'Administrador'
            ? const Center(child: Text('Acceso reservado al administrador.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          '${widget.usuario.nombre}\nDNI ${widget.usuario.dni}'),
                      const SizedBox(height: 12),
                      Text(propia
                          ? 'Confirma tu contraseña actual para cambiarla.'
                          : 'Confirma tu contraseña de administrador. La nueva clave reemplazará la de esta cuenta y deberá usarse en su próximo acceso.'),
                      const SizedBox(height: 24),
                      AbsorbPointer(
                        absorbing: _guardando,
                        child: Column(children: [
                          PasswordField(
                            etiqueta: propia
                                ? 'Contraseña actual'
                                : 'Tu contraseña de administrador',
                            controlador: _actual,
                            validador: (v) => Validators.requerido(
                                v, 'Ingresa tu contraseña actual.'),
                          ),
                          const SizedBox(height: 20),
                          PasswordField(
                            etiqueta: 'Nueva contraseña',
                            controlador: _nueva,
                            validador: Validators.nuevaPassword,
                            ayuda: 'De 6 a 20 caracteres y al menos un número',
                          ),
                          const SizedBox(height: 20),
                          PasswordField(
                            etiqueta: 'Confirmar nueva contraseña',
                            controlador: _confirmar,
                            validador: (v) =>
                                Validators.confirmarPassword(v, _nueva.text),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_reset),
                        label: Text(_guardando
                            ? 'Guardando…'
                            : propia
                                ? 'Cambiar contraseña'
                                : 'Restablecer contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
