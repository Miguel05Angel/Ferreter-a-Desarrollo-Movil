// Purga definitiva de la papelera de productos.
//
// Cada día a las 03:00 (hora de Lima) borra de verdad los productos que
// llevan 30 días o más en la papelera (campo `eliminadoEn`).
//
// Instalación:
//   1) Copia este archivo dentro de la carpeta /functions.
//   2) En /functions/index.js agrega:
//        exports.purgarPapelera = require('./purgarPapelera').purgarPapelera;
//   3) Despliega:  firebase deploy --only functions:purgarPapelera
//
// Requisitos: firebase-functions v2 y plan Blaze (las funciones programadas
// necesitan facturación activada; el consumo de este caso entra en la cuota
// gratuita).

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();

const DIAS_PAPELERA = 30;

exports.purgarPapelera = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/Lima' },
  async () => {
    const db = admin.firestore();
    const limite = admin.firestore.Timestamp.fromMillis(
      Date.now() - DIAS_PAPELERA * 24 * 60 * 60 * 1000
    );

    // Los productos sin `eliminadoEn` no coinciden con esta consulta.
    const snap = await db
      .collection('productos')
      .where('eliminadoEn', '<=', limite)
      .get();

    if (snap.empty) return;

    let lote = db.batch();
    let pendientes = 0;
    for (const doc of snap.docs) {
      lote.delete(doc.ref);
      pendientes++;
      if (pendientes === 400) {
        await lote.commit();
        lote = db.batch();
        pendientes = 0;
      }
    }
    if (pendientes > 0) await lote.commit();

    console.log(`Papelera: ${snap.size} producto(s) eliminados definitivamente.`);
  }
);
