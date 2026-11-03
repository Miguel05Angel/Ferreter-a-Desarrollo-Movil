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

  static const Usuario vendedorDemo = Usuario(
    id: 'u-2',
    nombre: 'Lucia Quispe',
    email: 'vendedor@ferreteria.com',
    telefono: '965432178',
    password: 'vendedor1',
    rol: 'Vendedor',
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
    const Producto(
      id: 'p-21', codigo: 'HER-006', nombre: 'Alicate universal 8"',
      descripcion: 'Alicate de acero forjado con mango aislado, ideal para cortar y sujetar.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 18.90, precioCompra: 11.00, stock: 40,
      tipoVisual: 'llaves', colorHex: 0xFF78909C),
    const Producto(
      id: 'p-22', codigo: 'HER-007', nombre: 'Llave francesa 10"',
      descripcion: 'Llave ajustable de acero cromado con apertura de hasta 30 mm.',
      categoriaId: 'cat-1', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 24.90, precioCompra: 15.00, stock: 28,
      tipoVisual: 'llaves', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-23', codigo: 'HER-008', nombre: 'Juego de destornilladores 6 pzas',
      descripcion: 'Set de destornilladores planos y Phillips con punta magnetica.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Juego',
      precioVenta: 29.90, precioCompra: 17.50, stock: 22,
      tipoVisual: 'llaves', colorHex: 0xFFE53935),
    const Producto(
      id: 'p-24', codigo: 'HER-009', nombre: 'Mazo de goma 16 oz',
      descripcion: 'Mazo de goma para trabajos que no deben marcar la superficie.',
      categoriaId: 'cat-1', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 19.90, precioCompra: 11.00, stock: 18,
      tipoVisual: 'martillo', colorHex: 0xFF455A64),
    const Producto(
      id: 'p-25', codigo: 'HER-010', nombre: 'Comba 4 lb',
      descripcion: 'Comba de acero con mango de madera para demolicion liviana.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 39.90, precioCompra: 25.00, stock: 12,
      tipoVisual: 'martillo', colorHex: 0xFF6D4C41),
    const Producto(
      id: 'p-26', codigo: 'HER-011', nombre: 'Taladro inalambrico 12V',
      descripcion: 'Taladro atornillador con bateria de litio y cargador rapido.',
      categoriaId: 'cat-1', marca: 'Foset', unidad: 'Unidad',
      precioVenta: 259.00, precioCompra: 185.00, stock: 8,
      tipoVisual: 'taladro', colorHex: 0xFF43A047),
    const Producto(
      id: 'p-27', codigo: 'HER-012', nombre: 'Rotomartillo 1000W',
      descripcion: 'Rotomartillo con tres modos de trabajo para concreto y ladrillo.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 349.00, precioCompra: 255.00, stock: 2,
      tipoVisual: 'taladro', colorHex: 0xFFFF6D00),
    const Producto(
      id: 'p-28', codigo: 'HER-013', nombre: 'Pistola de silicona 40W',
      descripcion: 'Pistola de silicona caliente con gatillo de avance continuo.',
      categoriaId: 'cat-1', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 22.50, precioCompra: 13.00, stock: 26,
      tipoVisual: 'pistola', colorHex: 0xFFFDD835),
    const Producto(
      id: 'p-29', codigo: 'HER-014', nombre: 'Flexometro 8 m',
      descripcion: 'Flexometro con cinta de acero y bloqueo automatico.',
      categoriaId: 'cat-1', marca: 'Truper', unidad: 'Unidad',
      precioVenta: 18.50, precioCompra: 10.50, stock: 44,
      tipoVisual: 'cinta', colorHex: 0xFFE53935),
    const Producto(
      id: 'p-30', codigo: 'HER-015', nombre: 'Wincha de 30 m',
      descripcion: 'Wincha de fibra de vidrio con caja resistente y manivela.',
      categoriaId: 'cat-1', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 32.00, precioCompra: 20.00, stock: 15,
      tipoVisual: 'cinta', colorHex: 0xFF1E88E5),
    const Producto(
      id: 'p-31', codigo: 'PIN-005', nombre: 'Pintura latex matizado 4 galones',
      descripcion: 'Balde de 4 galones de latex lavable. Elige el color.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 245.00, precioCompra: 172.00, stock: 14,
      tipoVisual: 'pintura', colorHex: 0xFF90CAF9,
      coloresHex: coloresPintura),
    const Producto(
      id: 'p-32', codigo: 'PIN-006', nombre: 'Barniz marino 1 galon',
      descripcion: 'Barniz transparente de alta proteccion para madera expuesta.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 72.00, precioCompra: 48.00, stock: 19,
      tipoVisual: 'pintura', colorHex: 0xFFFFB74D),
    const Producto(
      id: 'p-33', codigo: 'PIN-007', nombre: 'Imprimante blanco 1 galon',
      descripcion: 'Base selladora para mejorar la adherencia de la pintura.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 54.00, precioCompra: 36.00, stock: 21,
      tipoVisual: 'pintura', colorHex: 0xFFF5F5F5),
    const Producto(
      id: 'p-34', codigo: 'PIN-008', nombre: 'Thinner acrilico 1 galon',
      descripcion: 'Diluyente para pinturas y limpieza de herramientas.',
      categoriaId: 'cat-2', marca: 'Andina', unidad: 'Galon',
      precioVenta: 38.00, precioCompra: 24.00, stock: 4,
      tipoVisual: 'pintura', colorHex: 0xFF78909C),
    const Producto(
      id: 'p-35', codigo: 'PIN-009', nombre: 'Rodillo antigota 7 pulg',
      descripcion: 'Rodillo de microfibra que no salpica, para paredes y techos.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 12.50, precioCompra: 6.50, stock: 38,
      tipoVisual: 'rodillo', colorHex: 0xFFFFA726),
    const Producto(
      id: 'p-36', codigo: 'PIN-010', nombre: 'Mini rodillo 4 pulg',
      descripcion: 'Rodillo pequeno para esquinas y detalles.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 6.50, precioCompra: 3.00, stock: 50,
      tipoVisual: 'rodillo', colorHex: 0xFF26C6DA),
    const Producto(
      id: 'p-37', codigo: 'PIN-011', nombre: 'Brocha 4 pulgadas',
      descripcion: 'Brocha de cerda sintetica para superficies grandes.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 14.90, precioCompra: 8.00, stock: 33,
      tipoVisual: 'brocha', colorHex: 0xFF5D4037),
    const Producto(
      id: 'p-38', codigo: 'PIN-012', nombre: 'Brocha 1 pulgada',
      descripcion: 'Brocha fina para retoques y bordes.',
      categoriaId: 'cat-2', marca: 'Pretul', unidad: 'Unidad',
      precioVenta: 3.50, precioCompra: 1.40, stock: 90,
      tipoVisual: 'brocha', colorHex: 0xFFFF7043),
    const Producto(
      id: 'p-39', codigo: 'TUB-005', nombre: 'Tuberia PVC 3/4" x 3 m',
      descripcion: 'Tuberia PVC presion para agua fria de 3/4 de pulgada.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 15.50, precioCompra: 9.50, stock: 70,
      tipoVisual: 'tubo', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-40', codigo: 'TUB-006', nombre: 'Tuberia PVC desague 4" x 3 m',
      descripcion: 'Tuberia de desague de 4 pulgadas, serie liviana.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 38.90, precioCompra: 26.00, stock: 25,
      tipoVisual: 'tubo', colorHex: 0xFF9E9E9E),
    const Producto(
      id: 'p-41', codigo: 'TUB-007', nombre: 'Tuberia CPVC agua caliente 1/2"',
      descripcion: 'Tuberia CPVC para instalaciones de agua caliente.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 21.50, precioCompra: 13.50, stock: 40,
      tipoVisual: 'tubo', colorHex: 0xFFFFCC80),
    const Producto(
      id: 'p-42', codigo: 'TUB-008', nombre: 'Codo PVC 90 grados 3/4"',
      descripcion: 'Codo de 90 grados para tuberia PVC de 3/4 pulgada.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 1.80, precioCompra: 0.80, stock: 200,
      tipoVisual: 'codo', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-43', codigo: 'TUB-009', nombre: 'Codo PVC 45 grados 1/2"',
      descripcion: 'Codo de 45 grados para tuberia PVC de 1/2 pulgada.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 1.50, precioCompra: 0.65, stock: 180,
      tipoVisual: 'codo', colorHex: 0xFFCFD8DC),
    const Producto(
      id: 'p-44', codigo: 'TUB-010', nombre: 'Union universal PVC 1/2"',
      descripcion: 'Union desmontable para facilitar el mantenimiento.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 3.20, precioCompra: 1.60, stock: 120,
      tipoVisual: 'codo', colorHex: 0xFF90A4AE),
    const Producto(
      id: 'p-45', codigo: 'TUB-011', nombre: 'Pegamento PVC 1/4 galon',
      descripcion: 'Pegamento de secado rapido para uniones de PVC.',
      categoriaId: 'cat-3', marca: 'Tuboplas', unidad: 'Unidad',
      precioVenta: 38.00, precioCompra: 24.00, stock: 18,
      tipoVisual: 'pega', colorHex: 0xFF1E88E5),
    const Producto(
      id: 'p-46', codigo: 'TUB-012', nombre: 'Manguera de jardin 15 m',
      descripcion: 'Manguera flexible de jardin con acoples incluidos.',
      categoriaId: 'cat-3', marca: 'Foset', unidad: 'Unidad',
      precioVenta: 59.90, precioCompra: 38.00, stock: 14,
      tipoVisual: 'manguera', colorHex: 0xFF43A047),
    const Producto(
      id: 'p-47', codigo: 'ELE-004', nombre: 'Cable THW 14 AWG (metro)',
      descripcion: 'Cable de cobre aislado para instalaciones electricas.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Metro',
      precioVenta: 1.60, precioCompra: 0.95, stock: 600,
      tipoVisual: 'cable', colorHex: 0xFFE53935),
    const Producto(
      id: 'p-48', codigo: 'ELE-005', nombre: 'Cable de extension 10 m',
      descripcion: 'Extension de 10 metros con enchufe y tomacorriente.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Unidad',
      precioVenta: 34.90, precioCompra: 22.00, stock: 20,
      tipoVisual: 'cable', colorHex: 0xFFFFB300),
    const Producto(
      id: 'p-49', codigo: 'ELE-006', nombre: 'Cable vehicular 16 AWG (metro)',
      descripcion: 'Cable flexible para instalaciones automotrices.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Metro',
      precioVenta: 1.10, precioCompra: 0.60, stock: 300,
      tipoVisual: 'cable', colorHex: 0xFF546E7A),
    const Producto(
      id: 'p-50', codigo: 'ELE-007', nombre: 'Tomacorriente doble',
      descripcion: 'Tomacorriente doble con linea a tierra para empotrar.',
      categoriaId: 'cat-4', marca: 'Iusa', unidad: 'Unidad',
      precioVenta: 7.90, precioCompra: 4.20, stock: 75,
      tipoVisual: 'interruptor', colorHex: 0xFFFAFAFA),
    const Producto(
      id: 'p-51', codigo: 'ELE-008', nombre: 'Interruptor doble',
      descripcion: 'Interruptor doble de embutir con placa incluida.',
      categoriaId: 'cat-4', marca: 'Iusa', unidad: 'Unidad',
      precioVenta: 8.50, precioCompra: 4.60, stock: 60,
      tipoVisual: 'interruptor', colorHex: 0xFFEEEEEE),
    const Producto(
      id: 'p-52', codigo: 'ELE-009', nombre: 'Interruptor termomagnetico 20A',
      descripcion: 'Proteccion termomagnetica monopolar de 20 amperios.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Unidad',
      precioVenta: 28.00, precioCompra: 17.50, stock: 24,
      tipoVisual: 'interruptor', colorHex: 0xFF42A5F5),
    const Producto(
      id: 'p-53', codigo: 'ELE-010', nombre: 'Foco LED 15W E27',
      descripcion: 'Foco LED de luz blanca, bajo consumo y larga duracion.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Unidad',
      precioVenta: 14.90, precioCompra: 8.20, stock: 85,
      tipoVisual: 'foco', colorHex: 0xFFFFF59D),
    const Producto(
      id: 'p-54', codigo: 'ELE-011', nombre: 'Reflector LED 50W',
      descripcion: 'Reflector LED para exteriores resistente al agua.',
      categoriaId: 'cat-4', marca: 'Volteck', unidad: 'Unidad',
      precioVenta: 79.90, precioCompra: 52.00, stock: 11,
      tipoVisual: 'foco', colorHex: 0xFFE0E0E0),
    const Producto(
      id: 'p-55', codigo: 'CEM-003', nombre: 'Cemento Andino tipo I 42.5 kg',
      descripcion: 'Cemento de uso general para obras de concreto.',
      categoriaId: 'cat-5', marca: 'Andino', unidad: 'Bolsa',
      precioVenta: 28.50, precioCompra: 22.00, stock: 120,
      tipoVisual: 'cemento', colorHex: 0xFF9E9E9E),
    const Producto(
      id: 'p-56', codigo: 'CEM-004', nombre: 'Yeso en bolsa 25 kg',
      descripcion: 'Yeso para tarrajeo y acabados interiores.',
      categoriaId: 'cat-5', marca: 'Sol', unidad: 'Bolsa',
      precioVenta: 14.50, precioCompra: 9.50, stock: 60,
      tipoVisual: 'cemento', colorHex: 0xFFEEEEEE),
    const Producto(
      id: 'p-57', codigo: 'CEM-005', nombre: 'Cal hidratada 20 kg',
      descripcion: 'Cal hidratada para mezclas y acabados.',
      categoriaId: 'cat-5', marca: 'Sol', unidad: 'Bolsa',
      precioVenta: 11.90, precioCompra: 7.50, stock: 45,
      tipoVisual: 'cemento', colorHex: 0xFFE0E0E0),
    const Producto(
      id: 'p-58', codigo: 'CEM-006', nombre: 'Fierro corrugado 1/2" x 9 m',
      descripcion: 'Barra de acero corrugado para estructuras de concreto.',
      categoriaId: 'cat-5', marca: 'Aceros Arequipa', unidad: 'Unidad',
      precioVenta: 62.00, precioCompra: 48.00, stock: 90,
      tipoVisual: 'fierro', colorHex: 0xFF8D6E63),
    const Producto(
      id: 'p-59', codigo: 'CEM-007', nombre: 'Fierro liso 1/4" x 9 m',
      descripcion: 'Barra de acero liso para estribos y amarres.',
      categoriaId: 'cat-5', marca: 'Aceros Arequipa', unidad: 'Unidad',
      precioVenta: 14.90, precioCompra: 10.20, stock: 150,
      tipoVisual: 'fierro', colorHex: 0xFF78909C),
    const Producto(
      id: 'p-60', codigo: 'CEM-008', nombre: 'Alambre negro N16 (kg)',
      descripcion: 'Alambre recocido para amarrar fierro, venta por kilo.',
      categoriaId: 'cat-5', marca: 'Fiero', unidad: 'Kg',
      precioVenta: 6.90, precioCompra: 4.50, stock: 200,
      tipoVisual: 'fierro', colorHex: 0xFF455A64),
    const Producto(
      id: 'p-61', codigo: 'CTO-003', nombre: 'Clavo para calamina 2 1/2" (kg)',
      descripcion: 'Clavo con arandela para fijar calaminas y techos.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Kg',
      precioVenta: 7.50, precioCompra: 4.80, stock: 80,
      tipoVisual: 'clavos', colorHex: 0xFF90A4AE),
    const Producto(
      id: 'p-62', codigo: 'CTO-004', nombre: 'Clavo de madera 3" (kg)',
      descripcion: 'Clavo comun de 3 pulgadas para carpinteria.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Kg',
      precioVenta: 6.50, precioCompra: 4.20, stock: 110,
      tipoVisual: 'clavos', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-63', codigo: 'CTO-005', nombre: 'Tornillo autorroscante 8x1" (caja 200)',
      descripcion: 'Tornillo autorroscante de acero zincado.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Caja',
      precioVenta: 18.00, precioCompra: 11.00, stock: 40,
      tipoVisual: 'tornillos', colorHex: 0xFFB0BEC5),
    const Producto(
      id: 'p-64', codigo: 'CTO-006', nombre: 'Tarugos plasticos 8 mm (caja 100)',
      descripcion: 'Tarugos de expansion para fijar en pared.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Caja',
      precioVenta: 9.50, precioCompra: 5.20, stock: 65,
      tipoVisual: 'tornillos', colorHex: 0xFFCFD8DC),
    const Producto(
      id: 'p-65', codigo: 'CTO-007', nombre: 'Pernos hexagonales 3/8" (caja 50)',
      descripcion: 'Pernos hexagonales con tuerca y arandela.',
      categoriaId: 'cat-6', marca: 'Fiero', unidad: 'Caja',
      precioVenta: 26.00, precioCompra: 16.50, stock: 30,
      tipoVisual: 'tornillos', colorHex: 0xFF78909C),
    // ---- Productos con precio verificado en tiendas peruanas (23/10/2026) ----
    Producto(
      id: 'v-1', codigo: 'ILU-G01', nombre: 'Foco LED G9 3W luz fria',
      descripcion: 'Foco LED con base G9 (pines). Verifica que tu portalampara sea G9 antes de comprar.',
      categoriaId: 'cat-4', marca: 'Orange', unidad: 'Unidad',
      precioVenta: 6.90, stock: 10,
      tipoVisual: 'foco', colorHex: 0xFFE3F2FD,
      fuente: 'Promart (promart.pe)', urlFuente: 'https://www.promart.pe/iluminacion/g9',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-2', codigo: 'ILU-G02', nombre: 'Foco LED G9 3W luz calida',
      descripcion: 'Foco LED con base G9 (pines). Verifica que tu portalampara sea G9 antes de comprar.',
      categoriaId: 'cat-4', marca: 'Lightech', unidad: 'Unidad',
      precioVenta: 20.90, stock: 10,
      tipoVisual: 'foco', colorHex: 0xFFFFCC80,
      fuente: 'Promart (promart.pe)', urlFuente: 'https://www.promart.pe/iluminacion/g9',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-3', codigo: 'ILU-G03', nombre: 'Foco LED G9 9W luz calida 3000K',
      descripcion: 'Foco LED con base G9 (pines). Verifica que tu portalampara sea G9 antes de comprar.',
      categoriaId: 'cat-4', marca: 'Generico', unidad: 'Unidad',
      precioVenta: 17.90, stock: 10,
      tipoVisual: 'foco', colorHex: 0xFFFFCC80,
      fuente: 'Promart (promart.pe)', urlFuente: 'https://www.promart.pe/iluminacion/g9',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-4', codigo: 'TEF-001', nombre: 'Cinta de teflon sella roscas TC1078',
      descripcion: 'Cinta de teflon para sellar roscas, uso con gas y agua.',
      categoriaId: 'cat-3', marca: 'Toolcraft', unidad: 'Unidad',
      precioVenta: 5.90, stock: 10,
      tipoVisual: 'cinta', colorHex: 0xFFFAFAFA,
      fuente: 'Plaza Vea (plazavea.com.pe)', urlFuente: 'https://www.plazavea.com.pe/lbc/selladores-y-pegamentos-para-bricolaje',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-5', codigo: 'AIS-001', nombre: 'Juego de cintas aislantes de colores 18 mm x 6 m',
      descripcion: 'Juego de cintas aislantes de colores para instalaciones electricas (FP0020).',
      categoriaId: 'cat-4', marca: 'Fulgore', unidad: 'Unidad',
      precioVenta: 10.90, stock: 10,
      tipoVisual: 'cinta', colorHex: 0xFF212121,
      fuente: 'Plaza Vea (plazavea.com.pe)', urlFuente: 'https://www.plazavea.com.pe/lbc/selladores-y-pegamentos-para-bricolaje',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-6', codigo: 'EPO-001', nombre: 'Pegamento epoxico blanco',
      descripcion: 'Pegamento epoxico de dos componentes, color blanco.',
      categoriaId: 'cat-3', marca: 'Pegatanke', unidad: 'Unidad',
      precioVenta: 25.00, stock: 10,
      tipoVisual: 'pega', colorHex: 0xFFFAFAFA,
      fuente: 'Plaza Vea (plazavea.com.pe)', urlFuente: 'https://www.plazavea.com.pe/lbc/selladores-y-pegamentos-para-bricolaje',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-7', codigo: 'LAT-001', nombre: 'Pintura Latex Pato Mate Blanco 4GL',
      descripcion: 'Pintura latex mate blanco, presentacion de 4 galones.',
      categoriaId: 'cat-2', marca: 'Generico', unidad: 'Unidad',
      precioVenta: 124.00, stock: 10,
      tipoVisual: 'pintura', colorHex: 0xFFF5F5F5,
      coloresHex: coloresPintura,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/lista/CATG46233/Pinturas',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-8', codigo: 'LAT-002', nombre: 'Pintura American Latex Mate Blanco 4GL',
      descripcion: 'Pintura latex mate blanco, presentacion de 4 galones.',
      categoriaId: 'cat-2', marca: 'American Colors', unidad: 'Unidad',
      precioVenta: 364.50, stock: 10,
      tipoVisual: 'pintura', colorHex: 0xFFF5F5F5,
      coloresHex: coloresPintura,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/lista/CATG46233/Pinturas',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-9', codigo: 'LAT-003', nombre: 'Pintura Latex Semi Satinado Blanco 4GL',
      descripcion: 'Pintura latex semi satinada blanca, presentacion de 4 galones.',
      categoriaId: 'cat-2', marca: 'Generico', unidad: 'Unidad',
      precioVenta: 377.40, stock: 10,
      tipoVisual: 'pintura', colorHex: 0xFFF5F5F5,
      coloresHex: coloresPintura,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/lista/CATG46233/Pinturas',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-10', codigo: 'ROD-001', nombre: 'Rodillo para Base o Acabado 9"',
      descripcion: 'Rodillo de 9 pulgadas para aplicar base o acabado.',
      categoriaId: 'cat-2', marca: 'Pintor', unidad: 'Unidad',
      precioVenta: 21.00, stock: 10,
      tipoVisual: 'rodillo', colorHex: 0xFF42A5F5,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/marca/PINTOR',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-11', codigo: 'ROD-002', nombre: 'Rodillo para Acabado 9"',
      descripcion: 'Rodillo de 9 pulgadas para acabado.',
      categoriaId: 'cat-2', marca: 'Pintor', unidad: 'Unidad',
      precioVenta: 21.90, stock: 10,
      tipoVisual: 'rodillo', colorHex: 0xFF42A5F5,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/marca/PINTOR',
      fechaPrecio: DateTime(2026, 10, 25)),
    Producto(
      id: 'v-12', codigo: 'ROD-003', nombre: 'Rodillo para pintar verde 12"',
      descripcion: 'Rodillo de 12 pulgadas para pintar paredes amplias.',
      categoriaId: 'cat-2', marca: 'Pintor', unidad: 'Unidad',
      precioVenta: 31.50, stock: 10,
      tipoVisual: 'rodillo', colorHex: 0xFF66BB6A,
      fuente: 'Sodimac (sodimac.com.pe)', urlFuente: 'https://www.sodimac.com.pe/sodimac-pe/marca/PINTOR',
      fechaPrecio: DateTime(2026, 10, 25)),
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
    const Proveedor(
      id: 'pr-5', nombre: 'Tuboplas Distribuciones S.A.C.',
      ruc: '20567890123', telefono: '945221133',
      direccion: 'Av. Industrial 1020, Ate',
      productos: ['Tuberias PVC', 'Codos y uniones', 'Mangueras', 'Pegamentos']),
    const Proveedor(
      id: 'pr-6', nombre: 'Fiero Ferreteria Industrial E.I.R.L.',
      ruc: '20678123456', telefono: '956781234',
      direccion: 'Jr. Cusco 455, Cercado de Lima',
      productos: ['Clavos', 'Tornillos', 'Pernos', 'Fijaciones']),
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
