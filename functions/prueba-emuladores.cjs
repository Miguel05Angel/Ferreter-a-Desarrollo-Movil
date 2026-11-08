const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const projectId = 'demo-ferreteria';
const { FIRESTORE_EMULATOR_HOST, FIREBASE_AUTH_EMULATOR_HOST } = process.env;
if (!FIRESTORE_EMULATOR_HOST || !FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('Ejecuta la prueba con firebase emulators:exec.');
}

const app = initializeApp({ projectId });
const db = getFirestore(app, 'ferreteria-db');
const auth = getAuth(app);
const apiAuth = 'http://' + FIREBASE_AUTH_EMULATOR_HOST + '/identitytoolkit.googleapis.com/v1/accounts:';
const apiDb = 'http://' + FIRESTORE_EMULATOR_HOST +
  '/v1/projects/' + projectId + '/databases/ferreteria-db/documents/';
const apiFunciones = 'http://127.0.0.1:5001/' + projectId + '/us-central1/';

const emailDni = (dni) => dni + '@acceso.ferreteria.invalid';
const password = 'Prueba-local123';

async function peticion(url, { token, datos, method = 'POST' } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = 'Bearer ' + token;
  const respuesta = await fetch(url, {
    method,
    headers,
    body: datos === undefined ? undefined : JSON.stringify(datos),
  });
  return { codigo: respuesta.status, cuerpo: await respuesta.json() };
}

function llamar(nombre, token, data) {
  return peticion(apiFunciones + nombre, { token, datos: { data } });
}

async function iniciar(dni) {
  const respuesta = await peticion(apiAuth + 'signInWithPassword?key=demo-api-key', {
    datos: { email: emailDni(dni), password, returnSecureToken: true },
  });
  assert.equal(respuesta.codigo, 200, JSON.stringify(respuesta.cuerpo));
  return respuesta.cuerpo.idToken;
}

async function probar() {
  const admin = await auth.createUser({ email: emailDni('10000001'), password });
  await db.collection('usuarios').doc(admin.uid).set({
    nombre: 'Admin local', dni: '10000001', telefono: '', rol: 'Administrador',
  });
  await db.collection('productos').doc('martillo').set({
    nombre: 'Martillo', precioVenta: 10, stock: 3,
  });

  const datos = {
    operacion: 'registroPrueba000001',
    dni: '10000002', nombre: 'Vendedor local', telefono: '900000001', password,
  };
  const sinSesion = await llamar('registrarVendedor', null, datos);
  assert.equal(sinSesion.codigo, 401);
  const tokenAdmin = await iniciar('10000001');
  const alta = await llamar('registrarVendedor', tokenAdmin, datos);
  assert.equal(alta.codigo, 200, JSON.stringify(alta.cuerpo));
  const uid = alta.cuerpo.result.uid;
  assert.equal((await llamar('registrarVendedor', tokenAdmin, datos)).cuerpo.result.uid, uid);
  const duplicado = await llamar('registrarVendedor', tokenAdmin, {
    ...datos, operacion: 'registroPrueba000002',
  });
  assert.equal(duplicado.codigo, 409);

  const tokenVendedor = await iniciar('10000002');
  assert.equal((await llamar('registrarVendedor', tokenVendedor, datos)).codigo, 403);
  assert.equal((await peticion(apiDb + 'productos/martillo', { method: 'GET' })).codigo, 403);
  assert.equal((await peticion(apiDb + 'productos/martillo', {
    method: 'GET', token: tokenVendedor,
  })).codigo, 200);
  assert.equal((await peticion(apiDb + 'usuarios/' + uid + '?updateMask.fieldPaths=rol', {
    method: 'PATCH', token: tokenVendedor,
    datos: { fields: { rol: { stringValue: 'Administrador' } } },
  })).codigo, 403);

  const venta = {
    id: 'ventaPrueba000000001',
    clienteNombre: 'Público general', metodoPago: 'Efectivo', comprobante: 'Boleta',
    items: [{ productoId: 'martillo', cantidad: 2, precioUnitario: 10 }],
  };
  const compra = await llamar('registrarVenta', tokenVendedor, venta);
  assert.equal(compra.codigo, 200, JSON.stringify(compra.cuerpo));
  assert.equal(compra.cuerpo.result.venta.total, 23.6);
  assert.equal(compra.cuerpo.result.venta.numero, 'B001-0001');
  assert.equal((await llamar('registrarVenta', tokenVendedor, venta)).codigo, 200);
  assert.equal((await db.collection('productos').doc('martillo').get()).get('stock'), 1);
  assert.equal((await llamar('registrarVenta', tokenVendedor, {
    ...venta, id: 'ventaPrueba000000002',
  })).codigo, 400);

  await db.collection('ventas').doc('ajena').set({ vendedorId: admin.uid });
  const ajena = apiDb + 'ventas/ajena';
  assert.equal((await peticion(ajena, { method: 'GET', token: tokenVendedor })).codigo, 403);
  assert.equal((await peticion(ajena, { method: 'GET', token: tokenAdmin })).codigo, 200);
  assert.equal((await peticion(apiDb + 'ventas/' + venta.id, {
    method: 'GET', token: tokenVendedor,
  })).codigo, 200);
  console.log('OK: roles, alta, DNI duplicado, catálogo, venta, reintento, stock e historial.');
}

probar().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}).finally(() => deleteApp(app));
