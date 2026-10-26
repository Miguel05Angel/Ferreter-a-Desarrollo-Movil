import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/proveedor.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/layout/appbar_taller.dart';

/// Atajos para abrir el mapa desde cualquier pantalla.
class AppRoutesMapa {
  AppRoutesMapa._();

  static Future<void> tienda(BuildContext context) => AppRoutes.push(
        context,
        const MapaScreen(
          titulo: 'Ferreteria El Constructor',
          subtitulo: 'Nuestra tienda',
          direccion: AppConstants.direccionFerreteria,
          posicion: LatLng(
              AppConstants.latitudFerreteria, AppConstants.longitudFerreteria),
        ),
      );

  static Future<void> cliente(BuildContext context, Cliente c) =>
      AppRoutes.push(
        context,
        MapaScreen(
          titulo: c.nombre,
          subtitulo: 'Direccion del cliente',
          direccion: c.direccion,
          iconoDestino: Icons.person,
          colorDestino: const Color(0xFF2E7D32),
        ),
      );

  static Future<void> abrir(BuildContext context, Proveedor p) =>
      AppRoutes.push(
        context,
        MapaScreen(
          titulo: p.nombre,
          subtitulo: 'Proveedor',
          direccion: p.direccion,
          iconoDestino: Icons.local_shipping,
          colorDestino: const Color(0xFF0277BD),
          posicion: (p.latitud != null && p.longitud != null)
              ? LatLng(p.latitud!, p.longitud!)
              : null,
        ),
      );
}

