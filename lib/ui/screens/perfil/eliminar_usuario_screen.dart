import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatos.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/layout/appbar_taller.dart';

class EliminarUsuarioScreen extends StatefulWidget {
  final Usuario usuario;
  const EliminarUsuarioScreen({super.key, required this.usuario});

  @override
  State<EliminarUsuarioScreen> createState() => _EliminarUsuarioScreenState();
}

class _EliminarUsuarioScreenState extends State<EliminarUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _dni = TextEditingController();
  bool _eliminando = false;

  @override
  void dispose() {
    _password.dispose();
    _dni.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    if (_eliminando || !_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.usuarioActual?.rol != 'Administrador' ||
        auth.usuarioActual?.id == widget.usuario.id) {
      return;
    }
    setState(() => _eliminando = true);
    try {
      await auth.eliminarUsuario(
          usuarioId: widget.usuario.id, passwordActual: _password.text);
      if (!mounted) return;
      _password.clear();
      setState(() => _eliminando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Usuario eliminado. Las ventas se conservaron.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is AuthError
              ? error.mensaje
              : 'No se pudo confirmar la eliminación.')));
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actual = context.watch<AuthProvider>().usuarioActual;
    final permitida =
        actual?.rol == 'Administrador' && actual?.id != widget.usuario.id;
    return PopScope(
      canPop: !_eliminando,
      child: Scaffold(
        appBar: const AppBarTaller(
            mostrarCarrito: false,
            subtitulo: 'Administración',
            title: Text('Eliminar usuario')),
        body: !permitida
            ? const Center(
                child:
                    Text('Solo el administrador puede eliminar otras cuentas.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            '${widget.usuario.nombre}\nDNI ${widget.usuario.dni} · ${widget.usuario.rol}'),
                        const SizedBox(height: 16),
                        const Text(
                            'Esta acción elimina la cuenta y su acceso a la app. No se puede deshacer. Las ventas registradas se conservarán.'),
                        const SizedBox(height: 24),
                        AbsorbPointer(
                            absorbing: _eliminando,
                            child: Column(children: [
                              TextFormField(
                                controller: _dni,
                                decoration: const InputDecoration(
                                    labelText:
                                        'Escribe el DNI del usuario para confirmar'),
                                keyboardType: TextInputType.number,
                                inputFormatters: Formatos.digitos(8),
                                validator: (v) => v?.trim() ==
                                        widget.usuario.dni
                                    ? null
                                    : 'El DNI no coincide con la cuenta seleccionada.',
                              ),
                              const SizedBox(height: 20),
                              PasswordField(
                                  etiqueta: 'Tu contraseña de administrador',
                                  controlador: _password,
                                  validador: (v) => Validators.requerido(
                                      v, 'Ingresa tu contraseña actual.')),
                            ])),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error),
                          onPressed: _eliminando ? null : _eliminar,
                          icon: _eliminando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.delete_outline),
                          label: Text(_eliminando
                              ? 'Eliminando…'
                              : 'Eliminar definitivamente'),
                        ),
                      ],
                    )),
              ),
      ),
    );
  }
}
