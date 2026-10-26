import 'package:flutter/material.dart';

import '../../../core/utils/formatos.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/proveedor_provider.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/edicion_flow.dart';
import '../../widgets/inputs/custom_text_field.dart';

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
  late final TextEditingController _coordenadas;
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
    _coordenadas = TextEditingController(
      text: (p?.latitud != null && p?.longitud != null)
          ? '${p!.latitud}, ${p.longitud}'
          : '',
    );
    for (final x in [
      _nombre,
      _ruc,
      _telefono,
      _direccion,
      _productos,
      _coordenadas
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
    _coordenadas.dispose();
    super.dispose();
  }

  /// Convierte "lat, lng" en [lat, lng]; devuelve null si el formato no es valido.
  List<double>? _parseCoordenadas(String t) {
    final partes = t.split(',');
    if (partes.length != 2) return null;
    final lat = double.tryParse(partes[0].trim());
    final lng = double.tryParse(partes[1].trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return [lat, lng];
  }

  List<CambioCampo> _cambios() {
    final p = widget.proveedor;
    if (p == null) return [];
    final k = ComparadorCambios();
    k.texto('Nombre', p.nombre, _nombre.text);
    k.texto('RUC', p.ruc, _ruc.text);
    k.texto('Telefono', p.telefono, _telefono.text);
    k.texto('Direccion', p.direccion, _direccion.text);
    k.texto(
        'Coordenadas',
        (p.latitud != null && p.longitud != null)
            ? '${p.latitud}, ${p.longitud}'
            : '',
        _coordenadas.text);
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

    final coords = _parseCoordenadas(_coordenadas.text);

    final proveedor = Proveedor(
      id: widget.proveedor?.id ??
          'pr-${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombre.text.trim(),
      ruc: ruc,
      telefono: _telefono.text.trim(),
      direccion: _direccion.text.trim(),
      productos: listaProductos,
      latitud: coords?[0],
      longitud: coords?[1],
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
                etiqueta: 'Ubicacion exacta (opcional)',
                icono: Icons.pin_drop_outlined,
                controlador: _coordenadas,
                formateadores: Formatos.texto(40),
                ayuda:
                    'En Google Maps manten pulsado el lugar y copia: -12.0464, -77.0428',
                validador: (v) => (v == null ||
                        v.trim().isEmpty ||
                        _parseCoordenadas(v) != null)
                    ? null
                    : 'Formato: -12.0464, -77.0428',
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
