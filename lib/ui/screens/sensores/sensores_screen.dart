import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Lectura en vivo de los sensores del telefono.
///
/// A diferencia del ejemplo de la guia, cada stream se guarda en una
/// StreamSubscription y se cancela en [dispose]. Sin eso los sensores siguen
/// emitiendo despues de cerrar la pantalla: se fuga memoria y Flutter lanza
/// "setState() called after dispose()".
class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  /// Todas las suscripciones abiertas, para cancelarlas de una sola vez.
  final List<StreamSubscription<dynamic>> _subs = [];

  _Lectura? _acelerometro;
  _Lectura? _giroscopio;
  _Lectura? _magnetometro;
  _Lectura? _aceleracionUsuario;

  final Map<String, String> _errores = {};

  @override
  void initState() {
    super.initState();
    _escuchar(
      'Acelerometro',
      accelerometerEventStream(),
      (e) => _acelerometro = _Lectura(e.x, e.y, e.z),
    );
    _escuchar(
      'Giroscopio',
      gyroscopeEventStream(),
      (e) => _giroscopio = _Lectura(e.x, e.y, e.z),
    );
    _escuchar(
      'Magnetometro',
      magnetometerEventStream(),
      (e) => _magnetometro = _Lectura(e.x, e.y, e.z),
    );
    _escuchar(
      'Aceleracion del usuario',
      userAccelerometerEventStream(),
      (e) => _aceleracionUsuario = _Lectura(e.x, e.y, e.z),
    );
  }

  /// Se suscribe a un sensor y guarda la suscripcion para poder cancelarla.
  void _escuchar<T>(
    String nombre,
    Stream<T> stream,
    void Function(T evento) asignar,
  ) {
    _subs.add(
      stream.listen(
        (evento) {
          // El evento puede llegar justo despues de cerrar la pantalla.
          if (!mounted) return;
          setState(() => asignar(evento));
        },
        // Un telefono sin giroscopio o sin magnetometro lanza error aqui:
        // se muestra el aviso en vez de dejar la tarjeta en blanco.
        onError: (Object error) {
          if (!mounted) return;
          setState(() => _errores[nombre] = 'No disponible en este equipo');
        },
        cancelOnError: true,
      ),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores del telefono')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NivelCard(lectura: _acelerometro),
          const SizedBox(height: 12),
          _SensorCard(
            titulo: 'Acelerometro',
            descripcion: 'Incluye la gravedad. En reposo y plano marca Z ~ 9.8',
            icono: Icons.speed,
            unidad: 'm/s2',
            lectura: _acelerometro,
            error: _errores['Acelerometro'],
          ),
          _SensorCard(
            titulo: 'Giroscopio',
            descripcion: 'Velocidad de giro en cada eje',
            icono: Icons.threesixty,
            unidad: 'rad/s',
            lectura: _giroscopio,
            error: _errores['Giroscopio'],
          ),
          _SensorCard(
            titulo: 'Magnetometro',
            descripcion: 'Campo magnetico, la base de la brujula',
            icono: Icons.explore,
            unidad: 'uT',
            lectura: _magnetometro,
            error: _errores['Magnetometro'],
          ),
          _SensorCard(
            titulo: 'Aceleracion del usuario',
            descripcion: 'El mismo acelerometro pero sin la gravedad',
            icono: Icons.directions_run,
            unidad: 'm/s2',
            lectura: _aceleracionUsuario,
            error: _errores['Aceleracion del usuario'],
          ),
        ],
      ),
    );
  }
}

/// Valores X, Y, Z de un sensor en un instante.
class _Lectura {
  const _Lectura(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// Nivel de burbuja: convierte el acelerometro en grados de inclinacion.
///
/// Util de verdad en una ferreteria para comprobar si una repisa, un marco o
/// un mueble quedo derecho.
class _NivelCard extends StatelessWidget {
  const _NivelCard({required this.lectura});

  final _Lectura? lectura;

  @override
  Widget build(BuildContext context) {
    final l = lectura;
    // Con el telefono plano boca arriba: x~0, y~0, z~9.8 -> 0 grados en ambos.
    final horizontal = l == null
        ? 0.0
        : math.atan2(-l.x, math.sqrt(l.y * l.y + l.z * l.z)) * 180 / math.pi;
    final vertical = l == null ? 0.0 : math.atan2(l.y, l.z) * 180 / math.pi;
    final nivelado =
        l != null && horizontal.abs() < 1.0 && vertical.abs() < 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  nivelado ? Icons.check_circle : Icons.straighten,
                  color: nivelado ? Colors.green : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nivel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (l == null)
                  const Text('Leyendo...')
                else
                  Text(
                    nivelado ? 'NIVELADO' : 'DESNIVELADO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: nivelado ? Colors.green : Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Apoya el telefono sobre la superficie que quieras comprobar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child:
                      _Grados(etiqueta: 'Adelante / atras', valor: horizontal),
                ),
                Expanded(
                  child: _Grados(
                      etiqueta: 'Izquierda / derecha', valor: vertical),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Grados extends StatelessWidget {
  const _Grados({required this.etiqueta, required this.valor});

  final String etiqueta;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${valor.toStringAsFixed(1)} grados',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

/// Tarjeta con los tres ejes de un sensor.
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.unidad,
    required this.lectura,
    this.error,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final String unidad;
  final _Lectura? lectura;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = lectura;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(descripcion,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(unidad, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(error!)),
                ],
              )
            else if (l == null)
              const Text('Leyendo...')
            else
              Row(
                children: [
                  Expanded(child: _Eje(nombre: 'X', valor: l.x)),
                  Expanded(child: _Eje(nombre: 'Y', valor: l.y)),
                  Expanded(child: _Eje(nombre: 'Z', valor: l.z)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Eje extends StatelessWidget {
  const _Eje({required this.nombre, required this.valor});

  final String nombre;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, style: Theme.of(context).textTheme.labelMedium),
        Text(
          valor.toStringAsFixed(2),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}
