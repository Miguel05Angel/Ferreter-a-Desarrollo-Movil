class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String password;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.password,
    this.rol = 'Administrador',
  });
}
