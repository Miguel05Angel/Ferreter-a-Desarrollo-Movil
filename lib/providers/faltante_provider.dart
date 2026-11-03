import 'package:flutter/foundation.dart';

/// Un articulo que un cliente pidio y la ferreteria no tiene registrado.
class Faltante {
  final String id;
  final String producto;
  final String marca;
  final String categoria;
  final DateTime fecha;
  final String reportadoPor;

  const Faltante({
    required this.id,
    required this.producto,
    required this.marca,
    required this.categoria,
    required this.fecha,
    required this.reportadoPor,
  });
}

/// Reportes rapidos de productos que no se manejan en stock. Sirve para
/// decidir que ampliar en el catalogo.
class FaltanteProvider extends ChangeNotifier {
  final List<Faltante> _faltantes = [];

  static const categorias = [
    'Construcción',
    'Acabados',
    'Herramientas',
    'Gasfitería',
    'Electricidad',
  ];

  List<Faltante> get faltantes {
    final copia = [..._faltantes];
    copia.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(copia);
  }

  int get total => _faltantes.length;

  Faltante registrar({
    required String producto,
    required String marca,
    required String categoria,
    required String reportadoPor,
  }) {
    final f = Faltante(
      id: 'fl-${DateTime.now().microsecondsSinceEpoch}',
      producto: producto.trim(),
      marca: marca.trim(),
      categoria: categoria,
      fecha: DateTime.now(),
      reportadoPor: reportadoPor,
    );
    _faltantes.add(f);
    notifyListeners();
    return f;
  }

  void eliminar(String id) {
    _faltantes.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
