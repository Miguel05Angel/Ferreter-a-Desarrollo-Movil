import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/venta.dart';
import 'xlsx_writer.dart';

/// Exporta el analisis de ventas a un libro de Excel con hojas organizadas:
/// Resumen, Ventas, Detalle, Por dia, Por metodo de pago y Por categoria.
class ExportadorVentas {
  ExportadorVentas._();

  static const _dias = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];

  static String _f(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  static String _h(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static double _r(double v) => (v * 100).round() / 100;
  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Genera el archivo y abre el menu de compartir del dispositivo.
  /// [categoriaDe] devuelve el nombre de la categoria de un producto.
  static Future<void> compartirExcel({
    required List<Venta> ventas,
    required String Function(String productoId) categoriaDe,
    String etiquetaPeriodo = 'Todas las ventas',
  }) async {
    final bytes = XlsxWriter.construir(hojas(ventas, categoriaDe, etiquetaPeriodo));
    final dir = await getTemporaryDirectory();
    final ahora = DateTime.now();
    final nombre = 'Ventas_${ahora.year}${ahora.month.toString().padLeft(2, '0')}'
        '${ahora.day.toString().padLeft(2, '0')}_'
        '${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}.xlsx';
    final archivo = File('${dir.path}/$nombre');
    await archivo.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(archivo.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      ],
      subject: 'Reporte de ventas',
      text: 'Reporte de ventas - ${AppConstants.nombreApp}',
    );
  }

  static List<XlsxHoja> hojas(
    List<Venta> origen,
    String Function(String) categoriaDe,
    String etiquetaPeriodo,
  ) {
    final ventas = [...origen]..sort((a, b) => a.fecha.compareTo(b.fecha));
    final total = ventas.fold(0.0, (s, v) => s + v.total);
    final igv = ventas.fold(0.0, (s, v) => s + v.igv);
final unidades = ventas.fold<int>(
    0, (s, v) => s + v.items.fold<int>(0, (a, i) => a + i.cantidad));
    final porDia = <DateTime, List<Venta>>{};
    final porMetodo = <String, List<Venta>>{};
    final porComprobante = <String, List<Venta>>{};
    final porCategoria = <String, List<double>>{}; // [unidades, importe]
    for (final v in ventas) {
      porDia.putIfAbsent(_dia(v.fecha), () => []).add(v);
      porMetodo.putIfAbsent(v.metodoPago, () => []).add(v);
      porComprobante.putIfAbsent(v.comprobante, () => []).add(v);
      for (final i in v.items) {
        final c = porCategoria.putIfAbsent(categoriaDe(i.productoId), () => [0, 0]);
        c[0] += i.cantidad;
        c[1] += i.subtotal;
      }
    }

    double suma(List<Venta> l) => l.fold(0.0, (s, v) => s + v.total);
    double pct(double x) => total <= 0 ? 0 : _r(x / total * 100);

    String? mejorDia;
    var mejorMonto = 0.0;
    porDia.forEach((d, l) {
      final s = suma(l);
      if (s > mejorMonto) {
        mejorMonto = s;
        mejorDia = _f(d);
      }
    });

    const enc = XlsxWriter.sEncabezado;
    const mon = XlsxWriter.sMoneda;
    const neg = XlsxWriter.sNegrita;
    const ent = XlsxWriter.sEntero;

    // ------------------------------------------------------------ Resumen
    final resumen = <List<Object?>>[
      [const Cel('REPORTE DE VENTAS', XlsxWriter.sTitulo)],
      [const Cel('Negocio', neg), AppConstants.nombreApp],
      [const Cel('Generado', neg), '${_f(DateTime.now())} ${_h(DateTime.now())}'],
      [const Cel('Alcance', neg), etiquetaPeriodo],
      [],
      [const Cel('INDICADORES', enc), const Cel('Valor', enc)],
      ['Cantidad de ventas', Cel(ventas.length, ent)],
      ['Monto total (S/)', Cel(_r(total), mon)],
      ['IGV total (S/)', Cel(_r(igv), mon)],
      ['Ticket promedio (S/)', Cel(ventas.isEmpty ? 0 : _r(total / ventas.length), mon)],
      ['Productos vendidos (unidades)', Cel(unidades, ent)],
      ['Mejor dia', mejorDia == null ? '-' : '$mejorDia  (S/ ${mejorMonto.toStringAsFixed(2)})'],
      [],
      [const Cel('COMPROBANTE', enc), const Cel('Ventas', enc), const Cel('Total (S/)', enc), const Cel('% del total', enc)],
      for (final e in porComprobante.entries)
        [e.key, Cel(e.value.length, ent), Cel(_r(suma(e.value)), mon), Cel(pct(suma(e.value)), mon)],
    ];

    // ------------------------------------------------------------ Ventas
    final hojaVentas = <List<Object?>>[
      [
        const Cel('N° Venta', enc), const Cel('Fecha', enc), const Cel('Hora', enc),
        const Cel('Cliente', enc), const Cel('Comprobante', enc), const Cel('Metodo de pago', enc),
        const Cel('Vendedor', enc), const Cel('Items', enc), const Cel('Subtotal (S/)', enc),
        const Cel('IGV (S/)', enc), const Cel('Redondeo (S/)', enc), const Cel('Total (S/)', enc),
      ],
      for (final v in ventas)
        [
          v.numero, _f(v.fecha), _h(v.fecha), v.clienteNombre, v.comprobante,
          v.metodoPago, v.vendedor.isEmpty ? '-' : v.vendedor,
Cel(v.items.fold<int>(0, (a, i) => a + i.cantidad), ent),
          Cel(_r(v.subtotal), mon), Cel(_r(v.igv), mon), Cel(_r(v.redondeo), mon), Cel(_r(v.total), mon),
        ],
      if (ventas.isNotEmpty)
        [
          const Cel('TOTAL', neg), null, null, null, null, null, null, null,
          Cel(_r(ventas.fold(0.0, (s, v) => s + v.subtotal)), mon),
          Cel(_r(igv), mon),
          Cel(_r(ventas.fold(0.0, (s, v) => s + v.redondeo)), mon),
          Cel(_r(total), mon),
        ],
    ];

    // ------------------------------------------------------------ Detalle
    final detalle = <List<Object?>>[
      [
        const Cel('N° Venta', enc), const Cel('Fecha', enc), const Cel('Cliente', enc),
        const Cel('Producto', enc), const Cel('Categoria', enc), const Cel('Cantidad', enc),
        const Cel('P. unitario (S/)', enc), const Cel('Importe (S/)', enc),
      ],
      for (final v in ventas)
        for (final i in v.items)
          [
            v.numero, _f(v.fecha), v.clienteNombre, i.nombre, categoriaDe(i.productoId),
            Cel(i.cantidad, ent), Cel(_r(i.precioUnitario), mon), Cel(_r(i.subtotal), mon),
          ],
    ];

    // ------------------------------------------------------------ Por dia
    final dias = porDia.keys.toList()..sort();
    final hojaDias = <List<Object?>>[
      [
        const Cel('Fecha', enc), const Cel('Dia', enc), const Cel('Ventas', enc),
        const Cel('Total (S/)', enc), const Cel('Ticket promedio (S/)', enc),
      ],
      for (final d in dias)
        [
          _f(d), _dias[d.weekday - 1], Cel(porDia[d]!.length, ent),
          Cel(_r(suma(porDia[d]!)), mon), Cel(_r(suma(porDia[d]!) / porDia[d]!.length), mon),
        ],
    ];

    // ------------------------------------------------------------ Por metodo
    final hojaMetodos = <List<Object?>>[
      [const Cel('Metodo de pago', enc), const Cel('Ventas', enc), const Cel('Total (S/)', enc), const Cel('% del total', enc)],
      for (final e in porMetodo.entries)
        [e.key, Cel(e.value.length, ent), Cel(_r(suma(e.value)), mon), Cel(pct(suma(e.value)), mon)],
    ];

    // ------------------------------------------------------------ Por categoria
    final totalCat = porCategoria.values.fold(0.0, (s, e) => s + e[1]);
    final hojaCategorias = <List<Object?>>[
      [const Cel('Categoria', enc), const Cel('Unidades', enc), const Cel('Importe (S/)', enc), const Cel('% del total', enc)],
      for (final e in porCategoria.entries)
        [
          e.key, Cel(e.value[0].round(), ent), Cel(_r(e.value[1]), mon),
          Cel(totalCat <= 0 ? 0 : _r(e.value[1] / totalCat * 100), mon),
        ],
    ];

    return [
      XlsxHoja('Resumen', resumen, anchos: const [34, 20, 16, 14]),
      XlsxHoja('Ventas', hojaVentas,
          anchos: const [16, 12, 8, 30, 14, 15, 18, 8, 14, 12, 14, 14]),
      XlsxHoja('Detalle', detalle, anchos: const [16, 12, 30, 40, 18, 10, 16, 14]),
      XlsxHoja('Por dia', hojaDias, anchos: const [14, 14, 10, 14, 20]),
      XlsxHoja('Por metodo de pago', hojaMetodos, anchos: const [20, 10, 14, 12]),
      XlsxHoja('Por categoria', hojaCategorias, anchos: const [26, 12, 14, 12]),
    ];
  }
}
