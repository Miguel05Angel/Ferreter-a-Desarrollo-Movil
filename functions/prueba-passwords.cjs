const assert = require('node:assert/strict');
if (!process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIRESTORE_EMULATOR_HOST) {
  throw Error('Ejecutar solo con emuladores.');
}
const { restablecerPasswordUsuario } = require('./index');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const auth = getAuth();
const db = getFirestore();
const host = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:`;
const anterior = 'PruebaInicial123';
const nueva = 'PruebaNueva456';
async function cuenta(dni, rol) {
  const user = await auth.createUser({email: dni + '@acceso.ferreteria.invalid', password: anterior});
  await db.collection('usuarios').doc(user.uid).set({dni, rol, nombre: 'Prueba local', telefono: ''});
  return user;
}
async function login(user, password) {
  const response = await fetch(host + 'signInWithPassword?key=demo', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email:user.email,password,returnSecureToken:true}),
  });
  return {status:response.status, body:await response.json()};
}
async function sesion(user) {
  const result = await login(user, anterior);
  assert.equal(result.status, 200);
  return {uid:user.uid, token:await auth.verifyIdToken(result.body.idToken)};
}
async function rechaza(authContext, data, code) {
  await assert.rejects(restablecerPasswordUsuario.run({auth:authContext, data}),
    error => error.code === code);
}
(async () => {
  const admin = await cuenta('20000001', 'Administrador');
  const seller = await cuenta('20000002', 'Vendedor');
  const secondAdmin = await cuenta('20000003', 'Administrador');
  const adminSession = await sesion(admin);
  const sellerSession = await sesion(seller);
  const data = {usuarioId:seller.uid, nuevaPassword:nueva};
  await rechaza(undefined, data, 'unauthenticated');
  await rechaza(sellerSession, data, 'permission-denied');
  await rechaza({...adminSession, token:{...adminSession.token, auth_time:Math.floor(Date.now()/1000)-600}}, data, 'failed-precondition');
  await rechaza(adminSession, {...data, nuevaPassword:'abc'}, 'invalid-argument');
  await rechaza(adminSession, {...data, nuevaPassword:'letrassinnumero'}, 'invalid-argument');
  await rechaza(adminSession, {...data, usuarioId:admin.uid}, 'invalid-argument');
  await rechaza(adminSession, {...data, usuarioId:'no-existe'}, 'not-found');
  await rechaza({...adminSession, token:{...adminSession.token,email:'otra@acceso.ferreteria.invalid'}}, data, 'permission-denied');
  assert.equal((await login(seller, anterior)).status, 200);
  assert.deepEqual(await restablecerPasswordUsuario.run({auth:adminSession,data}), {usuarioId:seller.uid});
  assert.notEqual((await login(seller, anterior)).status, 200);
  assert.equal((await login(seller, nueva)).status, 200);
  await restablecerPasswordUsuario.run({auth:adminSession,
    data:{...data,usuarioId:secondAdmin.uid}});
  assert.equal((await login(secondAdmin, nueva)).status, 200);
  const stored = (await db.collection('usuarios').doc(seller.uid).get()).data();
  assert.deepEqual(Object.keys(stored).sort(), ['dni','nombre','rol','telefono']);
  assert.equal(stored.rol, 'Vendedor');
  await db.collection('usuarios').doc(admin.uid).update({rol:'Vendedor'});
  await rechaza(adminSession, data, 'permission-denied');
  console.log('Contraseñas: permisos, sesión reciente, validación, acceso con nueva clave y perfil sin contraseñas: OK.');
})().catch(error => {console.error(error); process.exitCode=1;});
