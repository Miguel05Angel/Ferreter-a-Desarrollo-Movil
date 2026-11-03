import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/solicitud_cotizacion.dart';
import '../../../providers/compra_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/feedback/edicion_flow.dart';
import '../../widgets/layout/appbar_taller.dart';

/// Registro de la cotizacion que devolvio el proveedor: precio unitario,
/// impuestos, envio y fecha de validez. Con estos datos se genera despues la
/// orden de compra definitiva.
class RegistrarCotizacionScreen extends StatefulWidget {
  final String solicitudId;

  const RegistrarCotizacionScreen({super.key, required this.solicitudId});

  @override
  State<RegistrarCotizacionScreen> createState() =>
      _RegistrarCotizacionScreenState();
}

class _RegistrarCotizacionScreenState extends State<RegistrarCotizacionScreen> {
  static const _condiciones = [
    'Contado',
    'Credito 15 dias',
    'Credito 30 dias',
    'Credito 45 dias',
    '50% adelanto y saldo contra entrega',
  ];

  late final ThemeData _tema = AppTheme.dark;
  final _formKey = GlobalKey<FormState>();
  final _precio = TextEditingController();
  final _envio = TextEditingController(text: '0');
  final _plazo = TextEditingController(text: '3');
  final _observaciones = TextEditingController();
  bool _incluyeIgv = false;
  String _pago = _condiciones.first;
  DateTime _validaHasta = DateTime.now().add(const Duration(days: 7));
  bool _cargando = false;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_precio, _envio]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _precio.dispose();
    _envio.dispose();
    _plazo.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  double get _precioNum =>
      double.tryParse(_precio.text.replaceAll(',', '.')) ?? 0;
  double get _envioNum => double.tryParse(_envio.text.replaceAll(',', '.')) ?? 0;

  CotizacionProveedor _armar() => CotizacionProveedor(
        precioUnitario: _precioNum,
        incluyeIgv: _incluyeIgv,
        envio: _envioNum,
        validaHasta: _validaHasta,
        plazoEntregaDias: int.tryParse(_plazo.text) ?? 0,
        condicionesPago: _pago,
        observaciones: _observaciones.text.trim(),
        fechaRegistro: DateTime.now(),
      );

  Future<void> _fecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _validaHasta.isBefore(DateTime.now())
          ? DateTime.now()
          : _validaHasta,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'OFERTA VALIDA HASTA',
    );
    if (f != null) setState(() => _validaHasta = f);
  }

  Future<void> _guardar(SolicitudCotizacion s) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.read<CompraProvider>().registrarCotizacion(s.id, _armar());
    setState(() => _cargando = false);
    await EdicionFlow.exito(
      context,
      titulo: 'Cotizacion registrada',
      mensaje: 'Ya puedes revisar los totales y generar la orden de compra.',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  InputDecoration _deco(String etiqueta, {String? prefijo, String? ayuda}) =>
      InputDecoration(
        labelText: etiqueta,
        prefixText: prefijo,
        helperText: ayuda,
        labelStyle: const TextStyle(
            fontFamily: 'monospace', fontSize: 12.5, letterSpacing: 1),
      );

  @override
  Widget build(BuildContext context) {
    if (!Permisos.de(context).puedeSolicitarReposicion) {
      return const AccesoRestringido(
        titulo: 'Compras',
        detalle: 'Las compras a proveedores son solo para el Administrador.',
      );
    }
    final s = context.watch<CompraProvider>().buscar(widget.solicitudId);
    if (s == null) {
      return const Scaffold(body: Center(child: Text('Solicitud no encontrada')));
    }

    // Si ya habia una cotizacion se precargan sus datos (correccion)
    if (!_inicializado && s.cotizacion != null) {
      final c = s.cotizacion!;
      _precio.text = c.precioUnitario.toStringAsFixed(2);
      _envio.text = c.envio.toStringAsFixed(2);
      _plazo.text = '${c.plazoEntregaDias}';
      _observaciones.text = c.observaciones;
      _incluyeIgv = c.incluyeIgv;
      _pago = c.condicionesPago;
      _validaHasta = c.validaHasta;
    }
    _inicializado = true;

    final previa = _precioNum > 0 ? _armar() : null;

    return Theme(
      data: _tema,
      child: Scaffold(
        appBar: AppBarTaller(
          mostrarCarrito: false,
          subtitulo: s.numero,
          title: const Text('Cotizacion del proveedor'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
            children: [
              FadeSlide(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.superficieOscura,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.bordeOscuro),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.descripcion,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.hueso)),
                            Text(
                              '${s.cantidad} ${s.unidad.toUpperCase()}  -  ${s.proveedorNombre}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                color: Color(0x99EDE8DF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _precio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [Formatos.decimal(enteros: 6)],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                decoration: _deco('PRECIO UNITARIO COTIZADO',
                    prefijo: 'S/  ',
                    ayuda: 'Por ${s.unidad.toLowerCase()}, tal como lo indico el proveedor'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Ingresa el precio unitario';
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('El precio incluye IGV',
                    style: TextStyle(color: AppTheme.hueso)),
                subtitle: const Text(
                  'Si lo apagas, el IGV (18%) se suma al precio.',
                  style: TextStyle(fontSize: 11.5, color: Color(0x99EDE8DF)),
                ),
                value: _incluyeIgv,
                onChanged: (v) => setState(() => _incluyeIgv = v),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _envio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [Formatos.decimal(enteros: 5)],
                decoration: _deco('GASTOS DE ENVIO / FLETE', prefijo: 'S/  '),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _plazo,
                      keyboardType: TextInputType.number,
                      inputFormatters: Formatos.digitos(3),
                      decoration: _deco('PLAZO (DIAS)'),
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Indica los dias'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _fecha,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _deco('VALIDA HASTA'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_validaHasta.day.toString().padLeft(2, '0')}/${_validaHasta.month.toString().padLeft(2, '0')}/${_validaHasta.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Icon(Icons.event_outlined, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _pago,
                isExpanded: true,
                decoration: _deco('CONDICIONES DE PAGO'),
                items: [
                  for (final c in _condiciones)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _pago = v ?? _pago),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observaciones,
                maxLines: 2,
                inputFormatters: Formatos.texto(160),
                decoration: _deco('OBSERVACIONES (OPCIONAL)'),
              ),

              // ----------------------------------------- totales en vivo
              const SizedBox(height: 22),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: previa == null
                    ? const SizedBox(width: double.infinity)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: AppTheme.grafito,
                          shape: BeveledRectangleBorder(
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(20)),
                            side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.6)),
                          ),
                        ),
                        child: Column(
                          children: [
                            _Fila('Subtotal',
                                Formatters.soles(previa.subtotal(s.cantidad))),
                            _Fila('IGV (18%)',
                                Formatters.soles(previa.igv(s.cantidad))),
                            _Fila('Envio', Formatters.soles(previa.envio)),
                            const Divider(color: AppTheme.bordeOscuro),
                            _Fila('Total de la orden',
                                Formatters.soles(previa.total(s.cantidad)),
                                grande: true),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 22),
              AnimatedButton(
                texto: 'Guardar cotizacion',
                icono: Icons.save_outlined,
                ancho: double.infinity,
                cargando: _cargando,
                onPressed: () => _guardar(s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String e;
  final String v;
  final bool grande;

  const _Fila(this.e, this.v, {this.grande = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            e.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: grande ? 12.5 : 11,
              letterSpacing: 1.2,
              color: grande ? AppTheme.hueso : const Color(0x99EDE8DF),
              fontWeight: grande ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: grande ? 24 : 14.5,
              fontWeight: FontWeight.w900,
              color: grande ? AppTheme.primary : AppTheme.hueso,
            ),
          ),
        ],
      ),
    );
  }
}
