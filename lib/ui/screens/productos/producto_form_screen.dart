import 'package:flutter/material.dart';

import '../../../core/utils/formatos.dart';

import '../../../core/permisos.dart';
import '../../widgets/feedback/acceso_restringido.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/producto.dart';
import '../../../providers/producto_provider.dart';

import '../../widgets/feedback/edicion_flow.dart';
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
  late final TextEditingController _stockMin;
  late final TextEditingController _fuente;
  late final TextEditingController _urlFuente;
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
    _stockMin = TextEditingController(text: '${p?.stockMinimo ?? 5}');
    _fuente = TextEditingController(text: p?.fuente ?? '');
    _urlFuente = TextEditingController(text: p?.urlFuente ?? '');
    _categoriaId = p?.categoriaId;
    _unidad = p?.unidad ?? AppConstants.unidades.first;
    for (final x in [
      _codigo,
      _nombre,
      _descripcion,
      _marca,
      _precioVenta,
      _precioCompra,
      _stock,
      _stockMin,
      _fuente,
      _urlFuente
    ]) {
      x.addListener(_alCambiar);
    }
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _marca.dispose();
    _precioVenta.dispose();
    _precioCompra.dispose();
    _stock.dispose();
    _stockMin.dispose();
    _fuente.dispose();
    _urlFuente.dispose();
    super.dispose();
  }

  List<CambioCampo> _cambios() {
    final p = widget.producto;
    if (p == null) return [];
    final k = ComparadorCambios();
    k.texto('Codigo', p.codigo, _codigo.text);
    k.texto('Nombre', p.nombre, _nombre.text);
    k.texto('Descripcion', p.descripcion, _descripcion.text);
    k.texto('Marca', p.marca, _marca.text);
    if (_categoriaId != p.categoriaId && _categoriaId != null) {
      final prov = context.read<ProductoProvider>();
      k.cambios.add(CambioCampo(
        'Categoria',
        prov.categoriaDe(p.categoriaId).nombre,
        prov.categoriaDe(_categoriaId!).nombre,
      ));
    }
    k.texto('Unidad', p.unidad, _unidad);
    k.numero('Precio de venta', p.precioVenta, _precioVenta.text);
    k.numero('Precio de compra', p.precioCompra, _precioCompra.text);
    k.numero('Stock', p.stock, _stock.text, decimales: 0);
    k.numero('Stock minimo', p.stockMinimo, _stockMin.text, decimales: 0);
    k.texto('Fuente del precio', p.fuente, _fuente.text);
    return k.cambios;
  }

  /// Fecha en que se verifico el precio: se conserva si no cambio nada.
  DateTime _fechaVerificacion() {
    final p = widget.producto;
    final precio = double.tryParse(_precioVenta.text.trim());
    if (p != null &&
        p.fechaPrecio != null &&
        p.fuente == _fuente.text.trim() &&
        p.precioVenta == precio) {
      return p.fechaPrecio!;
    }
    return DateTime.now();
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

    if (_esEdicion) {
      final seguro = await EdicionFlow.confirmar(
        context,
        entidad: 'a este producto',
        cambios: _cambios(),
      );
      if (!seguro || !mounted) return;
    }

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final base = Producto(
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
      stockMinimo: int.tryParse(_stockMin.text.trim()) ?? 5,
      fuente: _fuente.text.trim(),
      urlFuente: _urlFuente.text.trim(),
      fechaPrecio:
          _fuente.text.trim().isEmpty ? null : _fechaVerificacion(),
    );
    // Al editar se conservan la ilustracion 3D y los colores del producto
    final nuevo = widget.producto == null
        ? base
        : widget.producto!.copyWith(
            codigo: base.codigo,
            nombre: base.nombre,
            descripcion: base.descripcion,
            categoriaId: base.categoriaId,
            marca: base.marca,
            unidad: base.unidad,
            precioVenta: base.precioVenta,
            precioCompra: base.precioCompra,
            stock: base.stock,
            stockMinimo: base.stockMinimo,
            fuente: base.fuente,
            urlFuente: base.urlFuente,
            fechaPrecio: base.fechaPrecio,
          );

    try {
      if (_esEdicion) {
        await provider.actualizar(nuevo, stockOriginal: widget.producto!.stock);
      } else {
        await provider.agregar(nuevo);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el producto.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _cargando = false);

    await EdicionFlow.exito(
      context,
      titulo: _esEdicion ? 'Producto actualizado' : 'Producto registrado',
      mensaje: _esEdicion
          ? 'Los cambios se guardaron correctamente.'
          : 'Se agrego a tu lista correctamente.',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!Permisos.de(context).puedeGestionarProductos) {
      return const AccesoRestringido(
        titulo: 'Productos',
        detalle:
            'Solo el Administrador puede crear, editar o eliminar productos.',
      );
    }
    final categorias = context.watch<ProductoProvider>().categorias;

    return Scaffold(
      appBar: AppBarTaller(mostrarCarrito: false, 
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
                formateadores: Formatos.codigo(10),
                validador: Validators.codigoProducto,
                ayuda: 'Ej: HER-001',
                capitalizacion: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Nombre del producto',
                icono: Icons.label_outline,
                controlador: _nombre,
                formateadores: Formatos.nombre(60),
                validador: Validators.nombre,
                capitalizacion: TextCapitalization.sentences,
                ayuda: 'Ej: Taladro percutor 750W',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Descripcion',
                icono: Icons.description_outlined,
                controlador: _descripcion,
                formateadores: Formatos.texto(160),
                validador: (v) => Validators.requerido(v, 'Ingresa una descripcion'),
                lineas: 3,
                capitalizacion: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Marca',
                icono: Icons.branding_watermark_outlined,
                controlador: _marca,
                formateadores: Formatos.nombre(30),
                validador: (v) => Validators.requerido(v, 'Ingresa la marca'),
                ayuda: 'Ej: Truper',
              ),
              const SizedBox(height: 20),

              // Categoria
              const _Etiqueta('Categoria'),
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
                        const _Etiqueta('Unidad de medida'),
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
                      formateadores: Formatos.digitos(6),
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
                      formateadores: [Formatos.decimal(enteros: 6)],
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
                      formateadores: [Formatos.decimal(enteros: 6)],
                      tipoTeclado:
                          const TextInputType.numberWithOptions(decimal: true),
                      validador: Validators.precioOpcional,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _Etiqueta('Alerta de stock y origen del precio'),
              const SizedBox(height: 8),
              CustomTextField(
                etiqueta: 'Stock minimo (alerta)',
                icono: Icons.notification_important_outlined,
                controlador: _stockMin,
                formateadores: Formatos.digitos(4),
                tipoTeclado: TextInputType.number,
                ayuda: 'Al llegar a esta cantidad se envia la alerta de reposicion',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Fuente del precio',
                icono: Icons.storefront_outlined,
                controlador: _fuente,
                formateadores: Formatos.texto(60),
                ayuda: 'Tienda donde lo verificaste: Promart, Sodimac, Maestro, local...',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                etiqueta: 'Enlace de la fuente (opcional)',
                icono: Icons.link,
                controlador: _urlFuente,
                formateadores: Formatos.texto(200),
                tipoTeclado: TextInputType.url,
              ),
              const SizedBox(height: 32),
              AccionesFormulario(
                esEdicion: _esEdicion,
                hayCambios: _cambios().isNotEmpty,
                cargando: _cargando,
                textoRegistrar: 'Registrar producto',
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
