import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Resumen de un dia para colorear el calendario.
class DiaVentas {
  final int ventas;
  final double total;
  const DiaVentas(this.ventas, this.total);
}

/// RANGOS DE COLOR DEL CALENDARIO (faciles de configurar).
///
/// Por defecto se mide por CANTIDAD de ventas del dia:
///   rojo     = 0 ventas
///   amarillo = desde [bajoCantidad] hasta [altoCantidad] - 1  (1 a 4)
///   verde    = [altoCantidad] o mas                            (5 o mas)
/// Tambien puede medirse por MONTO (S/) con [bajoMonto] y [altoMonto].
/// Cambia los valores aqui o desde el engranaje del calendario.
class RangosVentas extends ChangeNotifier {
  RangosVentas._();
  static final RangosVentas instancia = RangosVentas._();

  bool porMonto = false;

  int bajoCantidad = 1;
  int altoCantidad = 5;

  double bajoMonto = 1;
  double altoMonto = 1000;

  static const Color rojo = Color(0xFFD32F2F);
  static const Color amarillo = Color(0xFFF9A825);
  static const Color verde = Color(0xFF2E7D32);

  Color colorDe(DiaVentas? d) {
    final ventas = d?.ventas ?? 0;
    final total = d?.total ?? 0;
    if (ventas == 0) return rojo;
    final valor = porMonto ? total : ventas.toDouble();
    final alto = porMonto ? altoMonto : altoCantidad.toDouble();
    final bajo = porMonto ? bajoMonto : bajoCantidad.toDouble();
    if (valor >= alto) return verde;
    if (valor >= bajo) return amarillo;
    return rojo;
  }

  String get textoRojo => 'Sin ventas';
  String get textoAmarillo => porMonto
      ? 'S/ ${bajoMonto.round()} a S/ ${altoMonto.round() - 1}'
      : '$bajoCantidad a ${altoCantidad - 1} ventas';
  String get textoVerde =>
      porMonto ? 'S/ ${altoMonto.round()} o mas' : '$altoCantidad o mas ventas';

  void actualizar({
    bool? porMonto,
    int? bajoCantidad,
    int? altoCantidad,
    double? bajoMonto,
    double? altoMonto,
  }) {
    this.porMonto = porMonto ?? this.porMonto;
    this.bajoCantidad = bajoCantidad ?? this.bajoCantidad;
    this.altoCantidad = altoCantidad ?? this.altoCantidad;
    this.bajoMonto = bajoMonto ?? this.bajoMonto;
    this.altoMonto = altoMonto ?? this.altoMonto;
    if (this.altoCantidad <= this.bajoCantidad) {
      this.altoCantidad = this.bajoCantidad + 1;
    }
    if (this.altoMonto <= this.bajoMonto) {
      this.altoMonto = this.bajoMonto + 1;
    }
    notifyListeners();
  }
}

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto',
  'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// Calendario donde cada dia se pinta segun las ventas registradas.
class CalendarioTermico extends StatelessWidget {
  final DateTime mes;
  final DateTime seleccionado;
  final Map<DateTime, DiaVentas> datos;
  final ValueChanged<DateTime> onDia;
  final ValueChanged<DateTime> onMes;

