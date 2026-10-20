import 'package:flutter/material.dart';

import 'models/categoria.dart';
import 'models/cliente.dart';
import 'models/cotizacion.dart';
import 'models/producto.dart';
import 'models/proveedor.dart';
import 'models/usuario.dart';
import 'models/venta.dart';

/// Datos de ejemplo basados en el levantamiento de informacion
/// realizado en la ferreteria.
class MockData {
  MockData._();

  static const Usuario usuarioDemo = Usuario(
    id: 'u-1',
    nombre: 'Carlos Huaman',
    email: 'admin@ferreteria.com',
    telefono: '987654321',
    password: 'admin123',
  );

  static final List<Categoria> categorias = [
    const Categoria(
        id: 'cat-1', nombre: 'Herramientas', icono: Icons.handyman, color: Color(0xFFFF6D00)),
    const Categoria(
        id: 'cat-2', nombre: 'Pinturas', icono: Icons.format_paint, color: Color(0xFF7B1FA2)),
    const Categoria(
        id: 'cat-3', nombre: 'Tuberias', icono: Icons.plumbing, color: Color(0xFF0277BD)),
    const Categoria(
        id: 'cat-4', nombre: 'Material electrico', icono: Icons.electrical_services, color: Color(0xFFF9A825)),
    const Categoria(
        id: 'cat-5', nombre: 'Cemento y obra', icono: Icons.construction, color: Color(0xFF616161)),
    const Categoria(
        id: 'cat-6', nombre: 'Clavos y tornillos', icono: Icons.build, color: Color(0xFF2E7D32)),
  ];

  static const List<int> coloresPintura = [
    0xFFF5F5F5, // blanco
    0xFFE53935, // rojo
    0xFF1E88E5, // azul
    0xFF43A047, // verde
    0xFFFDD835, // amarillo
    0xFF8E24AA, // morado
  ];

