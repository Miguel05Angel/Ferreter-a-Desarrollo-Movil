class Cliente {
  final String id;
  final String nombre;
  final String tipoDocumento; // DNI o RUC
  final String documento;
  final String telefono;
  final String direccion;
  final String email;
  final bool credito;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.tipoDocumento,
    required this.documento,
    required this.telefono,
    required this.direccion,
    this.email = '',
    this.credito = false,
  });

  Cliente copyWith({
    String? id,
    String? nombre,
    String? tipoDocumento,
    String? documento,
    String? telefono,
    String? direccion,
    String? email,
    bool? credito,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      email: email ?? this.email,
      credito: credito ?? this.credito,
    );
  }
}
