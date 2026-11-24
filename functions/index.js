const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

async function personal(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Inicia sesión.');
  }

  const db = getFirestore(); 
  const usuarios = db.collection('usuarios');
  const perfil = await usuarios.doc(request.auth.uid).get();
  if (!['Administrador', 'Vendedor'].includes(perfil.get('rol')) ||
      request.auth.token.email !== perfil.get('dni') + '@acceso.ferreteria.invalid') {
    throw new HttpsError('permission-denied', 'Cuenta sin perfil autorizado.');
  }
  return { db, usuarios, perfil };
}

// La contraseña se modifica en Authentication, nunca se guarda en Firestore.
exports.restablecerPasswordUsuario = onCall({ region: 'southamerica-east1' }, async (request) => {
  const { usuarios, perfil } = await personal(request);
  if (perfil.get('rol') !== 'Administrador') {
    throw new HttpsError('permission-denied', 'Acceso reservado al administrador.');
  }
  const authTime = request.auth.token.auth_time;
  const now = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(authTime) || now - authTime > 300 || authTime > now + 30) {
    throw new HttpsError('failed-precondition', 'Confirma de nuevo tu contraseña actual.');
  }
  const { usuarioId, nuevaPassword } = request.data ?? {};
  if (typeof usuarioId !== 'string' || !usuarioId || usuarioId.length > 128 ||
      usuarioId.includes('/') || typeof nuevaPassword !== 'string' ||
      nuevaPassword.length < 6 || nuevaPassword.length > 20 || !/[0-9]/.test(nuevaPassword)) {
    throw new HttpsError('invalid-argument', 'Datos de contraseña inválidos.');
  }
  if (usuarioId === request.auth.uid) {
    throw new HttpsError('invalid-argument', 'Usa Cambiar mi contraseña para tu propia cuenta.');
  }
  const destino = await usuarios.doc(usuarioId).get();
  if (!destino.exists || !['Administrador', 'Vendedor'].includes(destino.get('rol')) ||
      typeof destino.get('dni') !== 'string' || !/^[0-9]{8}$/.test(destino.get('dni'))) {
    throw new HttpsError('not-found', 'No se encontró la cuenta de personal.');
  }
  const auth = getAuth();
  try {
    const cuenta = await auth.getUser(usuarioId);
    if (cuenta.disabled || cuenta.email !== destino.get('dni') + '@acceso.ferreteria.invalid') {
      throw new HttpsError('failed-precondition', 'La cuenta no está habilitada o no coincide con el perfil.');
    }
    await auth.updateUser(usuarioId, { password: nuevaPassword });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.code === 'auth/user-not-found') {
      throw new HttpsError('not-found', 'No se encontró la cuenta.');
    }
    if (['auth/invalid-password', 'auth/password-does-not-meet-requirements'].includes(error.code)) {
      throw new HttpsError('invalid-argument', 'La contraseña no cumple los requisitos.');
    }
    // No incluir request.data ni el error del proveedor en los registros.
    throw new HttpsError('internal', 'No se pudo restablecer la contraseña.');
  }
  return { usuarioId };
});

exports.eliminarUsuario = onCall({ region: 'southamerica-east1' }, async (request) => {
  const { usuarios, perfil } = await personal(request);
  if (perfil.get('rol') !== 'Administrador') {
    throw new HttpsError('permission-denied', 'Acceso reservado al administrador.');
  }
  const now = Math.floor(Date.now() / 1000);
  const authTime = request.auth.token.auth_time;
  if (!Number.isFinite(authTime) || now - authTime > 300 || authTime > now + 30) {
    throw new HttpsError('failed-precondition', 'Confirma de nuevo tu contraseña actual.');
  }
  const { usuarioId } = request.data ?? {};
  if (typeof usuarioId !== 'string' || !usuarioId || usuarioId.length > 128 || usuarioId.includes('/')) {
    throw new HttpsError('invalid-argument', 'Usuario inválido.');
  }
  if (usuarioId === request.auth.uid) {
    throw new HttpsError('failed-precondition', 'No puedes eliminar tu propia cuenta.');
  }
  const ref = usuarios.doc(usuarioId);
  const destino = await ref.get();
  if (!destino.exists) {
    // Una segunda petición tras perder la respuesta puede repetirse sin efectos.
    return { usuarioId, yaEliminado: true };
  }
  if (!['Administrador', 'Vendedor'].includes(destino.get('rol')) ||
      typeof destino.get('dni') !== 'string' || !/^[0-9]{8}$/.test(destino.get('dni'))) {
    throw new HttpsError('failed-precondition', 'El perfil no corresponde a una cuenta de personal.');
  }
  const auth = getAuth();
  try {
    let cuenta;
    try { cuenta = await auth.getUser(usuarioId); }
    catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
    if (cuenta && cuenta.email !== destino.get('dni') + '@acceso.ferreteria.invalid') {
      throw new HttpsError('failed-precondition', 'La cuenta no coincide con el perfil.');
    }
    // Primero quitar el acceso. Si falla Firestore, una repetición termina la limpieza.
    if (cuenta) await auth.deleteUser(usuarioId);
    await ref.delete();
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'No se pudo confirmar la eliminación. Actualiza la lista antes de reintentar.');
  }
  // Las ventas históricas y los demás documentos no se eliminan.
  return { usuarioId, yaEliminado: false };
});

exports.registrarVendedor = onCall({ region: 'southamerica-east1' }, async (request) => {
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

exports.registrarVenta = onCall({ region: 'southamerica-east1' }, async (request) => {
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
