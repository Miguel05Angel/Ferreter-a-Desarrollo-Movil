import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/formatos.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/proveedor_provider.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/edicion_flow.dart';
import '../../widgets/inputs/custom_text_field.dart';
import 'selector_ubicacion_screen.dart';

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _ruc;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  late final TextEditingController _productos;
  late final TextEditingController _referencia;
  LatLng? _ubicacion;
  bool _cargando = false;

  bool get _esEdicion => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _ruc = TextEditingController(text: p?.ruc ?? '');
    _telefono = TextEditingController(text: p?.telefono ?? '');
    _direccion = TextEditingController(text: p?.direccion ?? '');
    _productos = TextEditingController(text: p?.productos.join(', ') ?? '');
    _referencia = TextEditingController(text: p?.referencia ?? '');
    if (p?.latitud != null && p?.longitud != null) {
      _ubicacion = LatLng(p!.latitud!, p.longitud!);
    }
    for (final x in [
      _nombre,
      _ruc,
      _telefono,
      _direccion,
      _referencia,
      _productos,
    ]) {
      x.addListener(_alCambiar);
    }
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _nombre.dispose();
    _ruc.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _productos.dispose();
    _referencia.dispose();
    super.dispose();
  }

  String _txtUbicacion(double? lat, double? lng) => (lat != null && lng != null)
      ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
      : '';

  Future<void> _anadirUbicacion() async {
    final r = await AppRoutes.push<LatLng>(
      context,
      SelectorUbicacionScreen(
        inicial: _ubicacion,
        direccion: _direccion.text.trim(),
        nombre: _nombre.text.trim().isEmpty ? 'Proveedor' : _nombre.text.trim(),
      ),
    );
    if (r != null && mounted) setState(() => _ubicacion = r);
  }

  List<CambioCampo> _cambios() {
    final p = widget.proveedor;
    if (p == null) return [];
    final k = ComparadorCambios();
    k.texto('Nombre', p.nombre, _nombre.text);
    k.texto('RUC', p.ruc, _ruc.text);
    k.texto('Telefono', p.telefono, _telefono.text);
    k.texto('Direccion', p.direccion, _direccion.text);
    k.texto('Referencia', p.referencia, _referencia.text);
    k.texto('Ubicacion exacta', _txtUbicacion(p.latitud, p.longitud),
        _txtUbicacion(_ubicacion?.latitude, _ubicacion?.longitude));
    String norm(String v) => v
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    k.texto('Productos que provee', norm(p.productos.join(', ')),
        norm(_productos.text));
    return k.cambios;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProveedorProvider>();
    final ruc = _ruc.text.trim();
    if (provider.existeRuc(ruc, ignorarId: widget.proveedor?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un proveedor con ese RUC'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (_esEdicion) {
      final seguro = await EdicionFlow.confirmar(
        context,
        entidad: 'a este proveedor',
        cambios: _cambios(),
      );
      if (!seguro || !mounted) return;
    }

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final listaProductos = _productos.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final proveedor = Proveedor(
      id: widget.proveedor?.id ??
          'pr-${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombre.text.trim(),
      ruc: ruc,
      telefono: _telefono.text.trim(),
      direccion: _direccion.text.trim(),
      referencia: _referencia.text.trim(),
      productos: listaProductos,
      latitud: _ubicacion?.latitude,
      longitud: _ubicacion?.longitude,
    );

    if (_esEdicion) {
      provider.actualizar(proveedor);
    } else {
      provider.agregar(proveedor);
    }

    setState(() => _cargando = false);
    if (!mounted) return;

    await EdicionFlow.exito(
      context,
      titulo: _esEdicion ? 'Proveedor actualizado' : 'Proveedor registrado',
      mensaje: _esEdicion
          ? 'Los cambios se guardaron correctamente.'
          : 'Se agrego a tu lista correctamente.',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarTaller(mostrarCarrito: false, 
          title: Text(_esEdicion ? 'Editar proveedor' : 'Nuevo proveedor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                etiqueta: 'Razon social',
                icono: Icons.business_outlined,
                controlador: _nombre,
                formateadores: Formatos.nombre(60),
                validador: Validators.nombre,
                capitalizacion: TextCapitalization.words,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'RUC',
                icono: Icons.badge_outlined,
                controlador: _ruc,
                formateadores: Formatos.digitos(11),
                tipoTeclado: TextInputType.number,
                validador: Validators.ruc,
                ayuda: '11 digitos',
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Telefono',
                icono: Icons.phone_outlined,
                controlador: _telefono,
                formateadores: Formatos.digitos(9),
                tipoTeclado: TextInputType.phone,
                validador: Validators.telefono,
                ayuda: '9 digitos',
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Direccion',
                icono: Icons.location_on_outlined,
                controlador: _direccion,
                formateadores: Formatos.texto(100),
                validador: Validators.direccion,
                capitalizacion: TextCapitalization.sentences,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Referencia (opcional)',
                icono: Icons.flag_outlined,
                controlador: _referencia,
                formateadores: Formatos.texto(100),
                ayuda: 'Ej: a la espalda del parque, porton azul',
                capitalizacion: TextCapitalization.sentences,
              ),
              const SizedBox(height: 18),
              _BotonUbicacion(
                ubicacion: _ubicacion,
                onTap: _anadirUbicacion,
                onQuitar: () => setState(() => _ubicacion = null),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Productos que ofrece',
                icono: Icons.inventory_2_outlined,
                controlador: _productos,
                formateadores: Formatos.texto(150),
                ayuda: 'Separados por comas, ej: Cemento, Fierro',
                lineas: 2,
              ),
              const SizedBox(height: 30),
              AccionesFormulario(
                esEdicion: _esEdicion,
                hayCambios: _cambios().isNotEmpty,
                cargando: _cargando,
                textoRegistrar: 'Registrar proveedor',
                onGuardar: _guardar,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}


/// Boton "Anadir ubicacion exacta": abre el mapa dentro de la app.
class _BotonUbicacion extends StatelessWidget {
  final LatLng? ubicacion;
  final VoidCallback onTap;
  final VoidCallback onQuitar;

  const _BotonUbicacion({
    required this.ubicacion,
    required this.onTap,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final hay = ubicacion != null;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final color = hay ? AppTheme.success : AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(hay ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined),
            label: Text(hay ? 'CAMBIAR UBICACION EXACTA' : 'ANADIR UBICACION EXACTA'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: color, width: 1.8),
              foregroundColor:
                  hay ? color : (oscuro ? AppTheme.primary : const Color(0xFFD95800)),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: hay
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: AppTheme.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ubicacion fijada: ${ubicacion!.latitude.toStringAsFixed(5)}, ${ubicacion!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Colors.grey.shade600),
                        ),
                      ),
                      TextButton(
                          onPressed: onQuitar, child: const Text('Quitar')),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
