import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/usuario.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../auth/register_screen.dart';

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
                      ),
                  ],
                );
              },
            ),
    );
  }
}
