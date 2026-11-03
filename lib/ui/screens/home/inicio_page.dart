import 'package:flutter/material.dart';

import '../../widgets/media/producto_imagen.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/categoria.dart';
import '../../../data/models/producto.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/proveedor_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/cards/category_card.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../../widgets/inputs/buscador_productos.dart';
import '../../widgets/feedback/reportar_faltante_dialog.dart';
import '../welcome/welcome_screen.dart';
import '../../widgets/layout/section_header.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';
import '../../widgets/visual/tilt_3d.dart';
import '../categorias/categorias_screen.dart';
import '../clientes/clientes_page.dart';
import '../cotizaciones/cotizacion_form_screen.dart';
import '../cotizaciones/cotizaciones_page.dart';
import '../main/main_shell_screen.dart';
import '../productos/producto_detalle_screen.dart';
import '../productos/reposicion_screen.dart';
import '../proveedores/proveedores_page.dart';

Color _naranjaTexto(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppTheme.primary
        : const Color(0xFFD95800);

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'BUENOS DIAS';
    if (h < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  /// Un producto por tipo de ilustracion, para que el carrusel sea variado.
  List<Producto> _destacados(List<Producto> todos) {
    final vistos = <String>{};
    final res = <Producto>[];
    for (final p in todos) {
      if (p.agotado) continue;
      if (vistos.add(p.tipoVisual)) res.add(p);
      if (res.length == 8) break;
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>();
    final clientes = context.watch<ClienteProvider>();
    final ventas = context.watch<VentaProvider>();
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final permisos = Permisos.de(context);
    final cotizaciones = context.watch<CotizacionProvider>();
    final proveedores = context.watch<ProveedorProvider>();
    final misVentas = ventas.visiblesPara(
        esAdmin: permisos.esAdmin, usuarioId: usuario?.id ?? '');

    final stockBajo = productos.productos.where((p) => p.stockBajo).toList();
    final destacados = _destacados(productos.productos);
    final nombre = usuario?.nombre.split(' ').first ?? 'Invitado';
    final inicial = (usuario?.nombre.isNotEmpty ?? false)
        ? usuario!.nombre[0].toUpperCase()
        : '?';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ================================================ cabecera
          Container(
            color: AppTheme.grafito,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: PlanoPainter()),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FadeSlide(
                      inicio: const Offset(0, -0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _saludo(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        text: nombre,
                                        children: const [
                                          TextSpan(
                                            text: '.',
                                            style: TextStyle(
                                                color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                        color: AppTheme.hueso,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: permisos.esAdmin
                                            ? AppTheme.amarilloSenal
                                            : const Color(0xFF2E3A44),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (usuario?.rol ?? 'Vendedor')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          letterSpacing: 1.6,
                                          fontWeight: FontWeight.w900,
                                          color: permisos.esAdmin
                                              ? AppTheme.grafito
                                              : AppTheme.hueso,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const BotonCarrito(),
                              const SizedBox(width: 6),
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: const ShapeDecoration(
                                  color: AppTheme.primary,
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(16)),
                                  ),
                                ),
                                child: Text(
                                  inicial,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.grafito,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Tablero del dia
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _Mono(permisos.esAdmin ? 'VENTAS DE HOY' : 'MIS VENTAS DE HOY',
                                          const Color(0x99EDE8DF)),
                                      const SizedBox(height: 4),
                                      TweenAnimationBuilder<double>(
                                        tween:
                                            Tween(begin: 0, end: VentaProvider.totalHoyEn(misVentas)),
                                        duration:
                                            const Duration(milliseconds: 1500),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            Formatters.soles(v),
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  color: const Color(0xFF3A4148),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _MiniDato(
                                          valor: productos.totalProductos,
                                          etiqueta: 'PRODUCTOS'),
                                      const SizedBox(height: 7),
                                      _MiniDato(
                                          valor: clientes.totalClientes,
                                          etiqueta: 'CLIENTES'),
                                      const SizedBox(height: 7),
                                      _MiniDato(
                                          valor: productos.productosStockBajo,
                                          etiqueta: 'STOCK BAJO',
                                          alerta: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const FranjaPeligro(alto: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================ buscador
                const SizedBox(height: 20),
                const FadeSlide(
                  delay: Duration(milliseconds: 200),
                  child: BuscadorProductos(),
                ),
                const FadeSlide(
                  delay: Duration(milliseconds: 260),
                  child: BotonReportarFaltante(),
                ),
                FadeSlide(
                  delay: const Duration(milliseconds: 320),
                  child: _BotonAsistente(
                    onTap: () =>
                        AppRoutes.push(context, const WelcomeScreen()),
                  ),
                ),

                // ============================================ destacados
                if (destacados.isNotEmpty) ...[
                  SectionHeader(
                    titulo: 'Lo más recomendado en calidad y precio',
                    textoAccion: 'Ver todo',
                    onAccion: () => ShellNavegacion.irA(1),
                  ),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: destacados.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final p = destacados[i];
                        return FadeSlide(
                          delay: Duration(milliseconds: 200 + i * 90),
                          inicio: const Offset(0.35, 0),
                          child: _TarjetaDestacado(
                            producto: p,
                            categoria: productos.categoriaDe(p.categoriaId),
                            onTap: () => AppRoutes.push(
                              context,
                              ProductoDetalleScreen(productoId: p.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // ============================================ categorias
                SectionHeader(
                  titulo: 'Categorias',
                  textoAccion: 'Ver todo',
                  onAccion: () =>
                      AppRoutes.push(context, const CategoriasScreen()),
                ),
                SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 4),
                    itemCount: productos.categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final Categoria c = productos.categorias[i];
                      return FadeSlide(
                        delay: Duration(milliseconds: 100 + i * 70),
                        inicio: const Offset(0.3, 0),
                        child: CategoryCard(
                          categoria: c,
                          cantidad: productos.productos
                              .where((p) => p.categoriaId == c.id)
                              .length,
                          onTap: () => AppRoutes.push(
                              context, const CategoriasScreen()),
                        ),
                      );
                    },
                  ),
                ),

                // ============================================ cotizaciones
                const SectionHeader(titulo: 'Cotizaciones'),
                _TarjetaCotizaciones(
                  total: cotizaciones.totalCotizaciones,
                  onAbrir: () =>
                      AppRoutes.push(context, const CotizacionesPage()),
                  onNueva: () =>
                      AppRoutes.push(context, const CotizacionFormScreen()),
                ),

                // ============================================== comunidad
                const SectionHeader(titulo: 'Comunidad'),
                _TarjetaComunidad(
                  clientes: clientes.totalClientes,
                  proveedores: permisos.puedeVerProveedores
                      ? proveedores.totalProveedores
                      : null,
                  onClientes: () =>
                      AppRoutes.push(context, const ClientesPage()),
                  onProveedores: () =>
                      AppRoutes.push(context, const ProveedoresPage()),
                ),

                // ========================================= alertas stock
                if (stockBajo.isNotEmpty) ...[
                  SectionHeader(
                    titulo: 'Alertas de stock',
                    textoAccion: 'Ver productos',
                    onAccion: () => ShellNavegacion.irA(1),
                  ),
                  SizedBox(
                    height: 262,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: stockBajo.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => FadeSlide(
                        delay: Duration(milliseconds: 100 + i * 100),
                        inicio: const Offset(0.35, 0),
                        child: _TarjetaAlerta(
                          producto: stockBajo[i],
                          puedeReponer: permisos.puedeSolicitarReposicion,
                          onReponer: () => AppRoutes.push(
                            context,
                            ReposicionScreen(productoId: stockBajo[i].id),
                          ),
                          onTap: () => AppRoutes.push(
                            context,
                            ProductoDetalleScreen(productoId: stockBajo[i].id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================== piezas

class _Mono extends StatelessWidget {
  final String texto;
  final Color color;

  const _Mono(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10.5,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Dato pequeno del tablero con contador animado.
class _MiniDato extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final bool alerta;

  const _MiniDato({
    required this.valor,
    required this.etiqueta,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        alerta && valor > 0 ? const Color(0xFFFF5252) : AppTheme.hueso;
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: valor.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 19,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        Expanded(
          child: _Mono(etiqueta,
              alerta && valor > 0 ? color : const Color(0x99EDE8DF)),
        ),
      ],
    );
  }
}

/// Tarjeta del carrusel: el producto "flota" sobre su ficha y se mueve con
/// el dedo (paralaje 3D).
class _TarjetaDestacado extends StatelessWidget {
  final Producto producto;
  final Categoria categoria;
  final VoidCallback onTap;

  const _TarjetaDestacado({
    required this.producto,
    required this.categoria,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 172,
      child: Tilt3D(
        anguloMax: 0.16,
        radioBorde: 16,
        builder: (context, t) => Material(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 124,
                  width: double.infinity,
                  color: categoria.color.withOpacity(oscuro ? 0.18 : 0.12),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 10,
                        top: 9,
                        child: Text(
                          producto.codigo,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: Offset(t.dx * -9, t.dy * -9),
                          child: Transform.scale(
                            scale: 1 + t.distance * 0.12,
                            child: ProductoImagen(producto: producto, size: 100, sombra: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.soles(producto.precioVenta),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _naranjaTexto(context),
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
    );
  }
}

/// Acceso principal y siempre a la mano a las cotizaciones.
class _TarjetaCotizaciones extends StatelessWidget {
  final int total;
  final VoidCallback onAbrir;
  final VoidCallback onNueva;

  const _TarjetaCotizaciones({
    required this.total,
    required this.onAbrir,
    required this.onNueva,
  });

  @override
  Widget build(BuildContext context) {
    return Tilt3D(
      anguloMax: 0.08,
      radioBorde: 18,
      builder: (context, t) => Material(
        color: AppTheme.primary,
        clipBehavior: Clip.antiAlias,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6), bottomRight: Radius.circular(22)),
        ),
        elevation: 4,
        shadowColor: AppTheme.primary.withOpacity(0.5),
        child: InkWell(
          onTap: onAbrir,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.grafito,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Transform.translate(
                    offset: Offset(t.dx * -3, t.dy * -3),
                    child: const Icon(Icons.request_quote,
                        size: 30, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COTIZACIONES',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.grafito,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        total == 0
                            ? 'Crea, edita y comparte presupuestos en PDF'
                            : '$total ${total == 1 ? 'presupuesto' : 'presupuestos'}  |  buscalos por DNI o RUC',
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: Color(0xE615181B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.grafito,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onNueva,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: AppTheme.primary),
                          SizedBox(width: 3),
                          Text('NUEVA',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clientes y proveedores reunidos en un solo modulo.
class _TarjetaComunidad extends StatelessWidget {
  final int clientes;
  final int? proveedores; // null = sin permiso
  final VoidCallback onClientes;
  final VoidCallback onProveedores;

  const _TarjetaComunidad({
    required this.clientes,
    required this.proveedores,
    required this.onClientes,
    required this.onProveedores,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro;

    Widget mitad({
      required IconData icono,
      required Color color,
      required String titulo,
      required String detalle,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: color, size: 23),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(detalle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.grafito,
            child: const Row(
              children: [
                Icon(Icons.groups_2_outlined,
                    size: 17, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'TU RED DE CONTACTOS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                    color: Color(0xCCEDE8DF),
                  ),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                mitad(
                  icono: Icons.people_alt_outlined,
                  color: const Color(0xFF546E7A),
                  titulo: 'Clientes',
                  detalle: '$clientes registrados',
                  onTap: onClientes,
                ),
                if (proveedores != null) ...[
                  VerticalDivider(width: 1, color: borde),
                  mitad(
                    icono: Icons.local_shipping_outlined,
                    color: const Color(0xFF0277BD),
                    titulo: 'Proveedores',
                    detalle: '$proveedores registrados',
                    onTap: onProveedores,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de alerta: oscura, con franja de obra, producto flotando sobre
/// un halo rojo y un medidor segmentado del stock que queda.
class _TarjetaAlerta extends StatelessWidget {
  final Producto producto;
  final bool puedeReponer;
  final VoidCallback onReponer;
  final VoidCallback onTap;

  const _TarjetaAlerta({
    required this.producto,
    required this.puedeReponer,
    required this.onReponer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const rojo = Color(0xFFFF5252);
    final llenos = producto.stock.clamp(0, 5).toInt();

    return SizedBox(
      width: 178,
      child: Tilt3D(
        anguloMax: 0.16,
        radioBorde: 16,
        builder: (context, t) => Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const ShapeDecoration(
              color: AppTheme.grafito,
              shape: BeveledRectangleBorder(
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(24)),
                side: BorderSide(color: Color(0x99FF5252), width: 1.6),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const BeveledRectangleBorder(
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FranjaPeligro(alto: 7),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        const _PuntoAlerta(),
                        const SizedBox(width: 7),
                        const Text(
                          'REPONER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w900,
                            color: rojo,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          producto.codigo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Color(0x80EDE8DF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0x40FF5252), Color(0x00FF5252)],
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(t.dx * -8, t.dy * -8),
                          child: ProductoImagen(producto: producto, size: 78, sombra: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.hueso,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Expanded(
                                child: Container(
                                  height: 6,
                                  margin:
                                      EdgeInsets.only(right: i == 4 ? 0 : 3),
                                  decoration: BoxDecoration(
                                    color: i < llenos
                                        ? rojo
                                        : const Color(0xFF2E353B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          producto.stock <= 0
                              ? 'AGOTADO'
                              : 'QUEDAN ${producto.stock} ${producto.unidad.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: rojo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'TOCA PARA VER LA FICHA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                            color: Color(0x99EDE8DF),
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
      ),
    );
  }
}

/// Punto rojo que late para llamar la atencion.
class _PuntoAlerta extends StatefulWidget {
  const _PuntoAlerta();

  @override
  State<_PuntoAlerta> createState() => _PuntoAlertaState();
}

class _PuntoAlertaState extends State<_PuntoAlerta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5252).withOpacity(0.35 + 0.5 * _c.value),
              blurRadius: 4 + 8 * _c.value,
              spreadRadius: 1 + 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Acceso directo al asistente ferretero, justo debajo del buscador.
class _BotonAsistente extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonAsistente({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Material(
        color: AppTheme.grafito,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
          side: BorderSide(color: AppTheme.primary, width: 1.6),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('✨ Recomiéndame qué comprar para mi obra',
                      style: TextStyle(
                          color: AppTheme.hueso,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
                const Icon(Icons.arrow_forward, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
