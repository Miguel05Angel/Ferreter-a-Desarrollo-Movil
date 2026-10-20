import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/venta.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/success_dialog.dart';
import '../../widgets/inputs/custom_text_field.dart';

class CotizacionFormScreen extends StatefulWidget {
  const CotizacionFormScreen({super.key});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');

  final List<ItemVenta> _items = [];
  Producto? _productoSeleccionado;
  int _validez = AppConstants.diasValidez.first;
  bool _cargando = false;

  @override
  void dispose() {
    _clienteController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _items.fold(0.0, (suma, i) => suma + i.subtotal);
  double get _igv => _subtotal * AppConstants.igv;

  void _agregarItem() {
    final producto = _productoSeleccionado;
    final cantidad = int.tryParse(_cantidadController.text.trim());
    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona un producto'),
            backgroundColor: Color(0xFFD32F2F)),
      );
      return;
    }
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa una cantidad valida'),
            backgroundColor: Color(0xFFD32F2F)),
      );
      return;
    }
    final existente =
        _items.indexWhere((i) => i.productoId == producto.id);
    if (existente >= 0) {
      final actual = _items[existente];
      _items[existente] = ItemVenta(
        productoId: actual.productoId,
        nombre: actual.nombre,
        cantidad: actual.cantidad + cantidad,
        precioUnitario: actual.precioUnitario,
      );
    } else {
      _items.add(ItemVenta(
        productoId: producto.id,
        nombre: producto.nombre,
        cantidad: cantidad,
        precioUnitario: producto.precioVenta,
      ));
    }
    setState(() {
      _cantidadController.text = '1';
    });
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto a la cotizacion'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final cotizacion = context.read<CotizacionProvider>().registrar(
          clienteNombre: _clienteController.text.trim(),
          items: List.of(_items),
          validezDias: _validez,
        );

    setState(() => _cargando = false);
    if (!mounted) return;

    await SuccessDialog.mostrar(
      context,
      titulo: 'Cotizacion creada',
      mensaje:
          'Cliente: ${cotizacion.clienteNombre}\nTotal: ${Formatters.soles(cotizacion.total)}',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>().productos;
    final clientes = context.watch<ClienteProvider>().clientes;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cotizacion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                etiqueta: 'Cliente',
                icono: Icons.person_outline,
                controlador: _clienteController,
                validador: Validators.nombre,
                ayuda: 'Nombre del cliente o empresa',
                capitalizacion: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: clientes
                    .map(
                      (c) => ActionChip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text(c.nombre,
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(
                            () => _clienteController.text = c.nombre),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Agregar productos',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              DropdownButtonFormField<Producto>(
                initialValue: _productoSeleccionado,
                hint: const Text('Selecciona un producto'),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2_outlined)),
                items: productos
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.nombre} - ${Formatters.soles(p.precioVenta)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _productoSeleccionado = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      etiqueta: 'Cantidad',
                      icono: Icons.numbers,
                      controlador: _cantidadController,
                      tipoTeclado: TextInputType.number,
                      validador: Validators.cantidad,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _agregarItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_items.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: _items
                        .map(
                          (i) => ListTile(
                            dense: true,
                            title: Text(i.nombre,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${i.cantidad} x ${Formatters.soles(i.precioUnitario)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Formatters.soles(i.subtotal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5)),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18,
                                      color: Color(0xFFD32F2F)),
                                  onPressed: () =>
                                      setState(() => _items.remove(i)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Validez de la cotizacion',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.diasValidez
                    .map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$d dias'),
                          selected: _validez == d,
                          onSelected: (_) =>
                              setState(() => _validez = d),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(Formatters.soles(_subtotal)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IGV (18%)'),
                        Text(Formatters.soles(_igv)),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(Formatters.soles(_subtotal + _igv),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              AnimatedButton(
                texto: 'Guardar cotizacion',
                icono: Icons.request_quote_outlined,
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
