import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/layout/appbar_taller.dart';

/// Mapa dentro de la app para fijar la ubicacion exacta de un proveedor.
/// Se arrastra el pin (o se toca el mapa) hasta el lugar correcto y se
/// confirma con "Fijar ubicacion". Devuelve un [LatLng].
class SelectorUbicacionScreen extends StatefulWidget {
  final LatLng? inicial;

  /// Direccion escrita: se usa para ubicar el mapa si aun no hay coordenadas.
  final String direccion;
  final String nombre;

  const SelectorUbicacionScreen({
    super.key,
    this.inicial,
    this.direccion = '',
    this.nombre = 'Proveedor',
  });

  @override
  State<SelectorUbicacionScreen> createState() =>
      _SelectorUbicacionScreenState();
}

class _SelectorUbicacionScreenState extends State<SelectorUbicacionScreen>
    with SingleTickerProviderStateMixin {
  static const _respaldo =
      LatLng(AppConstants.latitudFerreteria, AppConstants.longitudFerreteria);

  GoogleMapController? _mapa;
  LatLng? _punto;
  BitmapDescriptor? _icono;
  bool _buscando = false;
  bool _iconoCargado = false;

  late final AnimationController _flecha = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _punto = widget.inicial;
    if (_punto == null && widget.direccion.trim().isNotEmpty) {
      _ubicarPorDireccion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iconoCargado) return;
    _iconoCargado = true;
    _crearIcono(MediaQuery.of(context).devicePixelRatio).then((i) {
      if (mounted) setState(() => _icono = i);
    });
  }

  @override
  void dispose() {
    _flecha.dispose();
    _mapa?.dispose();
    super.dispose();
  }

  /// Pin azul con el camion del proveedor, dibujado en codigo.
  Future<BitmapDescriptor> _crearIcono(double dpr) async {
    const w = 64.0, h = 78.0, r = 26.0;
    const color = Color(0xFF0277BD);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    const cx = w / 2, cy = r + 4;
    final pin = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r)),
      Path()
        ..moveTo(cx - 15, cy + r - 8)
        ..lineTo(cx, h - 4)
        ..lineTo(cx + 15, cy + r - 8)
        ..close(),
    );
    c.drawShadow(pin, Colors.black, 4, true);
    c.drawPath(pin, Paint()..color = color);
    c.drawPath(
        pin,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawCircle(const Offset(cx, cy), 19, Paint()..color = Colors.white);
    const icono = Icons.local_shipping;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
            fontSize: 26,
            fontFamily: icono.fontFamily,
            package: icono.fontPackage,
            color: color),
      ),
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
    final img =
        await rec.endRecording().toImage((w * dpr).ceil(), (h * dpr).ceil());
    final datos = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(datos!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  Future<void> _ubicarPorDireccion() async {
    setState(() => _buscando = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '${widget.direccion}, Peru',
        'format': 'json',
        'limit': '1',
        'countrycodes': 'pe',
      });
      final r = await http.get(uri, headers: {
        'User-Agent': 'FerreteriaElConstructor/1.0',
        'Accept-Language': 'es',
      }).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final lista = jsonDecode(utf8.decode(r.bodyBytes)) as List;
        if (lista.isNotEmpty) {
          final m = lista.first as Map<String, dynamic>;
          final p = LatLng(double.parse('${m['lat']}'), double.parse('${m['lon']}'));
          if (mounted) {
            setState(() => _punto = p);
            _mapa?.animateCamera(CameraUpdate.newLatLngZoom(p, 17));
          }
        }
      }
    } catch (_) {
      // se queda en la posicion por defecto
    }
    if (mounted) setState(() => _buscando = false);
  }

  void _mover(LatLng p) => setState(() => _punto = p);

  @override
  Widget build(BuildContext context) {
    final centro = _punto ?? _respaldo;
    final fijado = _punto != null;

    return Scaffold(
      appBar: AppBarTaller(
        mostrarCarrito: false,
        subtitulo: 'Proveedor',
        title: const Text('Ubicacion exacta'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: centro, zoom: fijado ? 17 : 14),
              padding: const EdgeInsets.only(bottom: 170, top: 70),
              onMapCreated: (c) => _mapa = c,
              onTap: _mover,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                if (_punto != null)
                  Marker(
                    markerId: const MarkerId('proveedor'),
                    position: _punto!,
                    draggable: true,
                    anchor: const Offset(0.5, 0.92),
                    icon: _icono ?? BitmapDescriptor.defaultMarker,
                    infoWindow: InfoWindow(title: widget.nombre),
                    onDragEnd: _mover,
                  ),
              },
            ),
          ),

          // ---- indicador con flecha animada
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: Material(
              color: AppTheme.grafito,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _flecha,
                      builder: (_, child) => Transform.translate(
                          offset: Offset(0, 5 * _flecha.value), child: child),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: AppTheme.primary, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fijado
                            ? 'Arrastra el pin o toca el mapa hasta la puerta exacta del proveedor.'
                            : 'Toca el mapa para colocar el pin del proveedor.',
                        style: const TextStyle(
                            color: AppTheme.hueso, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                    if (_buscando)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
          ),

          // ---- confirmar
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: Material(
              color: AppTheme.grafito,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fijado
                          ? 'LAT ${_punto!.latitude.toStringAsFixed(6)}   LNG ${_punto!.longitude.toStringAsFixed(6)}'
                          : 'SIN UBICACION FIJADA',
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                          color: Color(0xCCEDE8DF)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: fijado
                            ? () => Navigator.of(context).pop(_punto)
                            : null,
                        icon: const Icon(Icons.push_pin_outlined),
                        label: const Text('FIJAR UBICACION'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
