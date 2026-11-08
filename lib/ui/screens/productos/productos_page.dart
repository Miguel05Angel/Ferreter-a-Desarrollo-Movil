import 'package:flutter/material.dart';
import '../../widgets/inputs/editable_cantidad.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/cotizacion_borrador_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/cards/producto_tarjeta.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../../widgets/cotizacion/boton_listado_cotizacion.dart';
import '../../widgets/media/producto_imagen.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/filtros_catalogo.dart';
import '../../widgets/feedback/reportar_faltante_dialog.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/visual/tilt_3d.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';

/// Catalogo en cuadricula. Al elegir una categoria primero se ven las marcas
/// disponibles; al elegir una marca se despliegan sus productos.
///
/// Con [modoCotizacion] el catalogo sirve para elegir productos que van al
/// LISTADO DE COTIZACION (no al carrito): se pide la cantidad y se permite
/// superar el stock, que luego se resalta en rojo.
class ProductosPage extends StatefulWidget {
  final String categoriaInicial;
  final bool modoCotizacion;

  const ProductosPage({
    super.key,
    this.categoriaInicial = 'todas',
    this.modoCotizacion = false,
  });

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _busqueda = TextEditingController();
  late String _catId = widget.categoriaInicial;
  String? _marca;
  FiltrosCatalogo _filtros = const FiltrosCatalogo();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _elegirCategoria(String id) => setState(() {
        _catId = id;
        _marca = null;
        _filtros = const FiltrosCatalogo();
      });

  Future<void> _abrirFiltros() async {
    final provider = context.read<ProductoProvider>();
    final r = await mostrarFiltrosCatalogo(
      context,
      todos: provider.productos,
      categorias: provider.categorias,
      categoriaActual: _catId,
      actual: _filtros,
    );
    if (r == null) return;
    setState(() {
      if (r.categoriaId != _catId) {
        _catId = r.categoriaId;
        _marca = null;
      }
      _filtros = r.filtros;
    });
  }

