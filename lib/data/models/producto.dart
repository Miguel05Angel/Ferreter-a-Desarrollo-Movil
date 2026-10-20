class Producto {
  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String categoriaId;
  final String marca;
  final String unidad;
  final double precioVenta;
  final double precioCompra;
  final int stock;

  /// Tipo de ilustracion 3D que se dibuja en la app.
  final String tipoVisual;

  /// Color principal de la ilustracion (ARGB).
  final int colorHex;

  /// Colores alternativos disponibles (ej: pinturas).
  final List<int> coloresHex;

  const Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.categoriaId,
    required this.marca,
    required this.unidad,
    required this.precioVenta,
    required this.stock,
    this.precioCompra = 0,
    this.tipoVisual = 'generico',
    this.colorHex = 0xFF607D8B,
    this.coloresHex = const [],
  });

  bool get stockBajo => stock <= 5;
  bool get agotado => stock == 0;
  bool get esPintura => tipoVisual == 'pintura' && coloresHex.isNotEmpty;

  Producto copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    String? categoriaId,
    String? marca,
    String? unidad,
    double? precioVenta,
    double? precioCompra,
    int? stock,
    String? tipoVisual,
    int? colorHex,
    List<int>? coloresHex,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      marca: marca ?? this.marca,
      unidad: unidad ?? this.unidad,
      precioVenta: precioVenta ?? this.precioVenta,
      precioCompra: precioCompra ?? this.precioCompra,
      stock: stock ?? this.stock,
      tipoVisual: tipoVisual ?? this.tipoVisual,
      colorHex: colorHex ?? this.colorHex,
      coloresHex: coloresHex ?? this.coloresHex,
    );
  }
}
