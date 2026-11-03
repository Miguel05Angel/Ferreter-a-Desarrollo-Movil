import 'package:flutter/material.dart';
import '../../widgets/inputs/editable_cantidad.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/cotizacion.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/venta.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/cotizacion_borrador_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../services/cotizacion_pdf.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/cotizacion/confirmar_cambios_dialog.dart';
import '../../widgets/cotizacion/cotizacion_lista_dialog.dart';
import '../../widgets/cotizacion/perfil_cliente_sheet.dart';
import '../../widgets/inputs/buscador_cliente_documento.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/media/producto_imagen.dart';
import '../clientes/cliente_form_screen.dart';
import '../productos/productos_page.dart';
import 'cotizacion_documento_screen.dart';

/// Formulario de cotizacion. Trabaja siempre sobre un BORRADOR: los
/// productos se eligen en el catalogo de la tienda y llegan al listado de
/// cotizacion (no al carrito). Sirve tanto para crear como para editar.
class CotizacionFormScreen extends StatefulWidget {
  final Cotizacion? cotizacion;

  const CotizacionFormScreen({super.key, this.cotizacion});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  String? _clienteId;
  String? _errorCliente;
  int _validez = AppConstants.diasValidez.first;
  bool _cargando = false;
  bool _generando = false;
  bool _listadoAbierto = true;