  const CalendarioTermico({
    super.key,
    required this.mes,
    required this.seleccionado,
    required this.datos,
    required this.onDia,
    required this.onMes,
  });

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final rangos = RangosVentas.instancia;
    final hoy = _dia(DateTime.now());
    final primero = DateTime(mes.year, mes.month, 1);
    final dias = DateTime(mes.year, mes.month + 1, 0).day;
    final desfase = primero.weekday - 1;
    final filas = ((desfase + dias) / 7).ceil();
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: rangos,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mes anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => onMes(DateTime(mes.year, mes.month - 1)),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        '${_meses[mes.month - 1].toUpperCase()} ${mes.year}',
                        key: ValueKey(mes),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mes siguiente',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => onMes(DateTime(mes.year, mes.month + 1)),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final d in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                    Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (w, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                      scale: Tween(begin: 0.96, end: 1.0).animate(a), child: w),
                ),
                child: Column(
                  key: ValueKey('${mes.year}-${mes.month}'),
                  children: [
                    for (var f = 0; f < filas; f++)
                      Row(
                        children: [
                          for (var c = 0; c < 7; c++)
                            Expanded(
                              child: Builder(builder: (_) {
                                final n = f * 7 + c - desfase + 1;
                                if (n < 1 || n > dias) {
                                  return const AspectRatio(
                                      aspectRatio: 1, child: SizedBox());
                                }
                                final fecha = DateTime(mes.year, mes.month, n);
                                final futuro = fecha.isAfter(hoy);
                                final info = datos[fecha];
                                final color = futuro
                                    ? Colors.grey.withOpacity(0.18)
                                    : rangos.colorDe(info).withOpacity(0.88);
                                final elegido = fecha == _dia(seleccionado);
                                final esHoy = fecha == hoy;
                                return Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: GestureDetector(
                                    onTap: () => onDia(fecha),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        curve: Curves.easeOutBack,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(elegido ? 14 : 8),
                                          border: Border.all(
                                            color: elegido
                                                ? (oscuro
                                                    ? Colors.white
                                                    : AppTheme.grafito)
                                                : (esHoy
                                                    ? AppTheme.primary
                                                    : Colors.transparent),
                                            width: elegido ? 2.6 : 1.6,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('$n',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: elegido
                                                        ? FontWeight.w900
                                                        : FontWeight.w700,
                                                    color: futuro
                                                        ? Colors.grey.shade500
                                                        : Colors.white)),
                                            if (!futuro && (info?.ventas ?? 0) > 0)
                                              Text('${info!.ventas}',
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white70)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Leyenda(RangosVentas.rojo, rangos.textoRojo),
                        _Leyenda(RangosVentas.amarillo, rangos.textoAmarillo),
                        _Leyenda(RangosVentas.verde, rangos.textoVerde),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configurar rangos',
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: () => configurarRangos(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hoja para cambiar los rangos de color (cantidad o monto).
  static Future<void> configurarRangos(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ConfigRangos(),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _Leyenda(this.color, this.texto);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(texto, style: const TextStyle(fontSize: 11.5)),
        ],
      );
}

class _ConfigRangos extends StatelessWidget {
  const _ConfigRangos();

  @override
  Widget build(BuildContext context) {
    final r = RangosVentas.instancia;
    return ListenableBuilder(
      listenable: r,
      builder: (context, _) {
        Widget paso(String titulo, String valor, VoidCallback menos, VoidCallback mas) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  IconButton.outlined(onPressed: menos, icon: const Icon(Icons.remove)),
                  SizedBox(
                    width: 76,
                    child: Center(
                      child: Text(valor,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  IconButton.outlined(onPressed: mas, icon: const Icon(Icons.add)),
                ],
              ),
            );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RANGOS DEL CALENDARIO',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Por cantidad'), icon: Icon(Icons.tag)),
                      ButtonSegment(value: true, label: Text('Por monto'), icon: Icon(Icons.payments_outlined)),
                    ],
                    selected: {r.porMonto},
                    onSelectionChanged: (s) => r.actualizar(porMonto: s.first),
                  ),
                ),
                const SizedBox(height: 10),
                if (!r.porMonto) ...[
                  paso('Amarillo desde (ventas)', '${r.bajoCantidad}',
                      () => r.actualizar(bajoCantidad: r.bajoCantidad > 1 ? r.bajoCantidad - 1 : 1),
                      () => r.actualizar(bajoCantidad: r.bajoCantidad + 1)),
                  paso('Verde desde (ventas)', '${r.altoCantidad}',
                      () => r.actualizar(altoCantidad: r.altoCantidad - 1),
                      () => r.actualizar(altoCantidad: r.altoCantidad + 1)),
                ] else ...[
                  paso('Amarillo desde (S/)', r.bajoMonto.round().toString(),
                      () => r.actualizar(bajoMonto: r.bajoMonto > 100 ? r.bajoMonto - 100 : 1),
                      () => r.actualizar(bajoMonto: r.bajoMonto + 100)),
                  paso('Verde desde (S/)', r.altoMonto.round().toString(),
                      () => r.actualizar(altoMonto: r.altoMonto - 100),
                      () => r.actualizar(altoMonto: r.altoMonto + 100)),
                ],
                const SizedBox(height: 6),
                Text(
                  'Rojo = sin ventas. Amarillo = ${r.textoAmarillo}. Verde = ${r.textoVerde}.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