/// Mapa de Google con la ubicacion de la tienda, un cliente o un proveedor.
/// Si solo se conoce la direccion, se convierte a coordenadas con el
/// geocodificador. Permite abrir la ruta en la app de Google Maps y muestra
/// la distancia en linea recta desde la tienda.
class MapaScreen extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final String direccion;
  final LatLng? posicion;
  final IconData iconoDestino;
  final Color colorDestino;

  const MapaScreen({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.direccion,
    this.posicion,
    this.iconoDestino = Icons.place,
    this.colorDestino = const Color(0xFF0277BD),
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen>
    with SingleTickerProviderStateMixin {
  static const LatLng _tienda = LatLng(
      AppConstants.latitudFerreteria, AppConstants.longitudFerreteria);

  static const String _estiloOscuro = '['
      '{"elementType":"geometry","stylers":[{"color":"#1d2226"}]},'
      '{"elementType":"labels.text.fill","stylers":[{"color":"#8a9199"}]},'
      '{"elementType":"labels.text.stroke","stylers":[{"color":"#15181b"}]},'
      '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c3339"}]},'
      '{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a4148"}]},'
      '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1316"}]},'
      '{"featureType":"poi","stylers":[{"visibility":"off"}]}'
      ']';

  GoogleMapController? _controlador;
  LatLng? _pos;
  bool _buscando = true;
  String? _error;

  // ----- marcadores personalizados y ruta animada -----
  BitmapDescriptor? _iconoTienda;
  BitmapDescriptor? _iconoDestino;
  bool _iconosCargados = false;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..addListener(() {
      if (mounted) setState(() {});
    });
  List<LatLng> _ruta = const [];
  bool _rutaReal = false;
  double? _kmRuta;
  int? _minRuta;

  bool get _esTienda => widget.posicion == _tienda;

  @override
  void initState() {
    super.initState();
    _resolverUbicacion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iconosCargados) return;
    _iconosCargados = true;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    _crearIcono(Icons.storefront, AppTheme.primary, dpr).then((i) {
      if (mounted) setState(() => _iconoTienda = i);
    });
    _crearIcono(widget.iconoDestino, widget.colorDestino, dpr).then((i) {
      if (mounted) setState(() => _iconoDestino = i);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controlador?.dispose();
    super.dispose();
  }

  /// Dibuja un pin con un icono dentro y lo convierte en marcador del mapa.
  Future<BitmapDescriptor> _crearIcono(
      IconData icono, Color color, double dpr) async {
    const w = 64.0, h = 78.0, r = 26.0;
    final grabador = ui.PictureRecorder();
    final c = Canvas(grabador);
    c.scale(dpr);
    const cx = w / 2;
    const cy = r + 4;

    final cabeza = Path()
      ..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r));
    final punta = Path()
      ..moveTo(cx - 15, cy + r - 8)
      ..lineTo(cx, h - 4)
      ..lineTo(cx + 15, cy + r - 8)
      ..close();
    final pin = Path.combine(PathOperation.union, cabeza, punta);

    c.drawShadow(pin, Colors.black, 4, true);
    c.drawPath(pin, Paint()..color = color);
    c.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawCircle(const Offset(cx, cy), 19, Paint()..color = Colors.white);

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: 26,
          fontFamily: icono.fontFamily,
          package: icono.fontPackage,
          color: color,
        ),
      ),
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final img = await grabador
        .endRecording()
        .toImage((w * dpr).ceil(), (h * dpr).ceil());
    final datos = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      datos!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  /// Pide a OSRM (gratuito) la ruta por calles entre la tienda y el destino.
  /// Si no hay conexion o falla, usa una linea recta punteada.
  Future<void> _cargarRuta() async {
    final destino = _pos;
    if (destino == null || _esTienda) return;

    var puntos = <LatLng>[_tienda, destino];
    var real = false;
    double? km;
    int? min;
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_tienda.longitude},${_tienda.latitude};'
        '${destino.longitude},${destino.latitude}'
        '?overview=full&geometries=geojson',
      );
      final r = await http.get(uri, headers: {
        'User-Agent': 'FerreteriaElConstructor/1.0',
      }).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final rutas = j['routes'] as List?;
        if (rutas != null && rutas.isNotEmpty) {
          final ruta = rutas.first as Map<String, dynamic>;
          final coords = (ruta['geometry'] as Map)['coordinates'] as List;
          var lista = coords
              .map((c) => LatLng(
                  (c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          // Aligera el trazado para que la animacion sea fluida.
          if (lista.length > 160) {
            final paso = (lista.length / 160).ceil();
            final ligera = <LatLng>[
              for (var i = 0; i < lista.length; i += paso) lista[i],
            ];
            if (ligera.last != lista.last) ligera.add(lista.last);
            lista = ligera;
          }
          if (lista.length >= 2) {
            puntos = lista;
            real = true;
            km = (ruta['distance'] as num).toDouble() / 1000;
            min = ((ruta['duration'] as num).toDouble() / 60).round();
          }
        }
      }
    } catch (_) {
      // se queda la linea recta
    }
    if (!mounted) return;
    setState(() {
      _ruta = puntos;
      _rutaReal = real;
      _kmRuta = km;
      _minRuta = min;
    });
    _ajustarCamara();
    _anim.forward(from: 0);
  }

  /// Parte de la ruta que ya se "dibujo" segun el avance de la animacion.
  List<LatLng> _tramoVisible(double f) {
    if (_ruta.length < 2 || f <= 0) return const [];
    if (f >= 1) return _ruta;
    final acumulado = <double>[0];
    for (var i = 1; i < _ruta.length; i++) {
      final dx = _ruta[i].latitude - _ruta[i - 1].latitude;
      final dy = _ruta[i].longitude - _ruta[i - 1].longitude;
      acumulado.add(acumulado.last + math.sqrt(dx * dx + dy * dy));
    }
    final meta = acumulado.last * f;
    final visibles = <LatLng>[_ruta.first];
    for (var i = 1; i < _ruta.length; i++) {
      if (acumulado[i] <= meta) {
        visibles.add(_ruta[i]);
      } else {
        final seg = acumulado[i] - acumulado[i - 1];
        final t = seg == 0 ? 0.0 : (meta - acumulado[i - 1]) / seg;
        visibles.add(LatLng(
          _ruta[i - 1].latitude +
              (_ruta[i].latitude - _ruta[i - 1].latitude) * t,
          _ruta[i - 1].longitude +
              (_ruta[i].longitude - _ruta[i - 1].longitude) * t,
        ));
        break;
      }
    }
    return visibles;
  }

  void _ajustarCamara() {
    final pos = _pos;
    final c = _controlador;
    if (pos == null || c == null || _esTienda) return;
    final puntos = _ruta.isNotEmpty ? _ruta : [_tienda, pos];
    var minLat = puntos.first.latitude, maxLat = minLat;
    var minLng = puntos.first.longitude, maxLng = minLng;
    for (final p in puntos) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      try {
        c.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng)),
          70,
        ));
      } catch (_) {}
    });
  }

  Future<void> _resolverUbicacion() async {
    if (widget.posicion != null) {
      setState(() {
        _pos = widget.posicion;
        _buscando = false;
      });
      _cargarRuta();
      return;
    }
    try {
      final punto = await _buscarCoordenadas(widget.direccion);
      if (!mounted) return;
      if (punto == null) throw Exception('sin resultados');
      setState(() {
        _pos = punto;
        _buscando = false;
      });
      _cargarRuta();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos ubicar esta direccion en el mapa.';
        _buscando = false;
      });
    }
  }

  /// Convierte una direccion en coordenadas con el buscador gratuito de
  /// OpenStreetMap (Nominatim). No necesita clave ni plugins nativos.
  Future<LatLng?> _buscarCoordenadas(String direccion) async {
    Future<LatLng?> consultar(String texto) async {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': texto,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'pe',
      });
      final r = await http.get(uri, headers: {
        'User-Agent': 'FerreteriaElConstructor/1.0',
        'Accept-Language': 'es',
      }).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final lista = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      if (lista.isEmpty) return null;
      final primero = lista.first as Map<String, dynamic>;
      return LatLng(
        double.parse('${primero['lat']}'),
        double.parse('${primero['lon']}'),
      );
    }

    // Primero con la direccion completa; si no aparece, con lo que va despues
    // de la primera coma (distrito y ciudad).
    final completa = await consultar('$direccion, Peru');
    if (completa != null) return completa;
    final partes = direccion.split(',');
    if (partes.length > 1) {
      return consultar('${partes.sublist(1).join(',').trim()}, Peru');
    }
    return null;
  }

  /// Distancia en linea recta entre dos puntos (formula de Haversine).
  double _km(LatLng a, LatLng b) {
    const r = 6371.0;
    double rad(double g) => g * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  Future<void> _abrir(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('no se pudo abrir');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('No se pudo abrir Google Maps.'),
        ),
      );
    }
  }

  Uri get _urlRuta {
    final destino = _pos != null
        ? '${_pos!.latitude},${_pos!.longitude}'
        : Uri.encodeComponent(widget.direccion);
    return Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destino&travelmode=driving');
  }

  Uri get _urlBuscar => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_pos != null ? '${_pos!.latitude},${_pos!.longitude}' : Uri.encodeComponent(widget.direccion)}');

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final esTienda = _esTienda;
    final distancia = (_pos != null && !esTienda) ? _km(_tienda, _pos!) : null;
    final visible = _tramoVisible(Curves.easeInOut.transform(_anim.value));

    return Scaffold(
      appBar: AppBarTaller(
        mostrarCarrito: false,
        subtitulo: widget.subtitulo,
        title: const Text('Ubicacion'),
      ),
      body: Stack(
        children: [
          if (_pos != null)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: esTienda
                      ? _pos!
                      : LatLng((_pos!.latitude + _tienda.latitude) / 2,
                          (_pos!.longitude + _tienda.longitude) / 2),
                  zoom: esTienda ? 15.5 : 12.5,
                ),
                padding: const EdgeInsets.only(bottom: 250),
                style: oscuro ? _estiloOscuro : null,
                markers: {
                  Marker(
                    markerId: const MarkerId('destino'),
                    position: _pos!,
                    anchor: const Offset(0.5, 0.92),
                    zIndexInt: 2,
                    infoWindow: InfoWindow(
                        title: widget.titulo, snippet: widget.direccion),
                    icon: _iconoDestino ?? BitmapDescriptor.defaultMarker,
                  ),
                  if (!esTienda)
                    Marker(
                      markerId: const MarkerId('tienda'),
                      position: _tienda,
                      anchor: const Offset(0.5, 0.92),
                      zIndexInt: 1,
                      infoWindow: const InfoWindow(
                          title: 'Ferreteria El Constructor',
                          snippet: 'Nuestra tienda'),
                      icon: _iconoTienda ?? BitmapDescriptor.defaultMarker,
                    ),
                },
                polylines: {
                  if (visible.length >= 2) ...{
                    Polyline(
                      polylineId: const PolylineId('ruta_borde'),
                      points: visible,
                      color: const Color(0xFF15181B),
                      width: 9,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                    ),
                    Polyline(
                      polylineId: const PolylineId('ruta'),
                      points: visible,
                      color: AppTheme.primary,
                      width: 5,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      patterns: _rutaReal
                          ? const []
                          : [PatternItem.dash(18), PatternItem.gap(10)],
                    ),
                  },
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (c) {
                  _controlador = c;
                  _ajustarCamara();
                },
              ),
            )
          else
            Positioned.fill(
              child: Center(
                child: _buscando
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Ubicando direccion...'),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 56, color: Colors.grey.shade500),
                            const SizedBox(height: 14),
                            Text(
                              _error ?? 'Sin ubicacion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Puedes buscarla directamente en Google Maps.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

          // zoom
          if (_pos != null)
            Positioned(
              right: 14,
              top: 14,
              child: Column(
                children: [
                  _BotonMapa(
                      Icons.add, () => _controlador?.animateCamera(CameraUpdate.zoomIn())),
                  const SizedBox(height: 8),
                  _BotonMapa(Icons.remove,
                      () => _controlador?.animateCamera(CameraUpdate.zoomOut())),
                  const SizedBox(height: 8),
                  _BotonMapa(
                    Icons.my_location,
                    () => _controlador?.animateCamera(
                        CameraUpdate.newLatLngZoom(_pos!, 15.5)),
                  ),
                  if (!esTienda) ...[
                    const SizedBox(height: 8),
                    _BotonMapa(Icons.route, _ajustarCamara),
                    const SizedBox(height: 8),
                    _BotonMapa(Icons.replay, () => _anim.forward(from: 0)),
                  ],
                ],
              ),
            ),

          // ---------------------------------------------- panel inferior
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: AppTheme.grafito,
                shape: const BeveledRectangleBorder(
                  borderRadius:
                      BorderRadius.only(bottomRight: Radius.circular(24)),
                  side: BorderSide(color: AppTheme.primary, width: 1.6),
                ),
                shadows: const [
                  BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.hueso,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.direccion,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Color(0xCCEDE8DF)),
                        ),
                      ),
                    ],
                  ),
                  if (distancia != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.amarilloSenal.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        (_rutaReal && _kmRuta != null)
                            ? 'RUTA: ${_kmRuta!.toStringAsFixed(1)} KM  ·  ~${_minRuta ?? 0} MIN EN AUTO'
                            : 'A ${distancia.toStringAsFixed(1)} KM DE LA TIENDA (EN LINEA RECTA)',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.amarilloSenal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _LeyendaPin(
                            icono: Icons.storefront,
                            color: AppTheme.primary,
                            texto: 'TIENDA'),
                        const SizedBox(width: 14),
                        _LeyendaPin(
                            icono: widget.iconoDestino,
                            color: widget.colorDestino,
                            texto: widget.subtitulo.toUpperCase()),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          texto: 'Como llegar',
                          icono: Icons.navigation_outlined,
                          alto: 48,
                          onPressed: () => _abrir(_urlRuta),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.hueso,
                              side: const BorderSide(
                                  color: AppTheme.bordeOscuro, width: 1.6),
                            ),
                            onPressed: () => _abrir(_urlBuscar),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('GOOGLE MAPS'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (kDebugMode)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Mapa en gris? Falta la clave de Google Maps en AndroidManifest.xml',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: Color(0x80EDE8DF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonMapa extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonMapa(this.icono, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: ShapeDecoration(
          color: AppTheme.grafito,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
            side: BorderSide(color: AppTheme.primary, width: 1.4),
          ),
          shadows: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 8),
          ],
        ),
        child: Icon(icono, color: AppTheme.primary, size: 22),
      ),
    );
  }
}

class _LeyendaPin extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;

  const _LeyendaPin(
      {required this.icono, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icono, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: Color(0xCCEDE8DF),
          ),
        ),
      ],
    );
  }
}