  static final List<Producto> productos = [
    const Producto(
      id: 'p-1', codigo: 'HER-001', nombre: 'Taladro percutor 750W',
      descripcion: 'Taladro percutor de 750W con velocidad variable y mango auxiliar.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 189.90, precioCompra: 130.00, stock: 15,
      tipoVisual: 'taladro', colorHex: 0xFF1565C0),
    const Producto(
      id: 'p-2', codigo: 'HER-002', nombre: 'Juego de llaves mixtas 12 pzas',
      descripcion: 'Juego de 12 llaves combinadas en acero al cromo vanadio.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Juego',
      precioVenta: 89.90, precioCompra: 55.00, stock: 20,
      tipoVisual: 'llaves', colorHex: 0xFF90A4AE),
    const Producto(
      id: 'p-3', codigo: 'HER-003', nombre: 'Martillo de carpintero 16 oz',
      descripcion: 'Martillo con cabeza de acero forjado y mango de fibra.',
      categoriaId: 'cat-1', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 24.50, precioCompra: 14.00, stock: 35,
      tipoVisual: 'martillo', colorHex: 0xFF8D6E63),
    const Producto(
      id: 'p-4', codigo: 'HER-004', nombre: 'Pistola de calor 1500W',
      descripcion: 'Pistola de calor con dos temperaturas y accesorios.',
      categoriaId: 'cat-1', marca: 'Foset', unidad: 'Unidad',
      precioVenta: 65.00, precioCompra: 42.00, stock: 3,
      tipoVisual: 'pistola', colorHex: 0xFFE53935),
    const Producto(
      id: 'p-5', codigo: 'HER-005', nombre: 'Cinta metrica 5 m',
      descripcion: 'Cinta metrica de 5 metros con freno y gancho.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 12.90, precioCompra: 6.50, stock: 60,
      tipoVisual: 'cinta', colorHex: 0xFFFFB300),
    const Producto(
      id: 'p-6', codigo: 'PIN-001', nombre: 'Pintura latex blanco 1 galon',
      descripcion: 'Pintura latex lavable para interiores, acabado mate. Elige el color de tu preferencia.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 85.00, precioCompra: 58.00, stock: 25,
      tipoVisual: 'pintura', colorHex: 0xFFF5F5F5,
      coloresHex: coloresPintura),
    const Producto(
      id: 'p-7', codigo: 'PIN-002', nombre: 'Pintura esmalte rojo 1/4 galon',
      descripcion: 'Esmalte sintetico de alto brillo para metal y madera. Elige el color.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 28.50, precioCompra: 17.00, stock: 30,
      tipoVisual: 'pintura', colorHex: 0xFFE53935,
      coloresHex: coloresPintura),
    const Producto(
      id: 'p-8', codigo: 'PIN-003', nombre: 'Rodillo de felpa 9 pulg',
      descripcion: 'Rodillo de felpa para pintura latex con mango plastico.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 9.90, precioCompra: 4.50, stock: 45,
      tipoVisual: 'rodillo', colorHex: 0xFF26A69A),
    const Producto(
      id: 'p-9', codigo: 'PIN-004', nombre: 'Brocha 2 pulgadas',
      descripcion: 'Brocha de cerda natural con mango de madera.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 6.50, precioCompra: 2.80, stock: 80,
      tipoVisual: 'brocha', colorHex: 0xFF8D6E63),
    const Producto(
      id: 'p-10', codigo: 'TUB-001', nombre: 'Tuberia PVC 1/2" x 3 m',
      descripcion: 'Tuberia PVC presion ligera para agua potable.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 14.90, precioCompra: 8.50, stock: 100,
      tipoVisual: 'tubo', colorHex: 0xFFECEFF1),
    const Producto(
      id: 'p-11', codigo: 'TUB-002', nombre: 'Codo PVC 90 grados 1/2"',
      descripcion: 'Codo de 90 grados para tuberia PVC de 1/2 pulgada.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 1.20, precioCompra: 0.50, stock: 300,
      tipoVisual: 'codo', colorHex: 0xFFECEFF1),
    const Producto(
      id: 'p-12', codigo: 'TUB-003', nombre: 'Pega PVC 1/4 kg',
      descripcion: 'Adhesivo para tuberia PVC con aplicador.',
      categoriaId: 'cat-3', marca: 'Foset', unidad: 'Unidad',
      precioVenta: 12.00, precioCompra: 6.00, stock: 40,
      tipoVisual: 'pega', colorHex: 0xFF8E24AA),
    const Producto(
      id: 'p-13', codigo: 'TUB-004', nombre: 'Manguera reforzada 1/2" (metro)',
      descripcion: 'Manguera de PVC reforzada, venta por metro.',
      categoriaId: 'cat-3', marca: 'Foset', unidad: 'Metro',
      precioVenta: 3.50, precioCompra: 1.80, stock: 200,
      tipoVisual: 'manguera', colorHex: 0xFF66BB6A),
    const Producto(
      id: 'p-14', codigo: 'ELE-001', nombre: 'Cable THW 2.5 mm2 (metro)',
      descripcion: 'Cable electrico libre de halogeno, venta por metro.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Metro',
      precioVenta: 2.80, precioCompra: 1.60, stock: 500,
      tipoVisual: 'cable', colorHex: 0xFFFDD835),
    const Producto(
      id: 'p-15', codigo: 'ELE-002', nombre: 'Interruptor sencillo',
      descripcion: 'Interruptor de empotrar 10A 250V.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Unidad',
      precioVenta: 8.90, precioCompra: 4.50, stock: 70,
      tipoVisual: 'interruptor', colorHex: 0xFFFAFAFA),
    const Producto(
      id: 'p-16', codigo: 'ELE-003', nombre: 'Foco LED 9W E27',
      descripcion: 'Foco LED de 9W luz blanca, base E27.',
      categoriaId: 'cat-4', marca: 'Iusa', unidad: 'Unidad',
      precioVenta: 7.50, precioCompra: 3.80, stock: 150,
      tipoVisual: 'foco', colorHex: 0xFFFFF176),
    const Producto(
      id: 'p-17', codigo: 'CEM-001', nombre: 'Cemento Portland 42.5 kg',
      descripcion: 'Cemento Portland tipo I, bolsa de 42.5 kg.',
      categoriaId: 'cat-5', marca: 'Sol', unidad: 'Bolsa',
      precioVenta: 32.50, precioCompra: 26.00, stock: 60,
      tipoVisual: 'cemento', colorHex: 0xFF78909C),
    const Producto(
      id: 'p-18', codigo: 'CEM-002', nombre: 'Fierro corrugado 3/8" x 9 m',
      descripcion: 'Barra de acero corrugado de 3/8 pulgada por 9 metros.',
      categoriaId: 'cat-5', marca: 'Aceros Arequipa', unidad: 'Unidad',
      precioVenta: 38.90, precioCompra: 30.00, stock: 45,
      tipoVisual: 'fierro', colorHex: 0xFF5D4037),
    const Producto(
      id: 'p-19', codigo: 'CTO-001', nombre: 'Clavo de acero 2" (kg)',
      descripcion: 'Clavo de acero de 2 pulgadas, venta por kilogramo.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Kg',
      precioVenta: 9.80, precioCompra: 5.50, stock: 4,
      tipoVisual: 'clavos', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-20', codigo: 'CTO-002', nombre: 'Tornillo drywall 6x1" (caja 500)',
      descripcion: 'Tornillo para drywall con punta de broca, caja de 500 und.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Caja',
      precioVenta: 22.00, precioCompra: 13.00, stock: 55,
      tipoVisual: 'tornillos', colorHex: 0xFF90A4AE),
  ];

