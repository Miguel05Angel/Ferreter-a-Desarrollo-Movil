import 'package:intl/intl.dart';

/// Utilidades de formato para dinero y fechas.
class Formatters {
  Formatters._();

  static final NumberFormat _moneda = NumberFormat('#,##0.00');

  static String soles(double valor) => 'S/ ${_moneda.format(valor)}';

  static String fecha(DateTime fecha) =>
      DateFormat('dd/MM/yyyy HH:mm').format(fecha);

  static String fechaCorta(DateTime fecha) =>
      DateFormat('dd/MM/yyyy').format(fecha);

  static String hora(DateTime fecha) => DateFormat('HH:mm').format(fecha);
}
