import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/producto.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/inputs/custom_text_field.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _marca;
  late final TextEditingController _precioVenta;
  late final TextEditingController _precioCompra;
  late final TextEditingController _stock;
  String? _categoriaId;
  String _unidad = AppConstants.unidades.first;
  bool _cargando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _codigo = TextEditingController(text: p?.codigo ?? '');
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _marca = TextEditingController(text: p?.marca ?? '');
    _precioVenta =
        TextEditingController(text: p == null ? '' : '${p.precioVenta}');
    _precioCompra =
        TextEditingController(text: p == null || p.precioCompra == 0
            ? ''
            : '${p.precioCompra}');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _categoriaId = p?.categoriaId;
    _unidad = p?.unidad ?? AppConstants.unidades.first;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _marca.dispose();
    _precioVenta.dispose();
    _precioCompra.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoria'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    final provider = context.read<ProductoProvider>();
    final codigo = _codigo.text.trim();

    if (provider.existeCodigo(codigo, ignorarId: widget.producto?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un producto con ese codigo'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final nuevo = Producto(
      id: widget.producto?.id ??
          'p-${DateTime.now().millisecondsSinceEpoch}',
      codigo: codigo,
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      categoriaId: _categoriaId!,
      marca: _marca.text.trim(),
      unidad: _unidad,
      precioVenta: double.parse(_precioVenta.text.trim()),
      precioCompra: double.tryParse(_precioCompra.text.trim()) ?? 0,
      stock: int.parse(_stock.text.trim()),
    );

    if (_esEdicion) {
      provider.actualizar(nuevo);
    } else {
      provider.agregar(nuevo);
    }

    setState(() => _cargando = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_esEdicion
            ? 'Producto actualizado correctamente'
            : 'Producto registrado correctamente'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<ProductoProvider>().categorias;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                etiqueta: 'Codigo',
                icono: Icons.qr_code,
                controlador: _codigo,
                validador: Validators.codigoProducto,
                ayuda: 'Ej: HER-001',
                capitalizacion: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Nombre del producto',
                icono: Icons.label_outline,
                controlador: _nombre,
                validador: Validators.nombre,
                capitalizacion: TextCapitalization.sentences,
                ayuda: 'Ej: Taladro percutor 750W',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Descripcion',
                icono: Icons.description_outlined,
                controlador: _descripcion,
                validador: (v) => Validators.requerido(v, 'Ingresa una descripcion'),
                lineas: 3,
                capitalizacion: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Marca',
                icono: Icons.branding_watermark_outlined,
                controlador: _marca,
                validador: (v) => Validators.requerido(v, 'Ingresa la marca'),
                ayuda: 'Ej: Truper',
              ),
              const SizedBox(height: 20),

              // Categoria
              _Etiqueta('Categoria'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoriaId,
                hint: const Text('Selecciona una categoria'),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined)),
                items: categorias
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icono, size: 18, color: c.color),
                              const SizedBox(width: 10),
                              Text(c.nombre),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Etiqueta('Unidad de medida'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _unidad,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.straighten)),
                          items: AppConstants.unidades
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _unidad = v ?? _unidad),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      etiqueta: 'Stock',
                      icono: Icons.warehouse_outlined,
                      controlador: _stock,
                      tipoTeclado: TextInputType.number,
                      validador: Validators.stock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      etiqueta: 'Precio de venta (S/)',
                      icono: Icons.sell_outlined,
                      controlador: _precioVenta,
                      tipoTeclado:
                          const TextInputType.numberWithOptions(decimal: true),
                      validador: Validators.precio,
                      ayuda: 'Ej: 25.50',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      etiqueta: 'Precio de compra (opc.)',
                      icono: Icons.shopping_bag_outlined,
                      controlador: _precioCompra,
                      tipoTeclado:
                          const TextInputType.numberWithOptions(decimal: true),
                      validador: Validators.precioOpcional,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                texto: _esEdicion ? 'Guardar cambios' : 'Registrar producto',
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

class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Text(
      texto,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: esOscuro ? Colors.grey.shade300 : Colors.grey.shade800,
      ),
    );
  }
}
