import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../auth/register_screen.dart';
import 'editar_usuario_screen.dart';
import 'password_usuario_screen.dart';
import 'eliminar_usuario_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final _usuarios = context.read<AuthProvider>().escucharUsuarios();

  @override
  Widget build(BuildContext context) {
    final actual = context.watch<AuthProvider>().usuarioActual;
    return Scaffold(
      appBar: const AppBarTaller(
        mostrarCarrito: false,
        subtitulo: 'Administración',
        title: Text('Usuarios'),
      ),
      body: actual?.rol != 'Administrador'
          ? const Center(child: Text('Acceso reservado al administrador.'))
          : StreamBuilder<List<Usuario>>(
              stream: _usuarios,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('No se pudo cargar la lista.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          AppRoutes.push(context, const RegisterScreen()),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Registrar vendedor'),
                    ),
                    const SizedBox(height: 16),
                    for (final usuario in snapshot.data!)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(usuario.nombre),
                        subtitle: Text('DNI ${usuario.dni} · ${usuario.rol}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar usuario',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => AppRoutes.push(
                                context,
                                EditarUsuarioScreen(usuario: usuario),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Opciones de usuario',
                              onSelected: (opcion) => AppRoutes.push(
                                  context,
                                  opcion == 'eliminar'
                                      ? EliminarUsuarioScreen(usuario: usuario)
                                      : PasswordUsuarioScreen(
                                          usuario: usuario)),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: 'password',
                                    child: Text(usuario.id == actual!.id
                                        ? 'Cambiar mi contraseña'
                                        : 'Restablecer contraseña')),
                                if (usuario.id != actual.id)
                                  const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar usuario')),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
