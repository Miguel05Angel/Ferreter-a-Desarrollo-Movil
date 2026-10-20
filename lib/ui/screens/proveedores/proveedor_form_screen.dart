import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/proveedor_provider.dart';
import '../../widgets/buttons/animated_button.dart';
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
  }

  @override
  void dispose() {
    _nombre.dispose();
    _ruc.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _productos.dispose();
    super.dispose();
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
      productos: listaProductos,
    );

    if (_esEdicion) {
      provider.actualizar(proveedor);
    } else {
      provider.agregar(proveedor);
    }

    setState(() => _cargando = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_esEdicion
            ? 'Proveedor actualizado correctamente'
            : 'Proveedor registrado correctamente'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                validador: Validators.nombre,
                capitalizacion: TextCapitalization.words,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'RUC',
                icono: Icons.badge_outlined,
                controlador: _ruc,
                tipoTeclado: TextInputType.number,
                validador: Validators.ruc,
                ayuda: '11 digitos',
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Telefono',
                icono: Icons.phone_outlined,
                controlador: _telefono,
                tipoTeclado: TextInputType.phone,
                validador: Validators.telefono,
                ayuda: '9 digitos',
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Direccion',
                icono: Icons.location_on_outlined,
                controlador: _direccion,
                validador: Validators.direccion,
                capitalizacion: TextCapitalization.sentences,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Productos que ofrece',
                icono: Icons.inventory_2_outlined,
                controlador: _productos,
                ayuda: 'Separados por comas, ej: Cemento, Fierro',
                lineas: 2,
              ),
              const SizedBox(height: 30),
              AnimatedButton(
                texto:
                    _esEdicion ? 'Guardar cambios' : 'Registrar proveedor',
                icono: Icons.save_outlined,
                cargando: _cargando,
                onPressed: _guardar,
                ancho: double.infinity,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
