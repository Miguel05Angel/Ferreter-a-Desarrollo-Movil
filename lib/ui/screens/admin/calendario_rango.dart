import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_ui.dart';

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

String formatoFecha(DateTime d) => fechaTxt(d);

/// Lee una fecha en formato estricto dd/mm/aaaa. Devuelve null si no existe
/// en el calendario (por ejemplo 31/02/2026).
DateTime? leerFecha(String s) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s.trim());
  if (m == null) return null;
  final dia = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  final anio = int.parse(m.group(3)!);
  final f = DateTime(anio, mes, dia);
  if (f.year != anio || f.month != mes || f.day != dia) return null;
  return f;
}

/// Rango de fechas inclusivo (de las 00:00 del primer día al final del último).
class RangoFechas {
  RangoFechas(DateTime desde, DateTime hasta)
      : desde = soloFecha(desde),
        hasta = soloFecha(hasta);

  final DateTime desde;
  final DateTime hasta;

  bool contiene(DateTime? f) {
    if (f == null) return false;
    final d = soloFecha(f);
    return !d.isBefore(desde) && !d.isAfter(hasta);
  }

  String get texto => desde == hasta
      ? formatoFecha(desde)
      : '${formatoFecha(desde)} – ${formatoFecha(hasta)}';
}

class _ResultadoFechas {
  const _ResultadoFechas(this.rango);

  /// `null` significa "quitar el filtro".
  final RangoFechas? rango;
}

/// Botón de la barra de herramientas que abre el calendario.
class BotonFechas extends StatelessWidget {
  const BotonFechas({super.key, required this.valor, required this.onCambio});

  final RangoFechas? valor;
  final ValueChanged<RangoFechas?> onCambio;

  Future<void> _abrir(BuildContext context) async {
    final r = await dialogo<_ResultadoFechas>(
      context,
      (_) => _DialogoFechas(inicial: valor),
    );
    if (r != null) onCambio(r.rango);
  }

  @override
  Widget build(BuildContext context) {
    final activo = valor != null;
    return Tarjeta(
      onTap: () => _abrir(context),
      elevarAlHover: false,
      radio: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: activo ? Tono.acento : context.tenue,
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              activo ? valor!.texto : 'Todas las fechas',
              key: ValueKey(activo ? valor!.texto : 'todas'),
              style: estiloNum(
                context,
                size: 13.5,
                peso: FontWeight.w700,
                color: activo ? context.tinta : context.tenue,
              ),
            ),
          ),
          if (activo) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onCambio(null),
              child: Icon(Icons.close_rounded, size: 16, color: context.tenue),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inserta las barras mientras se escribe: 17032026 -> 17/03/2026.
class _FormatoFecha extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final d = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    final corto = d.length > 8 ? d.substring(0, 8) : d;
    final buf = StringBuffer();
    for (var i = 0; i < corto.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(corto[i]);
    }
    final t = buf.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _DialogoFechas extends StatefulWidget {
  const _DialogoFechas({this.inicial});

  final RangoFechas? inicial;

  @override
  State<_DialogoFechas> createState() => _DialogoFechasState();
}

class _DialogoFechasState extends State<_DialogoFechas> {
  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _semana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _msgOrden = 'Debe ser igual o posterior a la inicial';

  final DateTime _hoy = soloFecha(DateTime.now());
  final _tDesde = TextEditingController();
  final _tHasta = TextEditingController();

  late DateTime _mes;
  DateTime? _desde;
  DateTime? _hasta;
  String? _eDesde;
  String? _eHasta;

  @override
  void initState() {
    super.initState();
    final r = widget.inicial;
    _desde = r?.desde;
    _hasta = r?.hasta;
    final ref = r?.hasta ?? _hoy;
    _mes = DateTime(ref.year, ref.month);
    _sincronizar();
  }

  @override
  void dispose() {
    _tDesde.dispose();
    _tHasta.dispose();
    super.dispose();
  }

  void _sincronizar() {
    _tDesde.text = _desde == null ? '' : formatoFecha(_desde!);
    _tHasta.text = _hasta == null ? '' : formatoFecha(_hasta!);
    _eDesde = null;
    _eHasta = null;
  }

  void _elegir(DateTime d) {
    setState(() {
      if (_desde == null || _hasta != null) {
        _desde = d;
        _hasta = null;
      } else if (d.isBefore(_desde!)) {
        _hasta = _desde;
        _desde = d;
      } else {
        _hasta = d;
      }
      _sincronizar();
    });
  }

  void _preset(DateTime a, DateTime b) {
    setState(() {
      _desde = a;
      _hasta = b;
      _mes = DateTime(b.year, b.month);
      _sincronizar();
    });
  }

  void _escribir(bool esDesde, String t) {
    String? err;
    DateTime? f;
    if (t.length == 10) {
      f = leerFecha(t);
      if (f == null) {
        err = 'Fecha inválida';
      } else if (f.isAfter(_hoy)) {
        err = 'No puede ser una fecha futura';
        f = null;
      } else if (f.year < 2000) {
        err = 'Año fuera de rango';
        f = null;
      }
    }
    setState(() {
      final completo = t.isEmpty || t.length == 10;
      if (esDesde) {
        _eDesde = err;
        if (completo) _desde = f;
      } else {
        _eHasta = err;
        if (completo) _hasta = f;
      }
      if (_eHasta == _msgOrden) _eHasta = null;
      if (_desde != null && _hasta != null && _desde!.isAfter(_hasta!)) {
        _eHasta ??= _msgOrden;
      }
      if (f != null) _mes = DateTime(f.year, f.month);
    });
  }

