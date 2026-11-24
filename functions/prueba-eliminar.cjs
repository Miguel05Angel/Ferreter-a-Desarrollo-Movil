const assert = require('node:assert/strict');
if (!process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIRESTORE_EMULATOR_HOST) {
  throw Error('Ejecutar solo con emuladores.');
}
const { eliminarUsuario } = require('./index');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const auth = getAuth();
const db = getFirestore();
async function cuenta(dni, rol) {
  const user = await auth.createUser({email:dni+'@acceso.ferreteria.invalid',password:'Prueba123'});
  await db.collection('usuarios').doc(user.uid).set({dni,rol,nombre:'Prueba',telefono:''});
  return user;
}
const session = user => ({uid:user.uid,token:{email:user.email,auth_time:Math.floor(Date.now()/1000)}});
async function rechaza(actor, usuarioId, code) {
  await assert.rejects(eliminarUsuario.run({auth:actor,data:{usuarioId}}), e=>e.code===code);
}
(async () => {
  const admin = await cuenta('30000001','Administrador');
  const seller = await cuenta('30000002','Vendedor');
  const anotherAdmin = await cuenta('30000003','Administrador');
  const actor = session(admin);
  await rechaza(undefined,seller.uid,'unauthenticated');
  await rechaza(session(seller),anotherAdmin.uid,'permission-denied');
  await rechaza(actor,admin.uid,'failed-precondition');
  await rechaza({...actor,token:{...actor.token,auth_time:1}},seller.uid,'failed-precondition');
  await rechaza(actor,'ruta/invalida','invalid-argument');
  await db.collection('ventas').doc('historica').set({vendedorId:seller.uid,total:12});
  await eliminarUsuario.run({auth:actor,data:{usuarioId:seller.uid}});
  await assert.rejects(auth.getUser(seller.uid), e=>e.code==='auth/user-not-found');
  assert.equal((await db.collection('usuarios').doc(seller.uid).get()).exists,false);
  assert.equal((await db.collection('ventas').doc('historica').get()).get('total'),12);
  assert.equal((await eliminarUsuario.run({auth:actor,data:{usuarioId:seller.uid}})).yaEliminado,true);
  await eliminarUsuario.run({auth:actor,data:{usuarioId:anotherAdmin.uid}});
  assert.equal((await db.collection('usuarios').doc(anotherAdmin.uid).get()).exists,false);
  assert.equal((await db.collection('usuarios').doc(admin.uid).get()).get('rol'),'Administrador');
  const parcial = await cuenta('30000004','Vendedor');
  await auth.deleteUser(parcial.uid);
  await eliminarUsuario.run({auth:actor,data:{usuarioId:parcial.uid}});
  assert.equal((await db.collection('usuarios').doc(parcial.uid).get()).exists,false);
  const inconsistente = await cuenta('30000005','Vendedor');
  await auth.updateUser(inconsistente.uid,{email:'otra@acceso.ferreteria.invalid'});
  await rechaza(actor,inconsistente.uid,'failed-precondition');
  assert.equal((await db.collection('usuarios').doc(inconsistente.uid).get()).exists,true);
  console.log('Eliminación: permisos, sesión reciente, bloqueo de cuenta propia, Auth y perfil eliminados, reintentos y ventas conservadas: OK.');
})().catch(e=>{console.error(e);process.exitCode=1;});
