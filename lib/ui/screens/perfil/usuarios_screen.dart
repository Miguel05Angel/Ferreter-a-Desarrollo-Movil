import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/layout/appbar_taller.dart';

/// Solo para el Administrador: lista los usuarios y permite cambiar su rol.
class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.permisos.gestionaUsuarios) {
      return const AccesoRestringido(modulo: 'Usuarios y roles');
    }
    final yo = auth.usuarioActual;

    return Scaffold(
      appBar: const AppBarTaller(
          subtitulo: 'Administracion', title: Text('Usuarios y roles')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          FadeSlide(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.grafito,
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                    left: BorderSide(color: AppTheme.primary, width: 5)),
              ),
              child: const Text(
                'ADMINISTRADOR: control total.\n'
                'VENDEDOR: vende y atiende clientes; no edita productos, '
                'no ve costos y no entra a proveedores.',
                style: TextStyle(
                    color: Color(0xFFEDE8DF), height: 1.5, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < auth.usuarios.length; i++)
            FadeSlide(
              delay: Duration(milliseconds: 80 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.grafito,
                          child: Text(
                            auth.usuarios[i].nombre.isEmpty
                                ? '?'
                                : auth.usuarios[i].nombre[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auth.usuarios[i].nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(auth.usuarios[i].email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        if (auth.usuarios[i].id == yo?.id)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.amarilloSenal,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TU · ${auth.usuarios[i].rol.toUpperCase()}',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.grafito),
                            ),
                          )
                        else
                          DropdownButton<String>(
                            value: auth.usuarios[i].rol,
                            underline: const SizedBox.shrink(),
                            items: [
                              for (final r in Permisos.roles)
                                DropdownMenuItem(value: r, child: Text(r)),
                            ],
                            onChanged: (nuevo) {
                              if (nuevo == null) return;
                              final error = auth.cambiarRol(
                                  auth.usuarios[i].id, nuevo);
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
