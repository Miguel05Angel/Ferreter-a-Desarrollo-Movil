import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Permisos segun el rol del usuario.
///
/// ADMINISTRADOR: control total (productos, costos y ganancias, proveedores,
/// eliminar registros y ver las ventas de todos los vendedores).
///
/// VENDEDOR: vende, emite comprobantes, registra y edita clientes, hace
/// cotizaciones y consulta el catalogo. No ve costos, no gestiona productos
/// ni proveedores, no elimina registros y solo ve sus propias ventas.
class Permisos {
  final String rol;

  const Permisos(this.rol);

  /// Obtiene los permisos del usuario actual y se actualiza si cambia.
  factory Permisos.de(BuildContext context) => Permisos(
      context.watch<AuthProvider>().usuarioActual?.rol ?? 'Vendedor');

  /// Igual que [de] pero sin suscribirse a cambios (para callbacks).
  factory Permisos.leer(BuildContext context) => Permisos(
      context.read<AuthProvider>().usuarioActual?.rol ?? 'Vendedor');

  static const String administrador = 'Administrador';
  static const String vendedor = 'Vendedor';

  bool get esAdmin => rol == administrador;

  bool get puedeVender => true;
  bool get puedeEmitirComprobantes => true;
  bool get puedeHacerCotizaciones => true;
  bool get puedeRegistrarClientes => true;
  bool get puedeEditarClientes => true;

  bool get puedeGestionarProductos => esAdmin;
  bool get puedeVerCostos => esAdmin;
  bool get puedeVerProveedores => esAdmin;
  bool get puedeSolicitarReposicion => esAdmin;
  bool get puedeEliminarClientes => esAdmin;
  bool get puedeEliminarCotizaciones => esAdmin;
  bool get puedeVerTodasLasVentas => esAdmin;

  /// Lista para mostrar en el perfil: (descripcion, permitido).
  List<(String, bool)> get resumen => [
        ('Registrar ventas y emitir boletas o facturas', puedeVender),
        ('Compartir comprobantes en PDF o imagen', puedeEmitirComprobantes),
        ('Registrar y editar clientes', puedeRegistrarClientes),
        ('Crear cotizaciones', puedeHacerCotizaciones),
        ('Crear, editar y eliminar productos', puedeGestionarProductos),
        ('Ver precios de compra y ganancias', puedeVerCostos),
        ('Gestionar proveedores', puedeVerProveedores),
        ('Solicitar reposicion de stock a proveedores', puedeSolicitarReposicion),
        ('Eliminar clientes', puedeEliminarClientes),
        ('Eliminar cotizaciones', puedeEliminarCotizaciones),
        ('Ver las ventas de todos los vendedores', puedeVerTodasLasVentas),
      ];
}
