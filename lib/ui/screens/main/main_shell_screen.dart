import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/carrito_provider.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../carrito/carrito_page.dart';
import '../home/inicio_page.dart';
import '../perfil/perfil_page.dart';
import '../productos/productos_page.dart';
import '../ventas/ventas_page.dart';

/// Permite que cualquier pantalla cambie de pestana del shell
/// (por ejemplo, "Ver productos" desde Inicio).
class ShellNavegacion {
  ShellNavegacion._();

  static final ValueNotifier<int> indice = ValueNotifier<int>(0);

  static void irA(int i) => indice.value = i;
}

/// Estructura principal con barra de navegacion propia: indicador naranja
/// que se desliza, iconos que saltan y contador en el carrito.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transicion;
  int _indice = 0;
  int _direccion = 1;

  final _paginas = const [
    InicioPage(),
    ProductosPage(),
    VentasPage(),
    CarritoPage(),
    PerfilPage(),
  ];

  static const _items = <_ItemNav>[
    _ItemNav(Icons.home_outlined, Icons.home, 'Inicio'),
    _ItemNav(Icons.inventory_2_outlined, Icons.inventory_2, 'Productos'),
    _ItemNav(Icons.receipt_long_outlined, Icons.receipt_long, 'Ventas'),
    _ItemNav(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Carrito'),
    _ItemNav(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _transicion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    );
    ShellNavegacion.indice.value = 0;
    ShellNavegacion.indice.addListener(_alCambiarExterno);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => CarritoFlotante.activo.value = true);
  }

  @override
  void dispose() {
    ShellNavegacion.indice.removeListener(_alCambiarExterno);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => CarritoFlotante.activo.value = false);
    _transicion.dispose();
    super.dispose();
  }

  void _alCambiarExterno() {
    if (ShellNavegacion.indice.value != _indice) {
      _ir(ShellNavegacion.indice.value);
    }
  }

  void _ir(int i) {
    if (i == _indice) return;
    setState(() {
      _direccion = i > _indice ? 1 : -1;
      _indice = i;
    });
    ShellNavegacion.indice.value = i;
    _transicion.forward(from: 0);
    // En la pestana del carrito no hace falta la burbuja
    CarritoFlotante.activo.value = i != 3;
  }

  @override
  Widget build(BuildContext context) {
    final enCarrito = context.watch<CarritoProvider>().cantidadItems;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _transicion,
        child: IndexedStack(index: _indice, children: _paginas),
        builder: (context, child) {
          final v = Curves.easeOutCubic.transform(_transicion.value);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateY(_direccion * (1 - v) * 0.22);
          return Opacity(
            opacity: 0.35 + 0.65 * v,
            child: Transform(
              alignment:
                  _direccion > 0 ? Alignment.centerLeft : Alignment.centerRight,
              transform: m,
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: _BarraNav(
        indice: _indice,
        items: _items,
        enCarrito: enCarrito,
        onTap: _ir,
      ),
    );
  }
}

class _ItemNav {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;

  const _ItemNav(this.icono, this.iconoActivo, this.etiqueta);
}

class _BarraNav extends StatelessWidget {
  final int indice;
  final List<_ItemNav> items;
  final int enCarrito;
  final ValueChanged<int> onTap;

  const _BarraNav({
    required this.indice,
    required this.items,
    required this.enCarrito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.grafito,
        border: Border(top: BorderSide(color: Color(0xFF2C3238))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, c) {
              final ancho = c.maxWidth / items.length;
              return Stack(
                children: [
                  // Indicador que se desliza entre pestanas
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: ancho * indice + ancho * 0.22,
                    top: 0,
                    width: ancho * 0.56,
                    height: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(4)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _BotonNav(
                            item: items[i],
                            activo: i == indice,
                            insignia: i == 3 ? enCarrito : 0,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BotonNav extends StatelessWidget {
  final _ItemNav item;
  final bool activo;
  final int insignia;
  final VoidCallback onTap;

  const _BotonNav({
    required this.item,
    required this.activo,
    required this.insignia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppTheme.primary : const Color(0xFF8A9199);
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primary.withOpacity(0.15),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: activo ? 1.18 : 1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    activo ? item.iconoActivo : item.icono,
                    key: ValueKey(activo),
                    color: color,
                    size: 25,
                  ),
                ),
              ),
              Positioned(
                right: -9,
                top: -6,
                child: AnimatedScale(
                  scale: insignia > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 17, minHeight: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(9),
                      border:
                          Border.all(color: AppTheme.grafito, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$insignia',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.grafito,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.etiqueta.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              letterSpacing: 0.8,
              fontWeight: activo ? FontWeight.w900 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
