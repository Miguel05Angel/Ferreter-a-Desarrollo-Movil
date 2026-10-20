class Proveedor {
  final String id;
  final String nombre;
  final String ruc;
  final String telefono;
  final String direccion;
  final List<String> productos;

  const Proveedor({
    required this.id,
    required this.nombre,
    required this.ruc,
    required this.telefono,
    required this.direccion,
    this.productos = const [],
  });

  Proveedor copyWith({
    String? id,
    String? nombre,
    String? ruc,
    String? telefono,
    String? direccion,
    List<String>? productos,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ruc: ruc ?? this.ruc,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      productos: productos ?? this.productos,
    );
  }
}
