import 'package:flutter/material.dart';

import '../../../core/permisos.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/layout/section_header.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../../core/theme/app_theme.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _notificaciones = true;

  Future<void> _editarNombre() async {
    final controller = TextEditingController(
        text: context.read<AuthProvider>().usuarioActual?.nombre ?? '');
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.trim().length >= 3) {
      if (!mounted) return;
      context.read<AuthProvider>().actualizarNombre(resultado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nombre actualizado'),
            backgroundColor: Color(0xFF2E7D32)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final tema = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: const AppBarTaller(subtitulo: 'Cuenta', title: Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlide(
            child: ClipPath(
              clipper: _BiselClipper(),
              child: Container(
                color: AppTheme.grafito,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: PlanoPainter()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            alignment: Alignment.center,
                            decoration: const ShapeDecoration(
                              color: AppTheme.primary,
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(20)),
                              ),
                            ),
                            child: Text(
                              (usuario?.nombre.isNotEmpty ?? false)
                                  ? usuario!.nombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 32,
                                  color: AppTheme.grafito,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  usuario?.nombre ?? 'Invitado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.hueso,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  usuario?.email ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Color(0x99EDE8DF),
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 9),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.amarilloSenal,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (usuario?.rol ?? 'Cliente').toUpperCase(),
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: AppTheme.grafito,
                                        letterSpacing: 1.4,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader(titulo: 'Rol y permisos'),
          FadeSlide(
            delay: const Duration(milliseconds: 150),
            child: _TarjetaPermisos(permisos: Permisos.de(context)),
          ),
          const SectionHeader(titulo: 'Preferencias'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Modo oscuro'),
                  subtitle: const Text(
                      'Reduce el brillo para usar de noche'),
                  trailing: Switch(
                    value: tema.esModoOscuro,
                    onChanged: (v) => tema.alternarTema(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notificaciones'),
                  subtitle:
                      const Text('Alertas de stock y recordatorios'),
                  trailing: Switch(
                    value: _notificaciones,
                    onChanged: (v) =>
                        setState(() => _notificaciones = v),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(titulo: 'Cuenta'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar nombre'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editarNombre,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Telefono'),
                  subtitle: Text(usuario?.telefono ?? 'No registrado'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Acerca de'),
                  subtitle: Text(
                      '${AppConstants.nombreApp} - v1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                ConfirmDialog.mostrar(
                  context,
                  titulo: 'Cerrar sesion',
                  mensaje: '¿Deseas cerrar sesion en la aplicacion?',
                  textoConfirmar: 'Cerrar sesion',
                  onConfirmar: () {
                    context.read<AuthProvider>().cerrarSesion();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login, (route) => false);
                  },
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


class _BiselClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const corte = 26.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - corte)
      ..lineTo(size.width - corte, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_BiselClipper oldClipper) => false;
}


/// Lista de lo que el rol actual puede y no puede hacer.
class _TarjetaPermisos extends StatelessWidget {
  final Permisos permisos;

  const _TarjetaPermisos({required this.permisos});

  @override
  Widget build(BuildContext context) {
    final lista = permisos.resumen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: permisos.esAdmin
                        ? AppTheme.amarilloSenal
                        : AppTheme.grafito,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    permisos.rol.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      color: permisos.esAdmin
                          ? AppTheme.grafito
                          : AppTheme.hueso,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    permisos.esAdmin ? 'Control total' : 'Acceso de ventas',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < lista.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + i * 70),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                      offset: Offset((1 - v) * 16, 0), child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        lista[i].$2
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        size: 19,
                        color: lista[i].$2
                            ? AppTheme.success
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lista[i].$1,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.25,
                            color: lista[i].$2
                                ? null
                                : Colors.grey.shade500,
                            decoration: lista[i].$2
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
