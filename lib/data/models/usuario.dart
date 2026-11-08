class Usuario {
  final String id;
  final String dni;
  final String nombre;
  final String telefono;
  final String rol;

  const Usuario({
    required this.id,
    required this.dni,
    required this.nombre,
    required this.telefono,
    required this.rol,
  });

  factory Usuario.desdeFirestore(String id, Map<String, dynamic> datos) {
    return Usuario(
      id: id,
      dni: datos['dni'] as String? ?? '',
      nombre: datos['nombre'] as String? ?? '',
      telefono: datos['telefono'] as String? ?? '',
      rol: datos['rol'] as String? ?? '',
    );
  }
}
