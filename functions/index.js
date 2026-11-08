const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

async function personal(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Inicia sesión.');
  }

  const db = getFirestore('ferreteria-db');
  const usuarios = db.collection('usuarios');
  const perfil = await usuarios.doc(request.auth.uid).get();
  if (!['Administrador', 'Vendedor'].includes(perfil.get('rol')) ||
      request.auth.token.email !== perfil.get('dni') + '@acceso.ferreteria.invalid') {
    throw new HttpsError('permission-denied', 'Cuenta sin perfil autorizado.');
  }
  return { db, usuarios, perfil };
}

exports.registrarVendedor = onCall(async (request) => {
  const { usuarios, perfil } = await personal(request);
  if (perfil.get('rol') !== 'Administrador') {
    throw new HttpsError('permission-denied', 'Acceso reservado al administrador.');
  }

  const { operacion, dni, nombre, telefono, password } = request.data ?? {};
  if (
    typeof operacion !== 'string' || !/^[a-zA-Z0-9]{20}$/.test(operacion) ||
    typeof dni !== 'string' || !/^[0-9]{8}$/.test(dni) || dni === '00000000' ||
    typeof nombre !== 'string' || nombre.trim().length < 3 || nombre.length > 50 ||
    typeof telefono !== 'string' || !/^9[0-9]{8}$/.test(telefono) ||
    typeof password !== 'string' || password.length < 6 || password.length > 128 ||
    !/[0-9]/.test(password)
  ) {
    throw new HttpsError('invalid-argument', 'Datos de vendedor inválidos.');
  }

  const auth = getAuth();
  const email = dni + '@acceso.ferreteria.invalid';
  const uid = 'vendedor-' + operacion;
  try {
    await auth.createUser({ uid, email, password });
  } catch (error) {
    if (!['auth/uid-already-exists', 'auth/email-already-exists'].includes(error.code)) {
      throw error;
    }
    const anterior = await auth.getUserByEmail(email).catch((error) => {
      if (error.code === 'auth/user-not-found') return null;
      throw error;
    });
    if (anterior?.uid !== uid || anterior.disabled) {
      throw new HttpsError('already-exists', 'El DNI ya está registrado.');
    }
  }

  // Sin perfil la cuenta no puede acceder. La misma operación permite
  // terminar un alta interrumpida sin cambiar su contraseña ni su rol.
  const ref = usuarios.doc(uid);
  const datos = { dni, nombre: nombre.trim(), telefono, rol: 'Vendedor' };
  await ref.firestore.runTransaction(async (tx) => {
    const existente = await tx.get(ref);
    if (!existente.exists) {
      tx.create(ref, datos);
    } else if (existente.get('dni') !== dni || existente.get('rol') !== 'Vendedor') {
      throw new HttpsError('already-exists', 'El DNI ya está registrado.');
    }
  });
  return { uid };
});

exports.registrarVenta = onCall(async (request) => {
  const { db, perfil } = await personal(request);
  const { id, clienteNombre, items, metodoPago, comprobante } = request.data ?? {};
  if (
    typeof id !== 'string' || !/^[a-zA-Z0-9]{20}$/.test(id) ||
    typeof clienteNombre !== 'string' || !clienteNombre.trim() || clienteNombre.length > 200 ||
    !['Efectivo', 'Yape', 'Plin', 'Tarjeta'].includes(metodoPago) ||
    !['Boleta', 'Factura'].includes(comprobante) ||
    !Array.isArray(items) || !items.length || items.length > 100 ||
    items.some((item) => !item ||
      typeof item.productoId !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(item.productoId) ||
      !Number.isSafeInteger(item.cantidad) || item.cantidad <= 0 ||
      !Number.isFinite(item.precioUnitario)) ||
    new Set(items.map((item) => item.productoId)).size !== items.length
  ) {
    throw new HttpsError('invalid-argument', 'Datos de venta inválidos.');
  }

  const ventas = db.collection('ventas');
  const ventaRef = ventas.doc(id);
  const prefijo = comprobante === 'Factura' ? 'F001-' : 'B001-';
  const contador = db.collection('_meta').doc('ventas-' + prefijo.slice(0, -1));
  const fecha = new Date();
  return db.runTransaction(async (tx) => {
    const registrada = await tx.get(ventaRef);
    if (registrada.exists) {
      if (registrada.get('vendedorId') !== request.auth.uid) {
        throw new HttpsError('already-exists', 'Identificador de venta ocupado.');
      }
      const venta = registrada.data();
      return { venta: { ...venta, fecha: venta.fecha.toMillis() }, cambios: [] };
    }

    const correlativo = await tx.get(contador);
    let ultimo = correlativo.get('ultimo') ?? 0;
    if (!correlativo.exists) {
      const historicas = await tx.get(ventas
        .where('numero', '>=', prefijo)
        .where('numero', '<', prefijo.slice(0, -1) + '.'));
      for (const doc of historicas.docs) {
        const numero = Number(doc.get('numero').slice(prefijo.length));
        if (Number.isSafeInteger(numero)) ultimo = Math.max(ultimo, numero);
      }
    }

    const referencias = items.map((item) => db.collection('productos').doc(item.productoId));
    const productos = await tx.getAll(...referencias);
    const cambios = [];
    let subtotalCentavos = 0;
    const detalle = productos.map((producto, i) => {
      const { cantidad, precioUnitario } = items[i];
      const precio = producto.get('precioVenta') ?? producto.get('precio');
      const stock = producto.get('stock');
      if (!producto.exists || !Number.isInteger(stock) || stock < cantidad) {
        throw new HttpsError('failed-precondition', 'Stock insuficiente o producto no disponible.');
      }
      if (precio !== precioUnitario || precio < 0) {
        throw new HttpsError('failed-precondition', 'Cambió el precio. Actualiza el carrito.');
      }
      subtotalCentavos += Math.round(cantidad * precio * 100);
      cambios.push({ id: producto.id, antes: stock, despues: stock - cantidad });
      return { productoId: producto.id, nombre: producto.get('nombre') ?? '', cantidad, precioUnitario };
    });

    const igvCentavos = Math.round(subtotalCentavos * 0.18);
    const totalCentavos = subtotalCentavos + igvCentavos;
    const venta = {
      numero: prefijo + String(ultimo + 1).padStart(4, '0'),
      clienteNombre: clienteNombre.trim(),
      items: detalle,
      subtotal: subtotalCentavos / 100,
      igv: igvCentavos / 100,
      total: totalCentavos / 100,
      redondeo: metodoPago === 'Efectivo' ? (totalCentavos % 10) / 100 : 0,
      metodoPago,
      comprobante,
      estado: 'Completada',
      fecha,
      vendedorId: request.auth.uid,
      vendedor: perfil.get('nombre'),
    };

    for (const [i, ref] of referencias.entries()) {
      tx.update(ref, { stock: cambios[i].despues });
    }
    tx.set(contador, { ultimo: ultimo + 1 });
    tx.create(ventaRef, venta);
    return { venta: { ...venta, fecha: fecha.getTime() }, cambios };
  });
});
