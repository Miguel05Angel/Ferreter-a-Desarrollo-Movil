import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/firestore_mappers.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/venta.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

/// Panel administrativo que corre en el navegador.
///
/// Lee y escribe directamente en Firestore, por lo que lo que se cambia aqui
/// se ve en los telefonos y al contrario.
///
/// Trabaja sobre la API que expone FirestoreService (`productos` y `ventas`
/// como CollectionReference). Solo muestra las colecciones que las reglas
/// permiten a un Administrador: clientes, proveedores y cotizaciones no
/// tienen regla, asi que se niegan por defecto y no se listan aqui.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _seccion = 0;

  // Los streams se crean UNA vez. Si se crearan dentro de build(), cada
  // redibujado abriria una suscripcion nueva a Firestore, que se paga en
  // lecturas facturadas.
  late final Stream<List<Producto>> _productos;
  late final Stream<List<Venta>> _ventas;

  @override
  void initState() {
    super.initState();
    final svc = FirestoreService.instance;
    _productos = _escuchar(svc.productos, Mapeadores.productoDesde);
    _ventas = _escuchar(svc.ventas, Mapeadores.ventaDesde);
  }

  /// Convierte una coleccion en un stream de modelos, ordenado por `creadoEn`.
  ///
  /// Un resultado vacio que viene de la cache local no significa que la base
  /// este vacia: se ignora para no pintar la tabla en blanco al arrancar.
  Stream<List<T>> _escuchar<T>(
    CollectionReference<Mapa> coleccion,
    T Function(String id, Mapa datos) desde,
  ) {
    return coleccion
        .snapshots()
        .where((snap) => !(snap.metadata.isFromCache && snap.docs.isEmpty))
        .map((snap) {
      final docs = snap.docs.toList()
        ..sort((a, b) => _creado(a.data()).compareTo(_creado(b.data())));
      return docs.map((d) => desde(d.id, d.data())).toList();
    });
  }

  static int _creado(Mapa data) {
    final v = data['creadoEn'];
    return v is Timestamp ? v.millisecondsSinceEpoch : 0;
  }

  @override
  Widget build(BuildContext context) {
    final extendido = MediaQuery.sizeOf(context).width >= 1000;
    final usuario = context.watch<AuthProvider>().usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('El Constructor - Panel administrativo'),
        actions: [
          if (usuario != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Center(child: Text(usuario.nombre)),
            ),
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: context.read<AuthProvider>().cerrarSesion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: extendido,
            selectedIndex: _seccion,
            onDestinationSelected: (i) => setState(() => _seccion = i),
            labelType: extendido ? null : NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Resumen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Productos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Ventas'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: switch (_seccion) {
              0 => _Resumen(productos: _productos, ventas: _ventas),
              1 => _ProductosSeccion(productos: _productos),
              _ => _VentasSeccion(ventas: _ventas),
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RESUMEN
// ---------------------------------------------------------------------------

class _Resumen extends StatelessWidget {
  const _Resumen({required this.productos, required this.ventas});

  final Stream<List<Producto>> productos;
  final Stream<List<Venta>> ventas;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Producto>>(
      stream: productos,
      builder: (context, snap) {
        if (snap.hasError) return _Error(error: snap.error!);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snap.data!;
        final valor = lista.fold<double>(
          0,
          (suma, p) => suma + p.precioVenta * p.stock,
        );
        final bajos = lista.where((p) => p.stockBajo).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _Tarjeta(
                  titulo: 'Productos',
                  valor: '${lista.length}',
                  icono: Icons.inventory_2,
                ),
                _Tarjeta(
                  titulo: 'Stock bajo o agotado',
                  valor: '${bajos.length}',
                  icono: Icons.warning_amber,
                  alerta: bajos.isNotEmpty,
                ),
                _Tarjeta(
                  titulo: 'Valor del inventario',
                  valor: 'S/ ${valor.toStringAsFixed(2)}',
                  icono: Icons.payments,
                ),
                _TarjetaVentas(ventas: ventas),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Necesitan reposicion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (bajos.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Todo el stock esta por encima del minimo'),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final p in bajos)
                      ListTile(
                        leading: Icon(
                          p.agotado ? Icons.error : Icons.warning_amber,
                          color: p.agotado ? Colors.red : Colors.orange,
                        ),
                        title: Text(p.nombre),
                        subtitle: Text('Codigo ${p.codigo} - ${p.marca}'),
                        trailing: Text(
                          p.agotado
                              ? 'AGOTADO'
                              : '${p.stock} / minimo ${p.stockMinimo}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaVentas extends StatelessWidget {
  const _TarjetaVentas({required this.ventas});

  final Stream<List<Venta>> ventas;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venta>>(
      stream: ventas,
      builder: (context, snap) {
        final total = snap.data?.fold<double>(0, (s, v) => s + v.total);
        return _Tarjeta(
          titulo: 'Vendido (${snap.data?.length ?? 0} ventas)',
          valor: total == null ? '...' : 'S/ ${total.toStringAsFixed(2)}',
          icono: Icons.receipt_long,
        );
      },
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.alerta = false,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: alerta ? Colors.orange : null),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(valor, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRODUCTOS (crear, editar, eliminar)
// ---------------------------------------------------------------------------

class _ProductosSeccion extends StatelessWidget {
  const _ProductosSeccion({required this.productos});

  final Stream<List<Producto>> productos;

  CollectionReference<Mapa> get _col => FirestoreService.instance.productos;

  /// Ejecuta una escritura y avisa si Firestore la rechaza.
  ///
  /// Con las reglas nuevas un permission-denied es perfectamente posible
  /// (por ejemplo si caduca la sesion), y el panel tiene que decirlo en vez
  /// de quedarse callado.
  Future<void> _escribir(
    BuildContext context,
    String que,
    Future<void> Function() accion,
  ) async {
    final avisos = ScaffoldMessenger.of(context);
    try {
      await accion();
    } on FirebaseException catch (e) {
      avisos.showSnackBar(
        SnackBar(
          content: Text(e.code == 'permission-denied'
              ? 'Sin permiso para $que. Revisa que tu sesion siga activa '
                  'y que tu rol sea Administrador.'
              : 'No se pudo $que: (${e.code}) ${e.message}'),
        ),
      );
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text('No se pudo $que: $e')));
    }
  }

  Future<void> _nuevo(BuildContext context) async {
    final creado = await showDialog<Producto>(
      context: context,
      builder: (_) => const _ProductoFormDialog(),
    );
    if (creado == null || !context.mounted) return;
    await _escribir(context, 'crear el producto', () {
      return _col.doc(creado.id).set({
        ...Mapeadores.productoAMapa(creado),
        'creadoEn': Timestamp.now(),
      });
    });
  }

  Future<void> _editar(BuildContext context, Producto p) async {
    final editado = await showDialog<Producto>(
      context: context,
      builder: (_) => _ProductoFormDialog(original: p),
    );
    if (editado == null || !context.mounted) return;
    await _escribir(context, 'guardar el producto', () {
      return _col.doc(editado.id).set(
            Mapeadores.productoAMapa(editado),
            SetOptions(merge: true),
          );
    });
  }

  Future<void> _eliminar(BuildContext context, Producto p) async {
    // Borrar un documento de Firestore no se puede deshacer, asi que se
    // confirma siempre.
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          'Se va a eliminar "${p.nombre}" de la base de datos.\n\n'
          'Esta accion no se puede deshacer y el producto desaparece '
          'tambien de la app de los telefonos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await _escribir(
      context,
      'eliminar el producto',
      () => _col.doc(p.id).delete(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevo(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: StreamBuilder<List<Producto>>(
        stream: productos,
        builder: (context, snap) {
          if (snap.hasError) return _Error(error: snap.error!);
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const Center(
              child: Text('No hay productos en la base de datos'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Productos (${lista.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Codigo')),
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Marca')),
                      DataColumn(label: Text('Precio'), numeric: true),
                      DataColumn(label: Text('Stock'), numeric: true),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: [
                      for (final p in lista)
                        DataRow(
                          cells: [
                            DataCell(Text(p.codigo)),
                            DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(p.marca)),
                            DataCell(
                              Text('S/ ${p.precioVenta.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text(
                                '${p.stock}',
                                style: TextStyle(
                                  color: p.agotado
                                      ? Colors.red
                                      : (p.critico ? Colors.orange : null),
                                  fontWeight: p.stockBajo
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editar(context, p),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _eliminar(context, p),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

/// Formulario de producto. Devuelve el [Producto] listo para guardar, o `null`
/// si se cancela.
///
/// Es un dialogo que devuelve valor justamente para no tener que guardar un
/// "id en edicion" mutable en el State, que es de donde salen los botones con
/// el texto equivocado.
class _ProductoFormDialog extends StatefulWidget {
  const _ProductoFormDialog({this.original});

  /// `null` cuando se esta creando un producto nuevo.
  final Producto? original;

  @override
  State<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<_ProductoFormDialog> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _marca;
  late final TextEditingController _unidad;
  late final TextEditingController _precioVenta;
  late final TextEditingController _precioCompra;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;

  bool get _esNuevo => widget.original == null;

  @override
  void initState() {
    super.initState();
    final p = widget.original;
    _codigo = TextEditingController(text: p?.codigo ?? '');
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _marca = TextEditingController(text: p?.marca ?? '');
    _unidad = TextEditingController(text: p?.unidad ?? 'Unidad');
    _precioVenta =
        TextEditingController(text: p == null ? '' : '${p.precioVenta}');
    _precioCompra =
        TextEditingController(text: p == null ? '' : '${p.precioCompra}');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _stockMinimo =
        TextEditingController(text: p == null ? '5' : '${p.stockMinimo}');
  }

  @override
  void dispose() {
    for (final c in [
      _codigo,
      _nombre,
      _descripcion,
      _marca,
      _unidad,
      _precioVenta,
      _precioCompra,
      _stock,
      _stockMinimo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final p = widget.original;
    final resultado = Producto(
      // Un producto nuevo necesita un id propio; se reusa el del original
      // cuando se esta editando.
      id: p?.id ?? 'web-${DateTime.now().millisecondsSinceEpoch}',
      codigo: _codigo.text.trim(),
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      // Se conservan los campos que este formulario no edita.
      categoriaId: p?.categoriaId ?? '',
      marca: _marca.text.trim(),
      unidad: _unidad.text.trim().isEmpty ? 'Unidad' : _unidad.text.trim(),
      precioVenta: double.parse(_precioVenta.text.replaceAll(',', '.')),
      precioCompra:
          double.tryParse(_precioCompra.text.replaceAll(',', '.')) ?? 0,
      stock: int.parse(_stock.text),
      stockMinimo: int.tryParse(_stockMinimo.text) ?? 5,
      tipoVisual: p?.tipoVisual ?? 'generico',
      colorHex: p?.colorHex ?? 0xFF607D8B,
      coloresHex: p?.coloresHex ?? const [],
      fuente: p?.fuente ?? '',
      urlFuente: p?.urlFuente ?? '',
      fechaPrecio: p?.fechaPrecio,
      calidad: p?.calidad ?? 0,
    );
    Navigator.of(context).pop(resultado);
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

  String? _numero(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obligatorio';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Debe ser un numero';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  String? _entero(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obligatorio';
    final n = int.tryParse(v);
    if (n == null) return 'Debe ser un numero entero';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esNuevo ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigo,
                        decoration:
                            const InputDecoration(labelText: 'Codigo'),
                        validator: _obligatorio,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _marca,
                        decoration: const InputDecoration(labelText: 'Marca'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: _obligatorio,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcion,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioVenta,
                        decoration: const InputDecoration(
                          labelText: 'Precio de venta',
                          prefixText: 'S/ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _numero,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _precioCompra,
                        decoration: const InputDecoration(
                          labelText: 'Precio de compra',
                          prefixText: 'S/ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                        validator: _entero,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimo,
                        decoration:
                            const InputDecoration(labelText: 'Stock minimo'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _unidad,
                        decoration:
                            const InputDecoration(labelText: 'Unidad'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(_esNuevo ? 'Agregar' : 'Actualizar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VENTAS (solo lectura)
// ---------------------------------------------------------------------------

class _VentasSeccion extends StatelessWidget {
  const _VentasSeccion({required this.ventas});

  final Stream<List<Venta>> ventas;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venta>>(
      stream: ventas,
      builder: (context, snap) {
        if (snap.hasError) return _Error(error: snap.error!);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snap.data!.reversed.toList();
        if (lista.isEmpty) {
          return const Center(child: Text('Todavia no hay ventas'));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Ventas (${lista.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (final v in lista)
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        '${v.comprobante} ${v.numero} - ${v.clienteNombre}',
                      ),
                      subtitle: Text(
                        '${_fecha(v.fecha)} - ${v.metodoPago} - '
                        '${v.items.length} producto(s)',
                      ),
                      trailing: Text(
                        'S/ ${v.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';
}

// ---------------------------------------------------------------------------

class _Error extends StatelessWidget {
  const _Error({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final denegado =
        error is FirebaseException && (error as FirebaseException).code ==
            'permission-denied';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              denegado
                  ? 'Firestore nego el acceso'
                  : 'Firestore devolvio un error',
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              denegado
                  ? 'Las reglas de ferreteria-db solo dejan leer el catalogo '
                      'a cuentas con rol Administrador o Vendedor.'
                  : 'Revisa la consola del navegador para mas detalle.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