  bool get _esEdicion => widget.cotizacion != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cotizacion;
    if (c != null) {
      _validez = c.validezDias;
      final clientes = context.read<ClienteProvider>().clientes;
      _clienteId = _buscarClienteId(clientes, c);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final borrador = context.read<CotizacionBorradorProvider>();
      if (c == null) {
        borrador.limpiar();
      } else {
        final productos = context.read<ProductoProvider>();
        borrador.cargar([
          for (final i in c.items)
            LineaCotizacion(
              producto: productos.buscarPorId(i.productoId) ??
                  Producto(
                    id: i.productoId,
                    codigo: '',
                    nombre: i.nombre,
                    descripcion: '',
                    categoriaId: '',
                    marca: '',
                    unidad: 'Unidad',
                    precioVenta: i.precioUnitario,
                    stock: 0,
                  ),
              cantidad: i.cantidad,
              precio: i.precioUnitario,
            ),
        ], editando: c.id);
      }
    });
  }

  String? _buscarClienteId(List<Cliente> clientes, Cotizacion c) {
    for (final x in clientes) {
      if (c.clienteId.isNotEmpty && x.id == c.clienteId) return x.id;
    }
    for (final x in clientes) {
      if (x.nombre.trim().toLowerCase() == c.clienteNombre.trim().toLowerCase()) {
        return x.id;
      }
    }
    return null;
  }

  Cliente? _cliente(List<Cliente> lista) {
    if (_clienteId == null) return null;
    for (final c in lista) {
      if (c.id == _clienteId) return c;
    }
    return null;
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: AppTheme.danger),
    );
  }

  Future<void> _elegirCliente() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ClienteProvider>.value(
        value: context.read<ClienteProvider>(),
        child: _HojaClientes(seleccionado: _clienteId),
      ),
    );
    if (id != null) {
      setState(() {
        _clienteId = id;
        _errorCliente = null;
      });
    }
  }

  Future<void> _crearCliente() async {
    final provider = context.read<ClienteProvider>();
    final antes = provider.clientes.map((c) => c.id).toSet();
    await AppRoutes.push(context, const ClienteFormScreen());
    if (!mounted) return;
    for (final c in provider.clientes) {
      if (!antes.contains(c.id)) {
        setState(() {
          _clienteId = c.id;
          _errorCliente = null;
        });
        break;
      }
    }
  }

  Future<void> _irAlCatalogo() async {
    await AppRoutes.push(context, const ProductosPage(modoCotizacion: true));
  }

  /// Si hay productos que superan el stock avisa con el detalle exacto.
  /// Devuelve true si se puede continuar.
  Future<bool> _confirmarFaltantes() async {
    final borrador = context.read<CotizacionBorradorProvider>();
    final faltantes = borrador.conFaltante;
    if (faltantes.isEmpty) return true;

    final r = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoFaltantes(lineas: faltantes),
    );
    if (r == 'ajustar') {
      for (final l in faltantes) {
        if (l.producto.stock > 0) {
          borrador.fijarCantidad(l.producto.id, l.producto.stock);
        }
      }
      // Lo que no tiene ninguna unidad sigue marcado en rojo: se revisa.
      if (borrador.conFaltante.isNotEmpty && mounted) {
        _mensaje('Algunos productos no tienen stock: revisalos o cotiza igual');
        return false;
      }
      return true;
    }
    return r == 'continuar';
  }

  Future<Cotizacion?> _guardar() async {
    final borrador = context.read<CotizacionBorradorProvider>();
    final clientes = context.read<ClienteProvider>().clientes;
    final cliente = _cliente(clientes);

    if (cliente == null) {
      setState(() => _errorCliente = 'Selecciona o crea un cliente');
      _mensaje('Falta el cliente de la cotizacion');
      return null;
    }
    if (borrador.vacio) {
      _mensaje('Agrega al menos un producto desde la tienda');
      return null;
    }
    if (!await _confirmarFaltantes() || !mounted) return null;

    final items = [
      for (final l in borrador.lineas)
        ItemVenta(
          productoId: l.producto.id,
          nombre: l.producto.nombre,
          cantidad: l.cantidad,
          precioUnitario: l.precio,
        ),
    ];
    final provider = context.read<CotizacionProvider>();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return null;

    if (_esEdicion) {
      return provider.actualizar(
        id: widget.cotizacion!.id,
        clienteNombre: cliente.nombre,
        items: items,
        validezDias: _validez,
        clienteId: cliente.id,
        tipoDocumento: cliente.tipoDocumento,
        documento: cliente.documento,
      );
    }
    return provider.registrar(
      clienteNombre: cliente.nombre,
      items: items,
      validezDias: _validez,
      clienteId: cliente.id,
      tipoDocumento: cliente.tipoDocumento,
      documento: cliente.documento,
    );
  }

  /// Resumen de lo modificado respecto a la cotizacion original (vacio si
  /// no hay cambios o si es una cotizacion nueva).
  List<String> _cambios(CotizacionBorradorProvider b) {
    final c = widget.cotizacion;
    if (c == null || b.editandoId != c.id) return const [];
    final r = <String>[];
    final clientes = context.read<ClienteProvider>().clientes;
    if (_clienteId != _buscarClienteId(clientes, c)) {
      final nuevo = clientes.where((x) => x.id == _clienteId);
      r.add('~ Cliente: ${c.clienteNombre} → ${nuevo.isEmpty ? 'sin cliente' : nuevo.first.nombre}');
    }
    if (_validez != c.validezDias) {
      r.add('~ Validez: ${c.validezDias} → $_validez días');
    }
    final antes = {for (final i in c.items) i.productoId: i};
    final ahora = {for (final l in b.lineas) l.producto.id: l};
    for (final l in b.lineas) {
      final a = antes[l.producto.id];
      if (a == null) {
        r.add('+ ${l.cantidad} x ${l.producto.nombre}');
      } else if (a.cantidad != l.cantidad) {
        r.add('~ ${l.producto.nombre}: ${a.cantidad} → ${l.cantidad} und');
      }
    }
    for (final i in c.items) {
      if (!ahora.containsKey(i.productoId)) r.add('- ${i.cantidad} x ${i.nombre}');
    }
    return r;
  }

  /// Boton principal: crea, cancela (sin cambios) o pide doble confirmacion.
  Future<void> _alPulsarPrincipal(List<String> cambios) async {
    if (!_esEdicion) return _cotizar();
    if (cambios.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final r = await ConfirmarCambiosDialog.mostrar(context, cambios: cambios);
    if (r == 'aplicar' && mounted) await _cotizar();
  }

  /// Salir de la pantalla con cambios sin guardar.
  Future<void> _alIntentarSalir(List<String> cambios) async {
    final r = await ConfirmarCambiosDialog.mostrar(context,
        cambios: cambios, permitirDescartar: true);
    if (!mounted) return;
    if (r == 'aplicar') {
      await _cotizar();
    } else if (r == 'descartar') {
      context.read<CotizacionBorradorProvider>().limpiar();
      Navigator.of(context).pop();
    }
  }

  Future<void> _cotizar() async {
    setState(() => _cargando = true);
    final c = await _guardar();
    if (!mounted) return;
    setState(() => _cargando = false);
    if (c == null) return;

    context.read<CotizacionBorradorProvider>().limpiar();
    final accion = await CotizacionListaDialog.mostrar(
      context,
      cotizacion: c,
      edicion: _esEdicion,
    );
    if (!mounted) return;
    if (accion == 'ver' || accion == 'imagen') {
      // Abre el documento generado (y lo comparte como imagen si se pidio).
      Navigator.of(context).pushReplacement(FadeRoute<void>(
        builder: (_) => CotizacionDocumentoScreen(
          cotizacionId: c.id,
          compartirAlAbrir: accion == 'imagen' ? 'imagen' : null,
        ),
      ));
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _generarPdf() async {
    final cambios = _cambios(context.read<CotizacionBorradorProvider>());
    if (_esEdicion && cambios.isNotEmpty) {
      final r = await ConfirmarCambiosDialog.mostrar(context, cambios: cambios);
      if (r != 'aplicar' || !mounted) return;
    }
    setState(() => _generando = true);
    final c = await _guardar();
    if (!mounted) return;
    setState(() => _generando = false);
    if (c == null) return;

    context.read<CotizacionBorradorProvider>().limpiar();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _HojaPdf(cotizacion: c),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final borrador = context.watch<CotizacionBorradorProvider>();
    final clientes = context.watch<ClienteProvider>().clientes;
    final cliente = _cliente(clientes);
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final subtotal = borrador.subtotal;
    final igv = subtotal * AppConstants.igv;
    final emision = widget.cotizacion?.fecha ?? DateTime.now();
    final vence = emision.add(Duration(days: _validez));

    final cambios = _cambios(borrador);
    return PopScope(
      canPop: cambios.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && cambios.isNotEmpty) _alIntentarSalir(cambios);
      },
      child: Scaffold(
      appBar: AppBarTaller(
        mostrarCarrito: false,
        subtitulo: 'Presupuesto',
        title: Text(_esEdicion ? 'Editar cotizacion' : 'Nueva cotizacion'),
      ),
      body: Column(
        children: [
          _BannerBorrador(
            editando: _esEdicion,
            numero: _esEdicion ? CotizacionPdf.numero(widget.cotizacion!) : null,
            productos: borrador.lineas.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================================== cliente
                  const _Etiqueta('CLIENTE'),
                  const SizedBox(height: 8),
                  _TarjetaCliente(
                    cliente: cliente,
                    error: _errorCliente,
                    onTap: cliente == null
                        ? null
                        : () => PerfilClienteSheet.mostrar(context,
                            cliente: cliente),
                  ),
                  const SizedBox(height: 12),
                  BuscadorClienteDocumento(
                    onUsar: (id) => setState(() {
                      _clienteId = id;
                      _errorCliente = null;
                    }),
                    onCrear: _crearCliente,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _elegirCliente,
                          icon: const Icon(Icons.search, size: 19),
                          label: const Text('POR NOMBRE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppTheme.primary, width: 1.8),
                            foregroundColor: oscuro
                                ? AppTheme.primary
                                : const Color(0xFFD95800),
                          ),
                          onPressed: _crearCliente,
                          icon: const Icon(Icons.person_add_alt, size: 19),
                          label: const Text('AGREGAR / CREAR CLIENTE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ======================================== listado
                  Row(
                    children: [
                      const Expanded(child: _Etiqueta('LISTADO DE COTIZACION')),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            setState(() => _listadoAbierto = !_listadoAbierto),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Text('${borrador.unidades} und',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              AnimatedRotation(
                                turns: _listadoAbierto ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _irAlCatalogo,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('AGREGAR PRODUCTO DESDE LA TIENDA'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_listadoAbierto
                        ? const SizedBox(width: double.infinity)
                        : borrador.vacio
                            ? const _ListadoVacio()
                            : Column(
                                children: [
                                  for (final l in borrador.lineas)
                                    _FilaLinea(
                                      key: ValueKey(l.producto.id),
                                      linea: l,
                                      onCantidad: (n) => borrador.fijarCantidad(
                                          l.producto.id, n),
                                      onQuitar: () =>
                                          borrador.quitar(l.producto.id),
                                    ),
                                ],
                              ),
                  ),
                  if (borrador.conFaltante.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppTheme.danger.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppTheme.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${borrador.conFaltante.length} producto(s) '
                              'superan el stock disponible. Al cotizar veras el detalle.',
                              style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ======================================== validez
                  const _Etiqueta('VALIDEZ DE LA COTIZACION'),
                  const SizedBox(height: 8),
                  Row(
                    children: AppConstants.diasValidez
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$d dias'),
                              selected: _validez == d,
                              onSelected: (_) => setState(() => _validez = d),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emision: ${Formatters.fechaCorta(emision)}   |   '
                    'Vence: ${Formatters.fechaCorta(vence)}',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // ======================================== totales
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: oscuro
                              ? AppTheme.bordeOscuro
                              : AppTheme.bordeClaro),
                    ),
                    child: Column(
                      children: [
                        _FilaTotal('Subtotal', Formatters.soles(subtotal)),
                        const SizedBox(height: 6),
                        _FilaTotal('IGV (18%)', Formatters.soles(igv)),
                        const Divider(height: 18),
                        _FilaTotal('Total', Formatters.soles(subtotal + igv),
                            fuerte: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedButton(
                    texto: !_esEdicion
                        ? 'Cotizar'
                        : (cambios.isEmpty ? 'Cancelar' : 'Guardar cambios'),
                    icono: _esEdicion && cambios.isEmpty
                        ? Icons.close
                        : Icons.request_quote_outlined,
                    cargando: _cargando,
                    onPressed: (_cargando || _generando)
                        ? null
                        : () => _alPulsarPrincipal(cambios),
                    ancho: double.infinity,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          (_cargando || _generando) ? null : _generarPdf,
                      icon: _generando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('GENERAR PDF'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
    );
  }
}

// ===================================================================
// Piezas de la pantalla
// ===================================================================

class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11.5,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade600,
      ),
    );
  }
}

/// Encabezado fijo que recuerda que se trabaja en un borrador.
class _BannerBorrador extends StatefulWidget {
  final bool editando;
  final String? numero;
  final int productos;
  const _BannerBorrador(
      {required this.editando, required this.numero, required this.productos});

  @override
  State<_BannerBorrador> createState() => _BannerBorradorState();
}

class _BannerBorradorState extends State<_BannerBorrador>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.amarilloSenal.withOpacity(0.16),
        border: const Border(
          bottom: BorderSide(color: AppTheme.amarilloSenal, width: 2),
        ),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
            child: const Icon(Icons.edit_document,
                color: Color(0xFFB8860B), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BORRADOR DE COTIZACION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9A6B00),
                  ),
                ),
                Text(
                  widget.editando
                      ? 'Editando ${widget.numero ?? ''}  |  ${widget.productos} productos'
                      : 'Aun no guardada  |  ${widget.productos} productos',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  final Cliente? cliente;
  final String? error;
  final VoidCallback? onTap;
  const _TarjetaCliente(
      {required this.cliente, required this.error, this.onTap});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final hay = cliente != null;
    final color = hay
        ? (cliente!.tipoDocumento == 'RUC'
            ? const Color(0xFF0277BD)
            : AppTheme.primary)
        : Colors.grey.shade600;
    final borde = error != null
        ? AppTheme.danger
        : (hay
            ? color.withOpacity(0.7)
            : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Container(
            key: ValueKey(cliente?.id ?? 'ninguno'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borde, width: hay ? 1.8 : 1.3),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: color.withOpacity(0.14),
                    shape: BeveledRectangleBorder(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(14)),
                      side: BorderSide(color: color.withOpacity(0.5)),
                    ),
                  ),
                  child: hay
                      ? Text(cliente!.nombre[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: color))
                      : Icon(Icons.person_search_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hay ? cliente!.nombre : 'Selecciona un cliente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hay
                            ? '${cliente!.tipoDocumento} ${cliente!.documento}'
                                '${cliente!.telefono.isEmpty ? '' : '  |  Tel. ${cliente!.telefono}'}'
                            : 'Busca uno existente o crea uno nuevo',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hay)
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Text('TOCA PARA VER EL PERFIL',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error!,
                style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _ListadoVacio extends StatelessWidget {
  const _ListadoVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.playlist_add, size: 38, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('Tu listado esta vacio',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            'Pulsa "Agregar producto" para elegirlos desde la tienda. '
            'No se envian al carrito.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Un producto del listado: miniatura, nombre, cantidad editable. Entra con
/// la misma animacion de despliegue que el carrito y, si supera el stock,
/// el nombre y la cantidad se marcan en rojo.
class _FilaLinea extends StatelessWidget {
  final LineaCotizacion linea;
  final ValueChanged<int> onCantidad;
  final VoidCallback onQuitar;

  const _FilaLinea({
    super.key,
    required this.linea,
    required this.onCantidad,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final p = linea.producto;
    final rojo = linea.sinStock;
    final colorTexto = rojo ? AppTheme.danger : null;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 24),
          child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: rojo
              ? AppTheme.danger.withOpacity(oscuro ? 0.14 : 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rojo
                ? AppTheme.danger.withOpacity(0.7)
                : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
            width: rojo ? 1.6 : 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (rojo ? AppTheme.danger : AppTheme.primary)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: ProductoImagen(producto: p, size: 42)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            height: 1.2,
                            color: colorTexto),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Formatters.soles(linea.precio)} c/u   |   '
                        '${Formatters.soles(linea.subtotal)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.close, size: 19),
                  color: AppTheme.danger,
                  onPressed: onQuitar,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Paso(
                    icono: Icons.remove,
                    onTap: () => onCantidad(linea.cantidad - 1)),
                EditableCantidad(
                  valor: linea.cantidad,
                  maximo: 9999,
                  onCambio: onCantidad,
                  child: SizedBox(
                  width: 54,
                  child: Text(
                    '${linea.cantidad}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colorTexto),
                  ),
                )),
                _Paso(
                    icono: Icons.add,
                    onTap: () => onCantidad(linea.cantidad + 1)),
                const Spacer(),
                Text(
                  'Stock: ${p.stock}',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: rojo ? AppTheme.danger : Colors.grey.shade600),
                ),
              ],
            ),
            if (rojo)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Faltan ${linea.faltante} '
                  '${linea.faltante == 1 ? 'unidad' : 'unidades'} para cubrir esta cotizacion.',
                  style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _Paso({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withOpacity(0.14),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icono, size: 18, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String a;
  final String b;
  final bool fuerte;
  const _FilaTotal(this.a, this.b, {this.fuerte = false});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontWeight: fuerte ? FontWeight.bold : FontWeight.normal,
      fontSize: fuerte ? 17 : 14,
      color: fuerte ? Theme.of(context).colorScheme.primary : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(a, style: estilo), Text(b, style: estilo)],
    );
  }
}

/// Advertencia con el detalle exacto del inventario.
class _DialogoFaltantes extends StatelessWidget {
  final List<LineaCotizacion> lineas;
  const _DialogoFaltantes({required this.lineas});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded,
          color: AppTheme.danger, size: 40),
      title: const Text('Inventario insuficiente'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Estos productos superan el stock disponible. Puedes '
                  'cotizarlos igual, pero no podras entregarlos completos hoy.',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              for (final l in lineas)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.producto.nombre,
                          style: const TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Stock disponible: ${l.producto.stock} '
                        '${l.producto.stock == 1 ? 'unidad' : 'unidades'}  |  '
                        'Faltantes para tu cotizacion: ${l.faltante} '
                        '${l.faltante == 1 ? 'unidad' : 'unidades'}',
                        style: const TextStyle(fontSize: 12.5, height: 1.35),
                      ),
                      Text('Solicitado: ${l.cantidad}',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('revisar'),
          child: const Text('REVISAR LISTADO'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('ajustar'),
          child: const Text('AJUSTAR AL STOCK'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('continuar'),
          child: const Text('COTIZAR IGUAL'),
        ),
      ],
    );
  }
}

/// Resultado de "Generar PDF": confirma y habilita Compartir.
class _HojaPdf extends StatefulWidget {
  final Cotizacion cotizacion;
  const _HojaPdf({required this.cotizacion});

  @override
  State<_HojaPdf> createState() => _HojaPdfState();
}

class _HojaPdfState extends State<_HojaPdf> {
  bool _compartiendo = false;

  Future<void> _compartir() async {
    setState(() => _compartiendo = true);
    try {
      await CotizacionPdf.compartir(widget.cotizacion);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo compartir el PDF'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
    if (mounted) setState(() => _compartiendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: const Border(
            top: BorderSide(color: AppTheme.primary, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 46, color: AppTheme.danger),
            const SizedBox(height: 10),
            const Text('PDF generado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'COTIZACION ${CotizacionPdf.numero(c)}\n'
              'Emision: ${Formatters.fechaCorta(c.fecha)}   |   '
              'Vence: ${Formatters.fechaCorta(c.fechaVencimiento)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text('Total ${Formatters.soles(c.total)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _compartiendo ? null : _compartir,
                icon: _compartiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_outlined),
                label: const Text('COMPARTIR'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('LISTO'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Busqueda de clientes por nombre o DNI / RUC.
class _HojaClientes extends StatefulWidget {
  final String? seleccionado;
  const _HojaClientes({required this.seleccionado});

  @override
  State<_HojaClientes> createState() => _HojaClientesState();
}

class _HojaClientesState extends State<_HojaClientes> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = _c.text.trim().toLowerCase();
    final lista = context.watch<ClienteProvider>().clientes.where((c) {
      return texto.isEmpty ||
          c.nombre.toLowerCase().contains(texto) ||
          c.documento.contains(texto);
    }).toList();
    final alto = MediaQuery.of(context).size.height;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: alto * 0.7),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: const Border(
              top: BorderSide(color: AppTheme.primary, width: 2.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _c,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, DNI o RUC...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: lista.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin resultados. Usa "Agregar / crear cliente".'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: lista.length,
                      itemBuilder: (context, i) {
                        final c = lista[i];
                        final sel = c.id == widget.seleccionado;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primary.withOpacity(0.15),
                            child: Text(c.nombre[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900)),
                          ),
                          title: Text(c.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text('${c.tipoDocumento} ${c.documento}'),
                          trailing: sel
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.success)
                              : null,
                          onTap: () => Navigator.of(context).pop(c.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