  Future<void> _agregarACotizacion(Producto p, Offset origen) async {
    final borrador = context.read<CotizacionBorradorProvider>();
    final cantidad = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaCantidad(
        producto: p,
        enListado: borrador.cantidadDe(p.id),
      ),
    );
    if (cantidad == null || !mounted) return;
    borrador.agregar(p, cantidad);
    VueloAlCarrito.lanzar(
      context,
      tipo: p.tipoVisual,
      colorHex: p.colorHex,
      desde: origen,
      tam: 92,
    );
  }

  void _agregar(Producto p, Offset origen) {
    if (widget.modoCotizacion) {
      _agregarACotizacion(p, origen);
      return;
    }
    final error = context.read<CarritoProvider>().agregar(p, 1);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    VueloAlCarrito.lanzar(
      context,
      tipo: p.tipoVisual,
      colorHex: p.colorHex,
      desde: origen,
      tam: 92,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final todos = provider.productos;
    final enCategoria = _catId == 'todas'
        ? todos
        : todos.where((p) => p.categoriaId == _catId).toList();
    final techo = FiltrosCatalogo.techoDe(todos);
    final texto = _busqueda.text.trim().toLowerCase();

    final lista = enCategoria.where((p) {
      if (_marca != null && p.marca != _marca) return false;
      if (texto.isNotEmpty &&
          !(p.nombre.toLowerCase().contains(texto) ||
              p.codigo.toLowerCase().contains(texto) ||
              p.marca.toLowerCase().contains(texto))) {
        return false;
      }
      return _filtros.acepta(p, techo);
    }).toList();

    final verMarcas =
        _catId != 'todas' && _marca == null && texto.isEmpty && !_filtros.activo;
    final puedeGestionar = Permisos.de(context).puedeGestionarProductos;
    final categoriaActual = _catId == 'todas'
        ? null
        : provider.categoriaDe(_catId);

    return Scaffold(
      appBar: AppBarTaller(
        title: Text(widget.modoCotizacion ? 'Elegir productos' : 'Productos'),
        subtitulo: widget.modoCotizacion ? 'Para la cotizacion' : 'Catalogo',
        mostrarCarrito: !widget.modoCotizacion,
        actions: widget.modoCotizacion
            ? [
                BotonListadoCotizacion(
                    onTap: () => Navigator.of(context).pop()),
              ]
            : null,
      ),
      floatingActionButton: widget.modoCotizacion
          ? Builder(builder: (context) {
              final n = context.watch<CotizacionBorradorProvider>().unidades;
              return FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.request_quote_outlined),
                label: Text(n == 0 ? 'VOLVER' : 'VER LISTADO ($n)'),
              );
            })
          : puedeGestionar
          ? FloatingActionButton.extended(
              onPressed: () =>
                  AppRoutes.push(context, const ProductoFormScreen()),
              icon: const Icon(Icons.add),
              label: const Text('NUEVO'),
            )
          : null,
      body: provider.error
          ? const Center(child: Text('No se pudo cargar el catálogo de Firestore.'))
          : provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '¿Qué herramienta o material buscas hoy?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 12, 0),
            child: BotonReportarFaltante(),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _ChipCategoria(
                  texto: 'Todas',
                  activo: _catId == 'todas',
                  onTap: () => _elegirCategoria('todas'),
                ),
                for (final c in provider.categorias)
                  _ChipCategoria(
                    texto: c.nombre,
                    activo: _catId == c.id,
                    color: c.color,
                    onTap: () => _elegirCategoria(c.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _abrirFiltros,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(_filtros.activo
                      ? 'Filtros (${_filtros.cantidad})'
                      : 'Filtros'),
                ),
                const SizedBox(width: 8),
                if (_filtros.activo)
                  TextButton(
                    onPressed: () =>
                        setState(() => _filtros = const FiltrosCatalogo()),
                    child: const Text('Quitar filtros'),
                  ),
                const Spacer(),
                Text(
                  verMarcas
                      ? '${_marcasDe(enCategoria).length} marcas'
                      : '${lista.length} productos',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (categoriaActual != null && _marca != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.arrow_back, size: 16),
                  label: Text('${categoriaActual.nombre}  >  $_marca'),
                  onPressed: () => setState(() => _marca = null),
                  onDeleted: () => setState(() => _marca = null),
                ),
              ),
            ),
          Expanded(
            child: verMarcas
                ? _CuadriculaMarcas(
                    marcas: _marcasDe(enCategoria),
                    color: categoriaActual!.color,
                    onMarca: (m) => setState(() => _marca = m),
                  )
                : lista.isEmpty
                    ? const EmptyState(
                        icono: Icons.search_off,
                        titulo: 'Sin resultados',
                        mensaje: 'No hay productos con esa busqueda o con los '
                            'filtros seleccionados.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 262,
                        ),
                        itemCount: lista.length,
                        itemBuilder: (context, i) {
                          final p = lista[i];
                          return Entrada3D(
                            delay: Duration(milliseconds: i < 8 ? i * 70 : 0),
                            child: ProductoTarjeta(
                              producto: p,
                              categoria: provider.categoriaDe(p.categoriaId),
                              permitirAgotado: widget.modoCotizacion,
                              onTap: () {
                                if (widget.modoCotizacion) {
                                  _agregarACotizacion(
                                      p,
                                      Offset(
                                          MediaQuery.of(context).size.width /
                                              2,
                                          300));
                                  return;
                                }
                                AppRoutes.push(
                                  context,
                                  ProductoDetalleScreen(productoId: p.id),
                                );
                              },
                              onAgregar: (origen) => _agregar(p, origen),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<_Marca> _marcasDe(List<Producto> productos) {
    final mapa = <String, List<Producto>>{};
    for (final p in productos) {
      mapa.putIfAbsent(p.marca, () => []).add(p);
    }
    final lista = mapa.entries
        .map((e) => _Marca(
              e.key,
              e.value.length,
              e.value.map((p) => p.precioVenta).reduce((a, b) => a < b ? a : b),
            ))
        .toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
    return lista;
  }
}

class _Marca {
  final String nombre;
  final int cantidad;
  final double desde;
  const _Marca(this.nombre, this.cantidad, this.desde);
}

class _CuadriculaMarcas extends StatelessWidget {
  final List<_Marca> marcas;
  final Color color;
  final ValueChanged<String> onMarca;

  const _CuadriculaMarcas({
    required this.marcas,
    required this.color,
    required this.onMarca,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
      itemCount: marcas.length,
      itemBuilder: (context, i) {
        final m = marcas[i];
        return Entrada3D(
          delay: Duration(milliseconds: i < 8 ? i * 70 : 0),
          child: Tilt3D(
            anguloMax: 0.10,
            radioBorde: 16,
            builder: (context, t) => Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onMarca(m.nombre),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.06),
                        color.withOpacity(0.20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: Offset(t.dx * -6, t.dy * -6),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.nombre.isEmpty ? '?' : m.nombre[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        m.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${m.cantidad} ${m.cantidad == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        'desde ${Formatters.soles(m.desde)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color? color;
  final VoidCallback onTap;

  const _ChipCategoria({
    required this.texto,
    required this.activo,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: activo ? base : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activo ? base : Colors.grey.shade400),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                color: activo ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Hoja para elegir la cantidad que se cotiza. Avisa cuando supera el stock.
class _HojaCantidad extends StatefulWidget {
  final Producto producto;
  final int enListado;
  const _HojaCantidad({required this.producto, required this.enListado});

  @override
  State<_HojaCantidad> createState() => _HojaCantidadState();
}

class _HojaCantidadState extends State<_HojaCantidad> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final total = _cantidad + widget.enListado;
    final faltan = total > p.stock ? total - p.stock : 0;
    final rojo = AppTheme.danger;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: const Border(
              top: BorderSide(color: AppTheme.primary, width: 2.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: ProductoImagen(producto: p, size: 50)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(
                          '${Formatters.soles(p.precioVenta)}  |  Stock: ${p.stock}',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed:
                      _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                  icon: const Icon(Icons.remove),
                ),
                EditableCantidad(
                  valor: _cantidad,
                  maximo: 9999,
                  onCambio: (n) => setState(() => _cantidad = n),
                  child: SizedBox(
                  width: 90,
                  child: Text('$_cantidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: faltan > 0 ? rojo : null)),
                )),
                IconButton.outlined(
                  onPressed:
                      _cantidad < 9999 ? () => setState(() => _cantidad++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: faltan > 0
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rojo.withOpacity(oscuro ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: rojo.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Supera el stock: hay ${p.stock} y faltarian $faltan '
                        '${faltan == 1 ? 'unidad' : 'unidades'}. '
                        'Se agregara marcado en rojo.',
                        style: TextStyle(
                            color: rojo,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_cantidad),
                icon: const Icon(Icons.playlist_add),
                label: Text(
                    'AGREGAR AL LISTADO  (${Formatters.soles(p.precioVenta * _cantidad)})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
