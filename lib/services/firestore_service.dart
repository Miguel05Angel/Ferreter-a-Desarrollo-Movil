import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_mappers.dart';
import '../data/mock_data.dart';
import '../data/models/producto.dart';
import 'firebase_ferreteria.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final db = FirebaseFerreteria.db;

  CollectionReference<Mapa> get productos => db.collection('productos');
  CollectionReference<Mapa> get ventas => db.collection('ventas');

  Future<void> prepararCatalogo() async {
    final marca = db.collection('_meta').doc('catalogo');
    if ((await marca.get(const GetOptions(source: Source.server))).exists)
      return;

    // Respeta un catálogo ya cargado en esta base.
    final actual =
        await productos.limit(1).get(const GetOptions(source: Source.server));

    await db.runTransaction((transaccion) async {
      if ((await transaccion.get(marca)).exists) return;
      final iniciales = actual.docs.isEmpty
          ? MockData.productos.indexed
          : <(int, Producto)>[];
      for (final (posicion, producto) in iniciales) {
        transaccion.set(productos.doc(producto.id), {
          ...Mapeadores.productoAMapa(producto),
          'creadoEn': Timestamp.fromMillisecondsSinceEpoch(posicion),
        });
      }
      transaccion.set(marca, {'creadoEn': FieldValue.serverTimestamp()});
    });
  }
}
