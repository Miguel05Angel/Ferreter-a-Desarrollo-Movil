/// Utilidades para trabajar con dinero sin errores de decimales.
class Dinero {
  Dinero._();

  /// Redondea a 2 decimales (centimos).
  static double r2(double v) => (v * 100).round() / 100;

  /// Convierte a centimos enteros.
  static int centimos(double v) => (v * 100).round();

  /// Redondeo de pagos en EFECTIVO en Peru: el total se redondea a favor del
  /// consumidor a multiplos de S/ 0.10 (Codigo de Proteccion y Defensa del
  /// Consumidor, art. 44, y Circular BCRP 002-2011). Ejemplos: 9.96 -> 9.90,
  /// 106.08 -> 106.00. Solo aplica al pago en efectivo; Yape, Plin y tarjeta
  /// conservan los centimos.
  static double totalEnEfectivo(double total) {
    final c = centimos(total);
    return (c - c % 10) / 100;
  }

  /// Cuanto se descuenta al cliente por el redondeo en efectivo.
  static double redondeoEfectivo(double total) =>
      r2(total - totalEnEfectivo(total));
}