  static final List<Cliente> clientes = [
    const Cliente(
      id: 'c-1', nombre: 'Juan Perez Quispe', tipoDocumento: 'DNI',
      documento: '45678901', telefono: '987654321',
      direccion: 'Av. Los Constructores 123, Lima', email: 'juan.perez@gmail.com', credito: true),
    const Cliente(
      id: 'c-2', nombre: 'Constructora Andina S.A.C.', tipoDocumento: 'RUC',
      documento: '20512345678', telefono: '912345678',
      direccion: 'Av. Industrial 456, Callao', credito: true),
    const Cliente(
      id: 'c-3', nombre: 'Maria Torres Flores', tipoDocumento: 'DNI',
      documento: '47890123', telefono: '998877665',
      direccion: 'Calle Las Flores 789, San Juan de Lurigancho'),
    const Cliente(
      id: 'c-4', nombre: 'Pedro Mamani Yupanqui', tipoDocumento: 'DNI',
      documento: '48901234', telefono: '934567890',
      direccion: 'Jr. Prolongacion 321, Comas', credito: true),
    const Cliente(
      id: 'c-5', nombre: 'Ingenieros Civiles del Sur S.R.L.', tipoDocumento: 'RUC',
      documento: '20678901234', telefono: '945678901',
      direccion: 'Av. Sur 890, San Martin de Porres'),
  ];

  static final List<Proveedor> proveedores = [
    const Proveedor(
      id: 'pr-1', nombre: 'Distribuidora Truper Peru S.A.C.',
      ruc: '20123456789', telefono: '987001122',
      direccion: 'Av. Argentina 1450, Callao',
      productos: ['Herramientas manuales', 'Herramientas electricas']),
    const Proveedor(
      id: 'pr-2', nombre: 'Pinturas Andina S.A.',
      ruc: '20234567890', telefono: '912334455',
      direccion: 'Av. Colonial 890, Lima',
      productos: ['Pinturas latex', 'Pinturas esmalte', 'Accesorios de pintura']),
    const Proveedor(
      id: 'pr-3', nombre: 'Materiales Electricos Volteck',
      ruc: '20345678901', telefono: '998445566',
      direccion: 'Calle Santa Rosa 234, La Victoria',
      productos: ['Cables electricos', 'Interruptores', 'Iluminacion LED']),
    const Proveedor(
      id: 'pr-4', nombre: 'Cemento Sol Distribuidora Lima',
      ruc: '20456789012', telefono: '933556677',
      direccion: 'Av. Nestor Gambetta 567, Callao',
      productos: ['Cemento', 'Fierro corrugado', 'Agregados']),
  ];

  static final List<Venta> ventas = [
    Venta(
      id: 'v-1', numero: 'B001-0001', clienteNombre: 'Juan Perez Quispe',
      items: const [
        ItemVenta(productoId: 'p-17', nombre: 'Cemento Portland 42.5 kg', cantidad: 10, precioUnitario: 32.50),
        ItemVenta(productoId: 'p-14', nombre: 'Cable THW 2.5 mm2 (metro)', cantidad: 20, precioUnitario: 2.80),
      ],
      subtotal: 381.00, igv: 68.58, total: 449.58,
      metodoPago: 'Efectivo', comprobante: 'Boleta',
      fecha: DateTime(2026, 10, 18, 10, 30)),
    Venta(
      id: 'v-2', numero: 'B001-0002', clienteNombre: 'Maria Torres Flores',
      items: const [
        ItemVenta(productoId: 'p-6', nombre: 'Pintura latex blanco 1 galon', cantidad: 2, precioUnitario: 85.00),
        ItemVenta(productoId: 'p-8', nombre: 'Rodillo de felpa 9 pulg', cantidad: 2, precioUnitario: 9.90),
      ],
      subtotal: 189.80, igv: 34.16, total: 223.96,
      metodoPago: 'Yape', comprobante: 'Boleta',
      fecha: DateTime(2026, 10, 18, 15, 45)),
    Venta(
      id: 'v-3', numero: 'F001-0001', clienteNombre: 'Constructora Andina S.A.C.',
      items: const [
        ItemVenta(productoId: 'p-18', nombre: 'Fierro corrugado 3/8" x 9 m', cantidad: 30, precioUnitario: 38.90),
      ],
      subtotal: 1167.00, igv: 210.06, total: 1377.06,
      metodoPago: 'Tarjeta', comprobante: 'Factura',
      fecha: DateTime(2026, 10, 19, 9, 10)),
  ];

  static final List<Cotizacion> cotizaciones = [
    Cotizacion(
      id: 'ct-1', clienteNombre: 'Ingenieros Civiles del Sur S.R.L.',
      items: const [
        ItemVenta(productoId: 'p-17', nombre: 'Cemento Portland 42.5 kg', cantidad: 50, precioUnitario: 32.50),
        ItemVenta(productoId: 'p-10', nombre: 'Tuberia PVC 1/2" x 3 m', cantidad: 30, precioUnitario: 14.90),
      ],
      subtotal: 2072.00, igv: 372.96, total: 2444.96,
      validezDias: 15, estado: 'Pendiente',
      fecha: DateTime(2026, 10, 17, 11, 20)),
  ];
}
