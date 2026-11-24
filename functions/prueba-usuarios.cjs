const assert = require('node:assert/strict');
const { FIREBASE_AUTH_EMULATOR_HOST: authHost, FIRESTORE_EMULATOR_HOST: dbHost } = process.env;
if (!authHost || !dbHost) throw Error('Usa firebase emulators:exec.');
const db = `http://${dbHost}/v1/projects/demo-ferreteria/databases/(default)/documents/usuarios/`;
const fields = (data) => Object.fromEntries(
  Object.entries(data).map(([key, value]) => [key, { stringValue: value }]),
);
async function request(url, method, token, body) {
  const response = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, body: await response.json() };
}
async function user(dni, rol) {
  const result = await request(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`,
    'POST', null, {email: `${dni}@acceso.ferreteria.invalid`,
      password: 'Prueba123', returnSecureToken: true},
  );
  assert.equal(result.status, 200, JSON.stringify(result.body));
  const { localId: uid, idToken: token } = result.body;
  const seeded = await request(db + uid, 'PATCH', 'owner', {
    fields: fields({ dni, rol, nombre: 'Usuario prueba', telefono: '' }),
  });
  assert.equal(seeded.status, 200, JSON.stringify(seeded.body));
  return {uid, token};
}
async function patch(uid, token, data, expected) {
  const query = new URLSearchParams();
  for (const key of Object.keys(data)) query.append('updateMask.fieldPaths', key);
  const response = await request(db + uid + '?' + query, 'PATCH', token,
    { fields: fields(data) });
  assert.equal(response.status, expected, JSON.stringify(response.body));
}
(async () => {
  const admin = await user('10000001', 'Administrador');
  const seller = await user('10000002', 'Vendedor');
  const other = await user('10000003', 'Vendedor');
  await patch(seller.uid, admin.token, {nombre: 'Nombre actualizado', telefono: '912345678'}, 200);
  await patch(admin.uid, admin.token, {nombre: 'Admin actualizado', telefono: ''}, 200);
  await patch(other.uid, seller.token, {nombre: 'No autorizado'}, 403);
  await patch(seller.uid, seller.token, {telefono: '923456789'}, 403);
  await patch(seller.uid, null, {nombre: 'Sin sesion'}, 403);
  await patch(seller.uid, admin.token, {rol: 'Administrador'}, 403);
  await patch(seller.uid, admin.token, {dni: '10000004'}, 403);
  await patch(seller.uid, admin.token, {nombre: 'AB'}, 403);
  await patch(seller.uid, admin.token, {telefono: '123'}, 403);
  await patch(seller.uid, seller.token, {nombre: 'Mi propio perfil'}, 200);
  const profile = await request(db + seller.uid, 'GET', admin.token);
  assert.equal(profile.body.fields.rol.stringValue, 'Vendedor');
  assert.equal(profile.body.fields.dni.stringValue, '10000002');
  console.log('10 comprobaciones de permisos aprobadas; DNI y rol conservados.');
})().catch((error) => { console.error(error); process.exitCode = 1; });
