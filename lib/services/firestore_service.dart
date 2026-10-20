import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/firestore_mappers.dart';
import '../data/mock_data.dart';

/// Unico punto de acceso a Firestore (base de datos "ferreteria-db").
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const String databaseId = 'ferreteria-db';

  // Colecciones
  static const String colProductos = 'productos';
  static const String colClientes = 'clientes';
  static const String colProveedores = 'proveedores';
  static const String colVentas = 'ventas';
  static const String colCotizaciones = 'cotizaciones';

  final FirebaseFirestore db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: databaseId,
  );

  // ------------------------------------------------------------------
  // LECTURA EN TIEMPO REAL
  // ------------------------------------------------------------------
  Stream<List<T>> escuchar<T>(
    String coleccion,
    T Function(String id, Mapa datos) desde,
  ) {
    return db.collection(coleccion).snapshots().map((snap) {
      debugPrint('📡 Firestore [$coleccion]: ${snap.docs.length} documentos '
          '${snap.metadata.isFromCache ? "(caché local)" : "(servidor)"}');
      final docs = snap.docs.toList()
        ..sort((a, b) => _creado(a.data()).compareTo(_creado(b.data())));
      return docs.map((d) => desde(d.id, d.data())).toList();
    });
  }

  static int _creado(Mapa data) {
    final v = data['creadoEn'];
    return v is Timestamp ? v.millisecondsSinceEpoch : 0;
  }

  // ------------------------------------------------------------------
  // ESCRITURA
  // ------------------------------------------------------------------
  Future<void> crear(String coleccion, String id, Mapa datos) => _ejecutar(
        'crear $coleccion/$id',
        () => db
            .collection(coleccion)
            .doc(id)
            .set({...datos, 'creadoEn': Timestamp.now()}),
      );

  Future<void> guardar(String coleccion, String id, Mapa datos) => _ejecutar(
        'guardar $coleccion/$id',
        () => db
            .collection(coleccion)
            .doc(id)
            .set(datos, SetOptions(merge: true)),
      );

  Future<void> eliminar(String coleccion, String id) => _ejecutar(
        'eliminar $coleccion/$id',
        () => db.collection(coleccion).doc(id).delete(),
      );

  Future<void> _ejecutar(String que, Future<void> Function() accion) async {
    try {
      await accion();
      debugPrint('✅ Firestore: $que (confirmado por el servidor)');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore: $que → (${e.code}) ${e.message}');
      debugPrint(_pista(e.code));
    } catch (e) {
      debugPrint('❌ Firestore: $que → $e');
    }
  }

  // ------------------------------------------------------------------
  // VERIFICACION DE CONEXION + CARGA INICIAL
  // ------------------------------------------------------------------
  /// Comprueba que el servidor responde y, SOLO la primera vez,
  /// sube los datos de ejemplo (MockData) a la base.
  Future<void> inicializarBaseDeDatos() async {
    try {
      final meta = db.collection('_meta').doc('seed');
      final snap = await meta
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      debugPrint('✅ Firestore CONECTADO a la base "$databaseId" '
          '(el servidor respondió)');
      if (snap.exists) {
        debugPrint('ℹ️ Datos iniciales ya cargados anteriormente.');
        return;
      }
      await _sembrar(meta);
    } on TimeoutException {
      debugPrint('❌ Firestore: sin respuesta en 10 s. Revisa tu internet '
          'o que la base "$databaseId" exista.');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore (${e.code}): ${e.message}');
      debugPrint(_pista(e.code));
    } catch (e) {
      debugPrint('❌ Firestore: $e');
    }
  }

  Future<void> _sembrar(DocumentReference<Mapa> meta) async {
    final batch = db.batch();
    final base = DateTime.now();
    var n = 0;

    void poner(String coleccion, String id, Mapa datos) {
      batch.set(db.collection(coleccion).doc(id), {
        ...datos,
        // Orden estable: respeta el orden de MockData.
        'creadoEn': Timestamp.fromDate(base.add(Duration(milliseconds: n++))),
      });
    }

    for (final p in MockData.productos) {
      poner(colProductos, p.id, Mapeadores.productoAMapa(p));
    }
    for (final c in MockData.clientes) {
      poner(colClientes, c.id, Mapeadores.clienteAMapa(c));
    }
    for (final p in MockData.proveedores) {
      poner(colProveedores, p.id, Mapeadores.proveedorAMapa(p));
    }
    for (final v in MockData.ventas) {
      poner(colVentas, v.id, Mapeadores.ventaAMapa(v));
    }
    for (final c in MockData.cotizaciones) {
      poner(colCotizaciones, c.id, Mapeadores.cotizacionAMapa(c));
    }
    batch.set(meta, {'cargadoEn': Timestamp.now(), 'documentos': n});

    await batch.commit();
    debugPrint('🌱 Firestore: datos iniciales cargados ($n documentos).');
  }

  static String _pista(String code) {
    switch (code) {
      case 'permission-denied':
        return '👉 Revisa las REGLAS de la base "$databaseId" en Firebase '
            'Console (pestaña Reglas). Copia las de firestore.rules.';
      case 'not-found':
        return '👉 La base "$databaseId" no existe en este proyecto. '
            'Revisa el nombre en Firebase Console → Firestore.';
      case 'unavailable':
        return '👉 Sin conexión a internet o Firestore no disponible.';
      default:
        return '👉 Código de error: $code';
    }
  }
}
