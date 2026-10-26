import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contacto_service.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/proveedor_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../mapa/mapa_screen.dart';
import 'proveedor_form_screen.dart';

class ProveedoresPage extends StatelessWidget {
  const ProveedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProveedorProvider>();
    if (!Permisos.de(context).puedeVerProveedores) {
      return const AccesoRestringido(
        titulo: 'Proveedores',
        detalle: 'La gestion de proveedores es solo para el Administrador.',
      );
    }

    return Scaffold(
      appBar: AppBarTaller(
          subtitulo: 'Abastecimiento', title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRoutes.push(context, const ProveedorFormScreen()),
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Nuevo'),
      ),
      body: provider.proveedores.isEmpty
          ? const EmptyState(
              icono: Icons.local_shipping_outlined,
              titulo: 'Sin proveedores',
              mensaje: 'Registra los proveedores de los productos '
                  'que compra la ferreteria.',
              textoBoton: 'Agregar proveedor',
              onAccion: null,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: provider.proveedores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final p = provider.proveedores[i];
                return FadeSlide(
                  delay: Duration(milliseconds: i < 8 ? i * 70 : 0),
                  child: _FichaProveedor(
                    proveedor: p,
                    onEditar: () => AppRoutes.push(
                        context, ProveedorFormScreen(proveedor: p)),
                    onEliminar: () {
                      ConfirmDialog.mostrar(
                        context,
                        titulo: 'Eliminar proveedor',
                        mensaje: '¿Eliminar a ${p.nombre}?',
                        textoConfirmar: 'Eliminar',
                        onConfirmar: () {
                          provider.eliminar(p.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proveedor eliminado'),
                              backgroundColor: Color(0xFF15181B),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// Ficha de perfil de un proveedor: cabecera con avatar, datos clave siempre
/// visibles y, al tocarla, se despliegan los productos y las acciones.
class _FichaProveedor extends StatefulWidget {
  final Proveedor proveedor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _FichaProveedor({
    required this.proveedor,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_FichaProveedor> createState() => _FichaProveedorState();
}

class _FichaProveedorState extends State<_FichaProveedor> {
  static const Color _azul = Color(0xFF0277BD);
  bool _abierta = false;
  bool _presionada = false;

  String get _iniciales {
    final partes = widget.proveedor.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  bool get _tieneCoordenadas =>
      widget.proveedor.latitud != null && widget.proveedor.longitud != null;

  @override
  Widget build(BuildContext context) {
    final p = widget.proveedor;
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final superficie = tema.colorScheme.surface;
    final borde = oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro;
    final textoSuave = oscuro ? const Color(0xB3EDE8DF) : Colors.grey.shade700;

    return AnimatedScale(
      scale: _presionada ? 0.975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _presionada = true),
        onTapUp: (_) => setState(() => _presionada = false),
        onTapCancel: () => setState(() => _presionada = false),
        onTap: () => setState(() => _abierta = !_abierta),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: superficie,
            shape: BeveledRectangleBorder(
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(26)),
              side: BorderSide(
                color: _abierta ? AppTheme.primary : borde,
                width: _abierta ? 1.8 : 1.1,
              ),
            ),
            shadows: [
              BoxShadow(
                color: _abierta
                    ? AppTheme.primary.withOpacity(0.22)
                    : const Color(0x22000000),
                blurRadius: _abierta ? 18 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------- cabecera
              Container(
                color: AppTheme.grafito,
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  children: [
                    Hero(
                      tag: 'prov-${p.id}',
                      child: Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: const ShapeDecoration(
                          color: AppTheme.primary,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16)),
                          ),
                        ),
                        child: Text(
                          _iniciales,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.grafito,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.hueso,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RUC ${p.ruc}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              letterSpacing: 0.8,
                              color: Color(0x99EDE8DF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _abierta ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 28, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------- datos clave
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: _azul),
                        const SizedBox(width: 8),
                        Text(p.telefono,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textoSuave)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: _azul),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.direccion,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.3,
                                  color: textoSuave)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Insignia(
                          icono: Icons.inventory_2_outlined,
                          texto:
                              '${p.productos.length} ${p.productos.length == 1 ? 'PRODUCTO' : 'PRODUCTOS'}',
                          color: _azul,
                        ),
                        _Insignia(
                          icono: _tieneCoordenadas
                              ? Icons.my_location
                              : Icons.location_searching,
                          texto: _tieneCoordenadas
                              ? 'UBICACION EXACTA'
                              : 'UBICADO POR DIRECCION',
                          color: _tieneCoordenadas
                              ? AppTheme.success
                              : const Color(0xFFB8860B),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------- desplegable
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _abierta
                      ? _Detalle(
                          proveedor: p,
                          onEditar: widget.onEditar,
                          onEliminar: widget.onEliminar,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _Detalle({
    required this.proveedor,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final p = proveedor;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final linea = oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: linea, height: 1),
            const SizedBox(height: 12),
            if (p.productos.isNotEmpty) ...[
              const Text(
                'PRODUCTOS QUE PROVEE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < p.productos.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 260 + i * 90),
                      curve: Curves.easeOutBack,
                      builder: (context, v, child) => Transform.scale(
                        scale: v.clamp(0.0, 1.2),
                        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0277BD).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  const Color(0xFF0277BD).withOpacity(0.25)),
                        ),
                        child: Text(
                          p.productos[i],
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF0277BD)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: _Accion(
                    icono: Icons.phone,
                    texto: 'LLAMAR',
                    color: AppTheme.success,
                    onTap: () =>
                        ContactoService.llamar(context, p.telefono),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Accion(
                    icono: Icons.chat_bubble_outline,
                    texto: 'WHATSAPP',
                    color: const Color(0xFF128C7E),
                    onTap: () => ContactoService.whatsapp(
                      context,
                      p.telefono,
                      'Hola ${p.nombre}, te escribimos de Ferreteria El Constructor.',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Accion(
                    icono: Icons.navigation_outlined,
                    texto: 'COMO LLEGAR',
                    color: AppTheme.primary,
                    onTap: () => AppRoutesMapa.abrir(context, p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.danger),
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Insignia extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Insignia(
      {required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _Accion({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      shape: BeveledRectangleBorder(
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(12)),
        side: BorderSide(color: color.withOpacity(0.55), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icono, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                texto,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
