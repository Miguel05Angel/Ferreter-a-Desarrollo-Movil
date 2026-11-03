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

  /// Cantidad minima configurada: al llegar a ella el producto pasa a
  /// STOCK CRITICO y se envia una alerta de reposicion.
  final int stockMinimo;

  /// Origen del precio (tienda o catalogo donde se verifico) y su fecha.
  /// Un precio sin fuente NO se considera real y el asistente no lo recomienda.
  final String fuente;
  final String urlFuente;
  final DateTime? fechaPrecio;

  /// Calificacion de calidad 1-5 tomada de la fuente (0 = sin dato).
  final double calidad;

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
    this.stockMinimo = 5,
    this.fuente = '',
    this.urlFuente = '',
    this.fechaPrecio,
    this.calidad = 0,
  });

  /// Stock critico o agotado (necesita reposicion).
  bool get stockBajo => stock <= stockMinimo;

  /// Quedan pocas unidades pero todavia hay: alerta previa a agotarse.
  bool get critico => stock > 0 && stock <= stockMinimo;
  bool get agotado => stock == 0;

  /// Precio con fuente y fecha de verificacion.
  bool get precioVerificado => fuente.trim().isNotEmpty && fechaPrecio != null;

  /// Tipo de herramienta o producto, para el filtro del catalogo.
  String get tipoLabel {
    const nombres = {
      'taladro': 'Taladros',
      'martillo': 'Martillos',
      'llaves': 'Llaves',
      'pistola': 'Pistolas',
      'cinta': 'Cintas',
      'pintura': 'Pinturas',
      'rodillo': 'Rodillos',
      'brocha': 'Brochas',
      'tubo': 'Tuberias',
      'codo': 'Accesorios PVC',
      'pega': 'Pegamentos',
      'manguera': 'Mangueras',
      'cable': 'Cables',
      'interruptor': 'Interruptores y tomas',
      'foco': 'Iluminacion',
      'cemento': 'Cemento',
      'fierro': 'Fierro y alambre',
      'clavos': 'Clavos',
      'tornillos': 'Tornillos y tarugos',
    };
    return nombres[tipoVisual] ?? 'Otros';
  }
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
    int? stockMinimo,
    String? fuente,
    String? urlFuente,
    DateTime? fechaPrecio,
    double? calidad,
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
      stockMinimo: stockMinimo ?? this.stockMinimo,
      fuente: fuente ?? this.fuente,
      urlFuente: urlFuente ?? this.urlFuente,
      fechaPrecio: fechaPrecio ?? this.fechaPrecio,
      calidad: calidad ?? this.calidad,
    );
  }
}
