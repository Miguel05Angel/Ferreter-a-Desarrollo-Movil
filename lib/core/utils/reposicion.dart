import 'dart:math' as math;

import '../../data/models/producto.dart';
import '../../data/models/proveedor.dart';
import '../constants/app_constants.dart';

/// Reglas para pedir mas stock: que proveedor corresponde a cada producto,
/// cuanto pedir y el texto del pedido.
class Reposicion {
  Reposicion._();

  /// Palabras que identifican la linea de cada categoria en los proveedores.
  static const Map<String, List<String>> _lineas = {
    'cat-1': ['herramienta'],
    'cat-2': ['pintura'],
    'cat-3': ['tuberia', 'pvc', 'manguera', 'sanitari'],
    'cat-4': ['electric', 'cable', 'ilumin', 'interruptor'],
    'cat-5': ['cemento', 'fierro', 'agregado'],
    'cat-6': ['clavo', 'tornillo', 'tarugo', 'fijacion'],
  };

  static String _norm(String t) => t
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  /// Proveedores que venden este producto, el mas probable primero.
  /// Compara la marca, la linea de la categoria y el nombre del producto.
  static List<Proveedor> proveedoresPara(Producto p, List<Proveedor> todos) {
    final marca = _norm(p.marca);
    final palabrasProducto =
        _norm(p.nombre).split(' ').where((w) => w.length > 3).toList();
    final palabrasLinea = _lineas[p.categoriaId] ?? const <String>[];

    final puntuados = <MapEntry<Proveedor, int>>[];
    for (final pr in todos) {
      var puntos = 0;
      if (marca.isNotEmpty && _norm(pr.nombre).contains(marca)) puntos += 3;
      for (final linea in pr.productos) {
        final l = _norm(linea);
        if (palabrasLinea.any((w) => l.contains(w))) puntos += 2;
        if (palabrasProducto.any((w) => l.contains(w))) puntos += 1;
      }
      if (puntos > 0) puntuados.add(MapEntry(pr, puntos));
    }
    puntuados.sort((a, b) => b.value.compareTo(a.value));
    return puntuados.map((e) => e.key).toList();
  }

  /// Cantidad sugerida para volver a un stock saludable. Los productos
  /// baratos se piden en mayor cantidad que los caros.
  static int cantidadSugerida(Producto p) {
    final objetivo = p.precioVenta < 5
        ? 200
        : p.precioVenta < 30
            ? 60
            : p.precioVenta < 100
                ? 30
                : 15;
    return math.max(10, objetivo - p.stock);
  }

  static String mensajePedido({
    required String numero,
    required String solicitante,
    required Producto producto,
    required int cantidad,
    required String observaciones,
  }) {
    final b = StringBuffer()
      ..writeln('Hola, soy $solicitante de ${AppConstants.nombreApp} '
          '(RUC ${AppConstants.rucFerreteria}).')
      ..writeln('Solicito la reposicion del siguiente producto:')
      ..writeln('- Pedido No.: $numero')
      ..writeln('- Codigo: ${producto.codigo}')
      ..writeln('- Producto: ${producto.nombre} (${producto.marca})')
      ..writeln('- Cantidad: $cantidad ${producto.unidad}')
      ..writeln('- Stock actual: ${producto.stock}');
    if (observaciones.trim().isNotEmpty) {
      b.writeln('- Observaciones: ${observaciones.trim()}');
    }
    b.write('Agradezco confirmar disponibilidad, precio y plazo de entrega.');
    return b.toString();
  }

  static String mensajeAviso({
    required Producto producto,
    required String vendedor,
  }) {
    final estado = producto.agotado
        ? 'esta AGOTADO'
        : 'tiene solo ${producto.stock} unidad(es)';
    return 'Aviso de stock: ${producto.nombre} (${producto.codigo}) $estado. '
        'Reportado por $vendedor. Se recomienda solicitar reposicion al proveedor.';
  }
}
