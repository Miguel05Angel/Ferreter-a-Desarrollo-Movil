import 'package:flutter/material.dart';

import '../../../core/utils/formatos.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/cliente_provider.dart';
import '../../widgets/feedback/edicion_flow.dart';
import '../../widgets/inputs/custom_text_field.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;
  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _documento;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  late final TextEditingController _email;
  String _tipoDocumento = 'DNI';
  bool _credito = false;
  bool _cargando = false;

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _documento = TextEditingController(text: c?.documento ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _direccion = TextEditingController(text: c?.direccion ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _tipoDocumento = c?.tipoDocumento ?? 'DNI';
    _credito = c?.credito ?? false;
    for (final x in [_nombre, _documento, _telefono, _direccion, _email]) {
      x.addListener(_alCambiar);
    }
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _validarDocumento(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa el numero de documento';
    }
    return _tipoDocumento == 'DNI' ? Validators.dni(valor) : Validators.ruc(valor);
  }

  List<CambioCampo> _cambios() {
    final c = widget.cliente;
    if (c == null) return [];
    final k = ComparadorCambios();
    k.texto('Nombre', c.nombre, _nombre.text);
    k.texto('Tipo de documento', c.tipoDocumento, _tipoDocumento);
    k.texto('Documento', c.documento, _documento.text);
    k.texto('Telefono', c.telefono, _telefono.text);
    k.texto('Direccion', c.direccion, _direccion.text);
    k.texto('Correo', c.email, _email.text);
    k.texto('Venta al credito', c.credito ? 'Si' : 'No', _credito ? 'Si' : 'No');
    return k.cambios;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ClienteProvider>();
    final doc = _documento.text.trim();
    if (provider.existeDocumento(doc, ignorarId: widget.cliente?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un cliente con ese documento'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (_esEdicion) {
      final seguro = await EdicionFlow.confirmar(
        context,
        entidad: 'a este cliente',
        cambios: _cambios(),
      );
      if (!seguro || !mounted) return;
    }

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final cliente = Cliente(
      id: widget.cliente?.id ?? 'c-${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombre.text.trim(),
      tipoDocumento: _tipoDocumento,
      documento: doc,
      telefono: _telefono.text.trim(),
      direccion: _direccion.text.trim(),
      email: _email.text.trim(),
      credito: _credito,
    );

    if (_esEdicion) {
      provider.actualizar(cliente);
    } else {
      provider.agregar(cliente);
    }

    setState(() => _cargando = false);
    if (!mounted) return;

    await EdicionFlow.exito(
      context,
      titulo: _esEdicion ? 'Cliente actualizado' : 'Cliente registrado',
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
          title: Text(_esEdicion ? 'Editar cliente' : 'Nuevo cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                etiqueta: 'Nombre completo o razon social',
                icono: Icons.person_outline,
                controlador: _nombre,
                formateadores: Formatos.nombre(60),
                validador: Validators.nombre,
                capitalizacion: TextCapitalization.words,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tipo de documento',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _tipoDocumento,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined)),
                          items: const [
                            DropdownMenuItem(
                                value: 'DNI', child: Text('DNI (8 digitos)')),
                            DropdownMenuItem(
                                value: 'RUC',
                                child: Text('RUC (11 digitos)')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _tipoDocumento = v ?? 'DNI';
                              _documento.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      etiqueta: 'N. de documento',
                      icono: Icons.pin_outlined,
                      controlador: _documento,
                      formateadores:
                          Formatos.digitos(_tipoDocumento == 'RUC' ? 11 : 8),
                      tipoTeclado: TextInputType.number,
                      validador: _validarDocumento,
                      ayuda: _tipoDocumento == 'DNI'
                          ? '8 digitos'
                          : '11 digitos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CustomTextField(
                etiqueta: 'Telefono',
                icono: Icons.phone_outlined,
                controlador: _telefono,
                formateadores: Formatos.digitos(9),
                tipoTeclado: TextInputType.phone,
                validador: Validators.telefono,
                ayuda: '9 digitos, ej: 987654321',
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
                etiqueta: 'Correo (opcional)',
                icono: Icons.email_outlined,
                controlador: _email,
                formateadores: Formatos.correo(60),
                tipoTeclado: TextInputType.emailAddress,
                validador: (v) => v == null || v.trim().isEmpty
                    ? null
                    : Validators.email(v),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _credito,
                onChanged: (v) => setState(() => _credito = v),
                title: const Text('Venta al credito (fiado)'),
                subtitle: const Text(
                    'Permite registrar deudas pendientes del cliente'),
                secondary: const Icon(Icons.credit_score_outlined),
              ),
              const SizedBox(height: 28),
              AccionesFormulario(
                esEdicion: _esEdicion,
                hayCambios: _cambios().isNotEmpty,
                cargando: _cargando,
                textoRegistrar: 'Registrar cliente',
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
