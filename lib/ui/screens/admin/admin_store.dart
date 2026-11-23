import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../data/firestore_mappers.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/venta.dart';
import '../../../services/firestore_service.dart';

DateTime? _aFecha(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

String _txt(dynamic v) => v == null ? '' : v.toString();

// ===========================================================================
// MODELOS DEL PANEL
// ===========================================================================

/// Un producto más su estado dentro del panel (activo / papelera).
class ItemProducto {
  ItemProducto({
    required this.p,
    required this.activo,
    this.eliminadoEn,
    this.creadoEn,
  }) : busqueda = '${p.nombre} ${p.codigo} ${p.marca}'.toLowerCase();

  final Producto p;

  /// `false` = desactivado: la app lo oculta pero sigue en la base de datos.
  final bool activo;

  /// Si no es null, el producto está en la papelera desde esta fecha.
  final DateTime? eliminadoEn;
  final DateTime? creadoEn;
  final String busqueda;

  String get id => p.id;
  bool get enPapelera => eliminadoEn != null;

  /// Días que le quedan en la papelera antes de la purga definitiva.
  int get diasRestantes {
    if (eliminadoEn == null) return AdminStore.diasPapelera;
    final fin = eliminadoEn!.add(const Duration(days: AdminStore.diasPapelera));
    final falta = fin.difference(DateTime.now());
    return falta.isNegative ? 0 : (falta.inHours / 24).ceil();
  }
}

class Trabajador {
  const Trabajador({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.dni,
    required this.email,
    required this.telefono,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String rol;
  final String dni;
  final String email;
  final String telefono;
  final bool activo;

  bool get esAdmin => rol.toLowerCase().contains('admin');

  factory Trabajador.desde(String id, Map<String, dynamic> m) => Trabajador(
        id: id,
        nombre: _txt(m['nombre']).isEmpty ? 'Sin nombre' : _txt(m['nombre']),
        rol: _txt(m['rol']).isEmpty ? 'Vendedor' : _txt(m['rol']),
        dni: _txt(m['dni']),
        email: _txt(m['email']),
        telefono: _txt(m['telefono']),
        activo: m['activo'] != false,
      );
}

enum EstadoPedido { pendiente, cotizado, ordenado }

class Pedido {
  const Pedido({
    required this.id,
    required this.numero,
    required this.estado,
    required this.proveedor,
    required this.descripcion,
    required this.codigo,
    required this.cantidad,
    required this.unidad,
    required this.solicitante,
    this.fecha,
    this.respuestaAntes,
    this.total,
  });

  final String id;
  final String numero;
  final EstadoPedido estado;
  final String proveedor;
  final String descripcion;
  final String codigo;
  final int cantidad;
  final String unidad;
  final String solicitante;
  final DateTime? fecha;
  final DateTime? respuestaAntes;
  final double? total;

  factory Pedido.desde(String id, Map<String, dynamic> m) {
    final e = _txt(m['estado']).toLowerCase();
    final estado = (e.contains('sin') || e.contains('pend'))
        ? EstadoPedido.pendiente
        : e.contains('orden')
            ? EstadoPedido.ordenado
            : e.contains('cotiz')
                ? EstadoPedido.cotizado
                : EstadoPedido.pendiente;
    final t = m['total'] ?? m['precioTotal'];
    return Pedido(
      id: id,
      numero: _txt(m['numero']).isEmpty ? id : _txt(m['numero']),
      estado: estado,
      proveedor: _txt(m['proveedorNombre'] ?? m['proveedor']),
      descripcion: _txt(m['descripcion']),
      codigo: _txt(m['codigo']),
      cantidad: (m['cantidad'] is num) ? (m['cantidad'] as num).toInt() : 0,
      unidad: _txt(m['unidad']),
      solicitante: _txt(m['solicitante']),
      fecha: _aFecha(m['fecha']),
      respuestaAntes: _aFecha(m['respuestaAntes']),
      total: t is num ? t.toDouble() : null,
    );
  }
}

// ===========================================================================
// ALMACÉN EN TIEMPO REAL
// ===========================================================================

/// Se suscribe UNA sola vez a cada colección. Las pestañas leen de aquí, así
/// que cambiar de pestaña es instantáneo y no genera lecturas nuevas.
class AdminStore extends ChangeNotifier {
  AdminStore() {
    _iniciar();
  }

  /// Días que un producto permanece en la papelera antes de purgarse.
  static const int diasPapelera = 30;

  /// Colecciones adicionales. Cámbialas aquí si en tu Firestore se llaman
  /// de otra forma.
  static const String colUsuarios = 'usuarios';
  static const String colPedidos = 'pedidos_proveedor';

  final List<StreamSubscription<dynamic>> _subs = [];

  List<ItemProducto> productos = const [];
  bool productosListo = false;
  Object? productosError;

  List<Venta> ventas = const [];
  bool ventasListo = false;
  Object? ventasError;

  List<Trabajador> trabajadores = const [];
  bool trabajadoresListo = false;
  Object? trabajadoresError;

  List<Pedido> pedidos = const [];
  bool pedidosListo = false;
  Object? pedidosError;

  bool _purgado = false;

  CollectionReference<Map<String, dynamic>> get _prod =>
      FirestoreService.instance.productos;

  void _iniciar() {
    final svc = FirestoreService.instance;

    _subs.add(svc.productos.snapshots().listen((snap) {
      // Un resultado vacío que viene de la caché no significa base vacía.
      if (snap.metadata.isFromCache && snap.docs.isEmpty) return;
      final lista = <ItemProducto>[];
      for (final d in snap.docs) {
        try {
          final m = d.data();
          lista.add(ItemProducto(
            p: Mapeadores.productoDesde(d.id, m),
            activo: m['activo'] != false,
            eliminadoEn: _aFecha(m['eliminadoEn']),
            creadoEn: _aFecha(m['creadoEn']),
          ));
        } catch (_) {
          // Un documento mal formado no debe tumbar todo el panel.
        }
      }
      lista.sort((a, b) => (b.creadoEn?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.creadoEn?.millisecondsSinceEpoch ?? 0));
      productos = lista;
      productosListo = true;
      productosError = null;
      notifyListeners();
      _purgarUnaVez();
    }, onError: (Object e) {
      productosError = e;
      productosListo = true;
      notifyListeners();
    }));

    _subs.add(svc.ventas.snapshots().listen((snap) {
      if (snap.metadata.isFromCache && snap.docs.isEmpty) return;
      final lista = <Venta>[];
      for (final d in snap.docs) {
        try {
          lista.add(Mapeadores.ventaDesde(d.id, d.data()));
        } catch (_) {}
      }
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      ventas = lista;
      ventasListo = true;
      ventasError = null;
      notifyListeners();
    }, onError: (Object e) {
      ventasError = e;
      ventasListo = true;
      notifyListeners();
    }));

    final db = FirebaseFirestore.instance;

    _subs.add(db.collection(colUsuarios).snapshots().listen((snap) {
      final lista = [for (final d in snap.docs) Trabajador.desde(d.id, d.data())];
      lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      trabajadores = lista;
      trabajadoresListo = true;
      trabajadoresError = null;
      notifyListeners();
    }, onError: (Object e) {
      trabajadoresError = e;
      trabajadoresListo = true;
      notifyListeners();
    }));

    _subs.add(db.collection(colPedidos).snapshots().listen((snap) {
      final lista = [for (final d in snap.docs) Pedido.desde(d.id, d.data())];
      lista.sort((a, b) => (b.fecha?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.fecha?.millisecondsSinceEpoch ?? 0));
      pedidos = lista;
      pedidosListo = true;
      pedidosError = null;
      notifyListeners();
    }, onError: (Object e) {
      pedidosError = e;
      pedidosListo = true;
      notifyListeners();
    }));
  }

  ItemProducto? buscarProducto(String id) {
    for (final i in productos) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ------------------------------ escrituras --------------------------------

  Future<void> crear(Producto p) => _prod.doc(p.id).set({
        ...Mapeadores.productoAMapa(p),
        'creadoEn': Timestamp.now(),
        'activo': true,
      });

  Future<void> guardar(Producto p) =>
      _prod.doc(p.id).set(Mapeadores.productoAMapa(p), SetOptions(merge: true));

  /// Desactivar = ocultar de la app sin borrar. Activar = volver a mostrar.
  Future<void> definirActivo(String id, bool activo) =>
      _prod.doc(id).update({'activo': activo});

  /// Papelera: no se borra, queda marcado con la fecha y desactivado.
  Future<void> aPapelera(String id) =>
      _prod.doc(id).update({'eliminadoEn': Timestamp.now(), 'activo': false});

  Future<void> restaurar(String id) => _prod
      .doc(id)
      .update({'eliminadoEn': FieldValue.delete(), 'activo': true});

  Future<void> eliminarDefinitivo(String id) => _prod.doc(id).delete();

  /// Borra de verdad lo que lleva 30 días o más en la papelera.
  Future<int> purgarVencidos() async {
    final limite = DateTime.now().subtract(const Duration(days: diasPapelera));
    final vencidos = productos
        .where((i) => i.eliminadoEn != null && i.eliminadoEn!.isBefore(limite))
        .toList();
    if (vencidos.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final i in vencidos) {
      batch.delete(_prod.doc(i.id));
    }
    await batch.commit();
    return vencidos.length;
  }

  Future<void> _purgarUnaVez() async {
    if (_purgado) return;
    _purgado = true;
    try {
      await purgarVencidos();
    } catch (_) {
      // Sin permiso o sin red: la Cloud Function programada lo hará.
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
