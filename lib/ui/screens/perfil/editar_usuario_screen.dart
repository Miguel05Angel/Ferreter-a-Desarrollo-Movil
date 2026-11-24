import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatos.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/layout/appbar_taller.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarUsuarioScreen({super.key, required this.usuario});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario.nombre);
  late final _telefono = TextEditingController(text: widget.usuario.telefono);
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<AuthProvider>().editarUsuario(
            usuarioId: widget.usuario.id,
            nombre: _nombre.text,
            telefono: _telefono.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is AuthError
            ? error.mensaje
            : 'No se pudo guardar. Inténtalo de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin =
        context.watch<AuthProvider>().usuarioActual?.rol == 'Administrador';
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        appBar: const AppBarTaller(
          mostrarCarrito: false,
          subtitulo: 'Administración',
          title: Text('Editar usuario'),
        ),
        body: !esAdmin
            ? const Center(child: Text('Acceso reservado al administrador.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('DNI ${widget.usuario.dni} · ${widget.usuario.rol}'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombre,
                        enabled: !_guardando,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        inputFormatters: Formatos.nombre(50),
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.nombre,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _telefono,
                        enabled: !_guardando,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: Formatos.digitos(9),
                        validator: Validators.telefonoOpcional,
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
                            : const Icon(Icons.save_outlined),
                        label:
                            Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
