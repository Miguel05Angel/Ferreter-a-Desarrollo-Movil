import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/venta.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../../services/exportador_ventas.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/ventas/calendario_termico.dart';
import '../../widgets/ventas/graficos_ventas.dart';
import '../../widgets/visual/tilt_3d.dart';
import 'venta_detalle_screen.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  String _filtro = 'Todas';
  late DateTime _dia = _soloDia(DateTime.now());
  late DateTime _mes = DateTime(_dia.year, _dia.month);
  String _periodo = 'Dia';
  bool _calAbierto = false;
  bool _barras = true;
  String _dona = 'Metodo de pago';
  bool _exportando = false;

  static const _diasCorto = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  static const _mesesCorto = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const _paleta = [
    AppTheme.primary,
    Color(0xFF0277BD),
    AppTheme.success,
    Color(0xFF8E24AA),
    Color(0xFFF9A825),
    Color(0xFF546E7A),
    Color(0xFFD81B60),
  ];

  static DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);
  String _corta(DateTime d) => '${d.day} ${_mesesCorto[d.month - 1]} ${d.year}';

  String get _etiquetaFecha {
    final hoy = _soloDia(DateTime.now());
    if (_dia == hoy) return 'HOY';
    if (_dia == hoy.subtract(const Duration(days: 1))) return 'AYER';
    return _corta(_dia).toUpperCase();
  }

  ({DateTime desde, DateTime hasta}) get _rango {
    switch (_periodo) {
      case 'Semana':
        final lunes = _dia.subtract(Duration(days: _dia.weekday - 1));
        return (desde: lunes, hasta: lunes.add(const Duration(days: 6)));
      case 'Mes':
        return (
          desde: DateTime(_dia.year, _dia.month, 1),
          hasta: DateTime(_dia.year, _dia.month + 1, 0),
        );
      default:
        return (desde: _dia, hasta: _dia);
    }
  }

  String get _textoRango {
    final r = _rango;
    switch (_periodo) {
      case 'Semana':
        return 'Semana del ${_corta(r.desde)} al ${_corta(r.hasta)}';
      case 'Mes':
        return 'Mes de ${_mesesCorto[_dia.month - 1]} ${_dia.year}';
      default:
        return _etiquetaFecha == 'HOY' ? 'Hoy, ${_corta(_dia)}' : _corta(_dia);
    }
  }

  List<Venta> _enRango(List<Venta> l) {
    final r = _rango;
    return l.where((v) {
      final d = _soloDia(v.fecha);
      return !d.isBefore(r.desde) && !d.isAfter(r.hasta);
    }).toList();
  }

  String _categoria(ProductoProvider p, String productoId) {
    for (final x in p.productos) {
      if (x.id == productoId) return p.categoriaDe(x.categoriaId).nombre;
    }
    return 'Otros';
  }

  ({List<String> et, List<double> val, List<int> cant}) _datosBarras(List<Venta> l) {
    final r = _rango;
    late List<String> et;
    late int n;
    switch (_periodo) {
      case 'Semana':
        n = 7;
        et = _diasCorto;
        break;
      case 'Mes':
        n = r.hasta.day;
        et = [for (var i = 1; i <= n; i++) '$i'];
        break;
      default:
        n = 15; // 7h a 21h
        et = [for (var h = 7; h <= 21; h++) '${h}h'];
    }
    final val = List<double>.filled(n, 0);
    final cant = List<int>.filled(n, 0);
    for (final v in l) {
      int i;
      switch (_periodo) {
        case 'Semana':
          i = v.fecha.weekday - 1;
          break;
        case 'Mes':
          i = v.fecha.day - 1;
          break;
        default:
          i = (v.fecha.hour.clamp(7, 21)) - 7;
      }
      val[i] += v.total;
      cant[i] += 1;
    }
    return (et: et, val: val, cant: cant);
  }

  List<SegmentoDona> _segmentos(List<Venta> l, ProductoProvider productos) {
    final mapa = <String, double>{};
    if (_dona == 'Categoria') {
      for (final v in l) {
        for (final i in v.items) {
          final c = _categoria(productos, i.productoId);
          mapa[c] = (mapa[c] ?? 0) + i.subtotal;
        }
      }
    } else {
      for (final v in l) {
        mapa[v.metodoPago] = (mapa[v.metodoPago] ?? 0) + v.total;
      }
    }
    final orden = mapa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < orden.length; i++)
        SegmentoDona(orden[i].key, orden[i].value, _paleta[i % _paleta.length]),
    ];
  }

  Future<void> _exportar(List<Venta> propias) async {
    final enRango = _enRango(propias);
    final eleccion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EXPORTAR A EXCEL',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Incluye resumen, ventas, detalle por producto y analisis por '
                'dia, metodo de pago y categoria.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.table_view_outlined, color: AppTheme.success),
                title: Text('Todas las ventas (${propias.length})'),
                subtitle: const Text('Todo el historial registrado'),
                onTap: () => Navigator.of(ctx).pop('todas'),
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined, color: AppTheme.primary),
                title: Text('Solo el periodo seleccionado (${enRango.length})'),
                subtitle: Text(_textoRango),
                onTap: () => Navigator.of(ctx).pop('periodo'),
              ),
            ],
          ),
        ),
      ),
    );
    if (eleccion == null || !mounted) return;

    final productos = context.read<ProductoProvider>();
    setState(() => _exportando = true);
    try {
      await ExportadorVentas.compartirExcel(
        ventas: eleccion == 'todas' ? propias : enRango,
        categoriaDe: (id) => _categoria(productos, id),
        etiquetaPeriodo: eleccion == 'todas' ? 'Todas las ventas' : _textoRango,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('No se pudo generar el Excel. Intenta de nuevo.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentaProvider>();
    final productos = context.watch<ProductoProvider>();
    final permisos = Permisos.de(context);
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final propias = provider.visiblesPara(
        esAdmin: permisos.esAdmin, usuarioId: usuario?.id ?? '');

    final enRango = _enRango(propias);
    final totalRango = enRango.fold(0.0, (s, v) => s + v.total);
    final filtros = ['Todas', ...AppConstants.metodosPago];
    final lista = _filtro == 'Todas'
        ? enRango
        : enRango.where((v) => v.metodoPago == _filtro).toList();

    // Datos del calendario termico (por dia).
    final datos = <DateTime, DiaVentas>{};
    for (final v in propias) {
      final d = _soloDia(v.fecha);
      final a = datos[d];
      datos[d] = DiaVentas((a?.ventas ?? 0) + 1, (a?.total ?? 0) + v.total);
    }

    final barras = _datosBarras(enRango);
    final tituloBarras = _periodo == 'Dia'
        ? 'VENTAS POR HORA'
        : (_periodo == 'Semana' ? 'VENTAS POR DIA DE LA SEMANA' : 'VENTAS POR DIA DEL MES');

    return Scaffold(
      appBar: const AppBarTaller(subtitulo: 'Caja', title: Text('Ventas')),
      body: provider.error
          ? const Center(child: Text('No se pudo cargar el historial de Firestore.'))
          : propias.isEmpty
          ? const EmptyState(
              icono: Icons.receipt_long_outlined,
              titulo: 'Sin ventas registradas',
              mensaje: 'Las ventas que registres desde el carrito apareceran aqui.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // ------------------------------------------ fecha + exportar
                FadeSlide(
                  child: Row(
                    children: [
                      Expanded(
                        child: _BotonFecha(
                          etiqueta: _etiquetaFecha,
                          abierto: _calAbierto,
                          onTap: () => setState(() => _calAbierto = !_calAbierto),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _exportando ? null : () => _exportar(propias),
                          icon: _exportando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.file_download_outlined),
                          label: const Text('EXCEL'),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _calAbierto
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: CalendarioTermico(
                            mes: _mes,
                            seleccionado: _dia,
                            datos: datos,
                            onMes: (m) => setState(() => _mes = DateTime(m.year, m.month)),
                            onDia: (d) => setState(() {
                              _dia = d;
                              _mes = DateTime(d.year, d.month);
                              _calAbierto = false;
                            }),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),

                // ------------------------------------------ periodo
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Dia', label: Text('Dia'), icon: Icon(Icons.today_outlined)),
                      ButtonSegment(value: 'Semana', label: Text('Semana'), icon: Icon(Icons.view_week_outlined)),
                      ButtonSegment(value: 'Mes', label: Text('Mes'), icon: Icon(Icons.calendar_view_month_outlined)),
                    ],
                    selected: {_periodo},
                    onSelectionChanged: (s) => setState(() => _periodo = s.first),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _textoRango.toUpperCase(),
                    key: ValueKey(_textoRango),
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 10),

                // ------------------------------------------ indicadores
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          titulo: 'Ventas',
                          valor: enRango.length.toDouble(),
                          icono: Icons.receipt_long_outlined,
                          color: const Color(0xFF0277BD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          titulo: 'Total',
                          valor: totalRango,
                          prefijo: 'S/ ',
                          esMoneda: true,
                          icono: Icons.payments_outlined,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  enRango.isEmpty
                      ? 'Sin ventas en este periodo'
                      : 'Ticket promedio ${Formatters.soles(totalRango / enRango.length)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),

                // ------------------------------------------ graficos
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.bordeOscuro
                            : AppTheme.bordeClaro),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _barras ? tituloBarras : 'DISTRIBUCION',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: true, icon: Icon(Icons.bar_chart), tooltip: 'Barras'),
                              ButtonSegment(value: false, icon: Icon(Icons.donut_large), tooltip: 'Dona'),
                            ],
                            selected: {_barras},
                            onSelectionChanged: (s) => setState(() => _barras = s.first),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _barras
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final o in const ['Metodo de pago', 'Categoria'])
                                      ChoiceChip(
                                        label: Text(o),
                                        selected: _dona == o,
                                        onSelected: (_) => setState(() => _dona = o),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (w, a) => FadeTransition(
                          opacity: a,
                          child: ScaleTransition(
                              scale: Tween(begin: 0.94, end: 1.0).animate(a), child: w),
                        ),
                        child: _barras
                            ? GraficoBarras(
                                key: ValueKey('barras-$_periodo'),
                                etiquetas: barras.et,
                                valores: barras.val,
                                cantidades: barras.cant,
                              )
                            : GraficoDona(
                                key: ValueKey('dona-$_dona'),
                                segmentos: _segmentos(enRango, productos),
                                centroTitulo: _dona == 'Categoria' ? 'POR CATEGORIA' : 'TOTAL',
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ------------------------------------------ historial
                const Text('HISTORIAL DEL PERIODO',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filtros.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _ChipFiltro(
                      texto: filtros[i],
                      activo: filtros[i] == _filtro,
                      onTap: () => setState(() => _filtro = filtros[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (lista.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                          _filtro == 'Todas'
                              ? 'No hay ventas en este periodo'
                              : 'Sin ventas con $_filtro en este periodo',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ...lista.asMap().entries.map(
                        (e) => FadeSlide(
                          key: ValueKey('${_filtro}_${_periodo}_${_dia}_${e.value.id}'),
                          delay: Duration(milliseconds: e.key < 8 ? e.key * 70 : 0),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _Ticket(
                              venta: e.value,
                              mostrarVendedor: permisos.esAdmin,
                              onTap: () => AppRoutes.push(
                                context,
                                VentaDetalleScreen(ventaId: e.value.id),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  final String etiqueta;
  final bool abierto;
  final VoidCallback onTap;
  const _BotonFecha({required this.etiqueta, required this.abierto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.grafito,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (w, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                      child: w,
                    ),
                  ),
                  child: Align(
                    key: ValueKey(etiqueta),
                    alignment: Alignment.centerLeft,
                    child: Text(etiqueta,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: abierto ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? AppTheme.grafito : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo
                ? AppTheme.grafito
                : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
        ),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: activo
                ? AppTheme.primary
                : (oscuro ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

/// Venta presentada como un ticket de caja: datos a la izquierda, linea
/// punteada de corte y total a la derecha.
class _Ticket extends StatelessWidget {
  final Venta venta;
  final bool mostrarVendedor;
  final VoidCallback onTap;

  const _Ticket({
    required this.venta,
    required this.onTap,
    this.mostrarVendedor = false,
  });

  IconData _iconoPago(String metodo) {
    switch (metodo) {
      case 'Yape':
        return Icons.phone_iphone;
      case 'Plin':
        return Icons.smartphone;
      case 'Tarjeta':
        return Icons.credit_card;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final acento = venta.comprobante == 'Factura'
        ? const Color(0xFF0277BD)
        : AppTheme.success;

    return Tilt3D(
      anguloMax: 0.07,
      radioBorde: 14,
      builder: (context, t) => Card(
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: acento),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: acento.withValues(alpha: 0.14),
                            shape: BeveledRectangleBorder(
                              borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(14)),
                              side: BorderSide(color: acento.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: Text(
                            venta.clienteNombre.isEmpty
                                ? '?'
                                : venta.clienteNombre[0].toUpperCase(),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: acento),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venta.clienteNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${venta.numero}  -  ${venta.comprobante.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: acento,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.fecha(venta.fecha),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (mostrarVendedor && venta.vendedor.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'VENDEDOR  ${venta.vendedor.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 2,
                  child: CustomPaint(
                    painter: _CortePainter(
                      oscuro ? AppTheme.bordeOscuro : const Color(0xFFC9C2B5),
                    ),
                  ),
                ),
                Container(
                  width: 112,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.soles(venta.total),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconoPago(venta.metodoPago),
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            venta.metodoPago.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CortePainter extends CustomPainter {
  final Color color;

  _CortePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    const trazo = 5.0;
    const hueco = 4.0;
    for (var y = 6.0; y < size.height - 6; y += trazo + hueco) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, math.min(y + trazo, size.height - 6)), p);
    }
  }

  @override
  bool shouldRepaint(_CortePainter old) => old.color != color;
}
