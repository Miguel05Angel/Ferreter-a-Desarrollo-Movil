import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/cliente.dart';
import 'models/cotizacion.dart';
import 'models/producto.dart';
import 'models/proveedor.dart';
import 'models/venta.dart';

typedef Mapa = Map<String, dynamic>;

/// Convierte tus modelos a/desde documentos de Firestore.
/// La lectura es tolerante: si falta un campo usa un valor por defecto
/// para que la app nunca se caiga por un documento incompleto.
class Mapeadores {
  Mapeadores._();

  static String _s(dynamic v, [String d = '']) => v is String ? v : d;
  static double _d(dynamic v, [double d = 0]) => v is num ? v.toDouble() : d;
  static int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;
  static bool _b(dynamic v, [bool d = false]) => v is bool ? v : d;
  static DateTime _f(dynamic v) =>
      v is Timestamp ? v.toDate() : DateTime.now();
  static List<int> _listaInt(dynamic v) =>
      v is List ? v.whereType<num>().map((e) => e.toInt()).toList() : <int>[];
  static List<String> _listaStr(dynamic v) =>
      v is List ? v.whereType<String>().toList() : <String>[];

  // ---------------- Producto ----------------
  static Producto productoDesde(String id, Mapa m) => Producto(
        id: id,
        codigo: _s(m['codigo']),
        nombre: _s(m['nombre']),
        descripcion: _s(m['descripcion']),
        categoriaId: _s(m['categoriaId']),
        marca: _s(m['marca']),
        unidad: _s(m['unidad'], 'Unidad'),
        precioVenta: _d(m['precioVenta'] ?? m['precio']),
        precioCompra: _d(m['precioCompra']),
        stock: _i(m['stock']),
        tipoVisual: _s(m['tipoVisual'], 'generico'),
        colorHex: _i(m['colorHex'], 0xFF607D8B),
        coloresHex: _listaInt(m['coloresHex']),
      );

  static Mapa productoAMapa(Producto p) => {
        'codigo': p.codigo,
        'nombre': p.nombre,
        'descripcion': p.descripcion,
        'categoriaId': p.categoriaId,
        'marca': p.marca,
        'unidad': p.unidad,
        'precioVenta': p.precioVenta,
        'precioCompra': p.precioCompra,
        'stock': p.stock,
        'tipoVisual': p.tipoVisual,
        'colorHex': p.colorHex,
        'coloresHex': p.coloresHex,
      };

  // ---------------- Cliente ----------------
  static Cliente clienteDesde(String id, Mapa m) => Cliente(
        id: id,
        nombre: _s(m['nombre']),
        tipoDocumento: _s(m['tipoDocumento'], 'DNI'),
        documento: _s(m['documento']),
        telefono: _s(m['telefono']),
        direccion: _s(m['direccion']),
        email: _s(m['email']),
        credito: _b(m['credito']),
      );

  static Mapa clienteAMapa(Cliente c) => {
        'nombre': c.nombre,
        'tipoDocumento': c.tipoDocumento,
        'documento': c.documento,
        'telefono': c.telefono,
        'direccion': c.direccion,
        'email': c.email,
        'credito': c.credito,
      };

  // ---------------- Proveedor ----------------
  static Proveedor proveedorDesde(String id, Mapa m) => Proveedor(
        id: id,
        nombre: _s(m['nombre']),
        ruc: _s(m['ruc']),
        telefono: _s(m['telefono']),
        direccion: _s(m['direccion']),
        productos: _listaStr(m['productos']),
      );

  static Mapa proveedorAMapa(Proveedor p) => {
        'nombre': p.nombre,
        'ruc': p.ruc,
        'telefono': p.telefono,
        'direccion': p.direccion,
        'productos': p.productos,
      };

  // ---------------- Items (ventas y cotizaciones) ----------------
  static Mapa _itemAMapa(ItemVenta i) => {
        'productoId': i.productoId,
        'nombre': i.nombre,
        'cantidad': i.cantidad,
        'precioUnitario': i.precioUnitario,
      };

  static ItemVenta _itemDesde(dynamic v) {
    final m = v is Map ? Mapa.from(v) : <String, dynamic>{};
    return ItemVenta(
      productoId: _s(m['productoId']),
      nombre: _s(m['nombre']),
      cantidad: _i(m['cantidad']),
      precioUnitario: _d(m['precioUnitario']),
    );
  }

  static List<ItemVenta> _items(dynamic v) =>
      v is List ? v.map(_itemDesde).toList() : <ItemVenta>[];

  // ---------------- Venta ----------------
  static Venta ventaDesde(String id, Mapa m) => Venta(
        id: id,
        numero: _s(m['numero']),
        clienteNombre: _s(m['clienteNombre']),
        items: _items(m['items']),
        subtotal: _d(m['subtotal']),
        igv: _d(m['igv']),
        total: _d(m['total']),
        metodoPago: _s(m['metodoPago']),
        comprobante: _s(m['comprobante'], 'Boleta'),
        fecha: _f(m['fecha']),
      );

  static Mapa ventaAMapa(Venta v) => {
        'numero': v.numero,
        'clienteNombre': v.clienteNombre,
        'items': v.items.map(_itemAMapa).toList(),
        'subtotal': v.subtotal,
        'igv': v.igv,
        'total': v.total,
        'metodoPago': v.metodoPago,
        'comprobante': v.comprobante,
        'fecha': Timestamp.fromDate(v.fecha),
      };

  // ---------------- Cotizacion ----------------
  static Cotizacion cotizacionDesde(String id, Mapa m) => Cotizacion(
        id: id,
        clienteNombre: _s(m['clienteNombre']),
        items: _items(m['items']),
        subtotal: _d(m['subtotal']),
        igv: _d(m['igv']),
        total: _d(m['total']),
        validezDias: _i(m['validezDias'], 7),
        estado: _s(m['estado'], 'Pendiente'),
        fecha: _f(m['fecha']),
      );

  static Mapa cotizacionAMapa(Cotizacion c) => {
        'clienteNombre': c.clienteNombre,
        'items': c.items.map(_itemAMapa).toList(),
        'subtotal': c.subtotal,
        'igv': c.igv,
        'total': c.total,
        'validezDias': c.validezDias,
        'estado': c.estado,
        'fecha': Timestamp.fromDate(c.fecha),
      };
}