  bool _completo(String t) => t.isEmpty || t.length == 10;

  bool get _puedeAplicar =>
      _desde != null &&
      _eDesde == null &&
      _eHasta == null &&
      _completo(_tDesde.text) &&
      _completo(_tHasta.text);

  void _aplicar() {
    final d = _desde!;
    Navigator.of(context).pop(_ResultadoFechas(RangoFechas(d, _hasta ?? d)));
  }

  // ----------------------------- calendario --------------------------------

  Widget _celda(int dia, int dias, int columna) {
    if (dia < 1 || dia > dias) return const SizedBox(height: 40);
    final f = DateTime(_mes.year, _mes.month, dia);
    final futuro = f.isAfter(_hoy);
    final ini = _desde != null && f == _desde;
    final fin = _hasta != null && f == _hasta;
    final dentro = _desde != null &&
        _hasta != null &&
        !f.isBefore(_desde!) &&
        !f.isAfter(_hasta!);
    final extremo = ini || fin;
    final unico = ini && fin;
    final redondoIzq = ini || dia == 1 || columna == 0;
    final redondoDer = fin || dia == dias || columna == 6;

    final tira = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: dentro && !unico ? Tono.acento.withOpacity(0.13) : null,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(redondoIzq ? 20 : 0),
          right: Radius.circular(redondoDer ? 20 : 0),
        ),
      ),
    );

    final circulo = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: extremo ? Tono.acento : Colors.transparent,
        shape: BoxShape.circle,
        border: f == _hoy && !extremo
            ? Border.all(color: Tono.acento, width: 1.4)
            : null,
      ),
      child: Text(
        '$dia',
        style: estiloNum(
          context,
          size: 13,
          peso: extremo ? FontWeight.w800 : FontWeight.w600,
          color: extremo
              ? Colors.white
              : (futuro ? context.tenue.withOpacity(0.4) : context.tinta),
        ),
      ),
    );

    return MouseRegion(
      cursor: futuro ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: futuro ? null : () => _elegir(f),
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [Positioned.fill(child: tira), circulo],
          ),
        ),
      ),
    );
  }

  Widget _grilla() {
    final primero = DateTime(_mes.year, _mes.month, 1);
    final desfase = (primero.weekday + 6) % 7; // lunes = 0
    final dias = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final filas = ((desfase + dias) / 7).ceil();
    return Column(
      key: ValueKey(_mes),
      children: [
        for (var fila = 0; fila < filas; fila++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _celda(fila * 7 + col - desfase + 1, dias, col),
                ),
            ],
          ),
      ],
    );
  }

  Widget _campo(String etiqueta, TextEditingController c, bool esDesde, String? error) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [_FormatoFecha()],
            onChanged: (t) => _escribir(esDesde, t),
            style: estiloNum(context, size: 14, peso: FontWeight.w600),
            decoration: decoCampo(
              context,
              etiqueta,
              Icons.edit_calendar_outlined,
              hint: 'dd/mm/aaaa',
            ).copyWith(
              enabledBorder: error != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Tono.peligro),
                    )
                  : null,
              focusedBorder: error != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Tono.peligro, width: 1.6),
                    )
                  : null,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Tono.peligro,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _preajuste(String t, DateTime a, DateTime b) {
    final activo = _desde == a && _hasta == b;
    return Pildora(texto: t, activo: activo, onTap: () => _preset(a, b));
  }

  @override
  Widget build(BuildContext context) {
    final puedeSiguiente = !DateTime(_mes.year, _mes.month + 1).isAfter(_hoy);
    final ayer = _hoy.subtract(const Duration(days: 1));
    final mesIni = DateTime(_hoy.year, _hoy.month, 1);

    return Dialog(
      backgroundColor: context.panel,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.linea),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar por fecha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: context.tinta,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close_rounded, color: context.tenue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _preajuste('Hoy', _hoy, _hoy),
                  _preajuste('Ayer', ayer, ayer),
                  _preajuste(
                      '7 días', _hoy.subtract(const Duration(days: 6)), _hoy),
                  _preajuste(
                      '30 días', _hoy.subtract(const Duration(days: 29)), _hoy),
                  _preajuste('Este mes', mesIni, _hoy),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mes anterior',
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: context.tinta,
                    onPressed: () => setState(
                      () => _mes = DateTime(_mes.year, _mes.month - 1),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${_meses[_mes.month - 1]} ${_mes.year}',
                        key: ValueKey(_mes),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.tinta,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mes siguiente',
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: context.tinta,
                    onPressed: puedeSiguiente
                        ? () => setState(
                              () => _mes = DateTime(_mes.year, _mes.month + 1),
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final d in _semana)
                    Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: context.tenue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _grilla(),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: context.linea, height: 1),
              const SizedBox(height: 16),
              Text(
                'O escribe las fechas (opcional)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.tenue,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _campo('Desde', _tDesde, true, _eDesde),
                  const SizedBox(width: 12),
                  _campo('Hasta', _tHasta, false, _eHasta),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const _ResultadoFechas(null)),
                    style: TextButton.styleFrom(foregroundColor: context.tenue),
                    child: const Text('Quitar filtro'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _puedeAplicar ? _aplicar : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Tono.acento,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
