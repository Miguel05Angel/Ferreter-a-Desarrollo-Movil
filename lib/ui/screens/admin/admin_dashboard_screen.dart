import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import 'admin_store.dart';
import 'admin_ui.dart';
import 'pedidos_tab.dart';
import 'productos_tab.dart';
import 'trabajadores_tab.dart';
import 'ventas_tab.dart';

/// Panel administrativo que corre en el navegador.
///
/// Lee y escribe directamente en Firestore, por lo que lo que se cambia aqui
/// se ve en los telefonos y al contrario.
///
/// Navegación: barra flotante superior (sin menú lateral). Los datos se
/// escuchan una sola vez en [AdminStore] y las pestañas conservan su estado
/// al cambiar entre ellas.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminStore _store = AdminStore();
  final Set<int> _visitadas = {0};
  int _tab = 0;

  /// `null` = sigue el tema del sistema hasta que el usuario lo cambie.
  bool? _oscuroManual;

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Widget _pestana(int i) => switch (i) {
        0 => ProductosTab(store: _store),
        1 => VentasTab(store: _store),
        2 => PedidosTab(store: _store),
        _ => TrabajadoresTab(store: _store),
      };

  Future<void> _salir(BuildContext context) async {
    final ok = await dialogo<bool>(
      context,
      (_) => const ConfirmarDialogo(
        icono: Icons.logout_rounded,
        color: Tono.acento,
        titulo: 'Cerrar sesión',
        mensaje: '¿Quieres salir del panel administrativo?',
        textoConfirmar: 'Cerrar sesión',
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthProvider>().cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = _oscuroManual ??
        (MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final nombre = context.watch<AuthProvider>().usuarioActual?.nombre ??
        'Administrador';

    return AnimatedTheme(
      data: temaAdmin(oscuro),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: context.fondo,
            body: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      for (var i = 0; i < 4; i++)
                        _visitadas.contains(i)
                            ? _Fundido(
                                key: ValueKey('tab-$i'),
                                activo: i == _tab,
                                child: _pestana(i),
                              )
                            : const SizedBox.shrink(),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _BarraNavegacion(
                    indice: _tab,
                    nombre: nombre,
                    oscuro: oscuro,
                    onTab: (i) => setState(() {
                      _tab = i;
                      _visitadas.add(i);
                    }),
                    onTema: () => setState(() => _oscuroManual = !oscuro),
                    onSalir: () => _salir(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fundido corto cada vez que una pestaña pasa a ser la activa.
class _Fundido extends StatefulWidget {
  const _Fundido({super.key, required this.activo, required this.child});

  final bool activo;
  final Widget child;

  @override
  State<_Fundido> createState() => _FundidoState();
}

class _FundidoState extends State<_Fundido> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    if (widget.activo) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _Fundido old) {
    super.didUpdateWidget(old);
    if (widget.activo && !old.activo) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curva,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curva.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curva.value) * 10),
          child: child,
        ),
      ),
    );
  }
}

// ===========================================================================
// BARRA FLOTANTE
// ===========================================================================

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.indice,
    required this.nombre,
    required this.oscuro,
    required this.onTab,
    required this.onTema,
    required this.onSalir,
  });

  final int indice;
  final String nombre;
  final bool oscuro;
  final ValueChanged<int> onTab;
  final VoidCallback onTema;
  final VoidCallback onSalir;

  static const _items = [
    SegItem(icono: Icons.inventory_2_outlined, texto: 'Productos'),
    SegItem(icono: Icons.point_of_sale_rounded, texto: 'Ventas'),
    SegItem(icono: Icons.local_shipping_outlined, texto: 'Pedidos'),
    SegItem(icono: Icons.groups_outlined, texto: 'Trabajadores'),
  ];
  static const _soloIconos = [
    SegItem(icono: Icons.inventory_2_outlined),
    SegItem(icono: Icons.point_of_sale_rounded),
    SegItem(icono: Icons.local_shipping_outlined),
    SegItem(icono: Icons.groups_outlined),
  ];
  static const _nombres = ['Productos', 'Ventas', 'Pedidos a proveedores', 'Trabajadores'];

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 820;
    final marcaCompleta = ancho >= 1040;
    final mostrarMarca = ancho >= 560;

    final cuerpo = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: context.panel.withOpacity(context.oscuro ? 0.78 : 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.linea),
      ),
      child: Row(
        children: [
          if (mostrarMarca) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Tono.acento,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.handyman_rounded,
                  size: 19, color: Colors.white),
            ),
            if (marcaCompleta) ...[
              const SizedBox(width: 11),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El Constructor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: -0.3,
                      color: context.tinta,
                    ),
                  ),
                  Text(
                    'Panel de administración',
                    style: TextStyle(fontSize: 11, color: context.tenue),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Segmentos(
                  items: compacto ? _soloIconos : _items,
                  tooltips: _nombres,
                  indice: indice,
                  anchoItem: compacto ? 52 : 128,
                  alto: 40,
                  invertido: true,
                  onCambio: onTab,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: oscuro ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
            child: IconButton(
              onPressed: onTema,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  key: ValueKey(oscuro),
                  color: context.tinta,
                  size: 21,
                ),
              ),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Cuenta',
            offset: const Offset(0, 48),
            color: context.panel,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.linea),
            ),
            onSelected: (v) {
              if (v == 1) onSalir();
            },
            itemBuilder: (_) => [
              PopupMenuItem<int>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.tinta,
                      ),
                    ),
                    Text(
                      'Administrador',
                      style: TextStyle(fontSize: 12, color: context.tenue),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 19, color: context.tinta),
                    const SizedBox(width: 10),
                    Text('Cerrar sesión', style: TextStyle(color: context.tinta)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.panel2,
                shape: BoxShape.circle,
                border: Border.all(color: context.linea),
              ),
              child: Text(
                inicial(nombre),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: context.tinta,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(ancho < 600 ? 10 : 20, 14, ancho < 600 ? 10 : 20, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.oscuro ? 0.45 : 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: cuerpo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
