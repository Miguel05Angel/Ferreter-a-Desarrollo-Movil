/// Reglas de acceso de la aplicacion segun el rol del usuario.
///
/// ADMINISTRADOR: control total del negocio.
/// VENDEDOR: atiende al cliente y registra ventas, pero no toca el
/// catalogo, los costos, los proveedores ni los usuarios.
class Permisos {
  final String rol;
  const Permisos(this.rol);

  static const String admin = 'Administrador';
  static const String vendedor = 'Vendedor';
  static const List<String> roles = [admin, vendedor];

  bool get esAdmin => rol == admin;
  bool get esVendedor => !esAdmin;

  /// Crear, editar y eliminar productos.
  bool get gestionaProductos => esAdmin;

  /// Ver precio de compra, ganancia y margen.
  bool get veCostos => esAdmin;

  /// Entrar al modulo de proveedores.
  bool get gestionaProveedores => esAdmin;

  /// Eliminar clientes (crear y editar lo puede hacer cualquiera).
  bool get eliminaClientes => esAdmin;

  /// Ver el historial de TODAS las ventas (el vendedor ve solo las suyas).
  bool get veTodasLasVentas => esAdmin;

  /// Cambiar roles de otros usuarios.
  bool get gestionaUsuarios => esAdmin;

  List<String> get puede => esAdmin
      ? const [
          'Vender y emitir boletas o facturas',
          'Crear, editar y eliminar productos',
          'Ver costos, ganancias y margenes',
          'Administrar clientes y proveedores',
          'Ver todas las ventas del negocio',
          'Cambiar el rol de los usuarios',
        ]
      : const [
          'Vender y emitir boletas o facturas',
          'Consultar productos y su stock',
          'Registrar y editar clientes',
          'Crear cotizaciones',
          'Ver sus propias ventas',
        ];

  List<String> get noPuede => esAdmin
      ? const []
      : const [
          'Crear, editar o eliminar productos',
          'Ver precios de compra ni ganancias',
          'Entrar a proveedores',
          'Eliminar clientes',
          'Ver ventas de otros vendedores',
        ];
}
