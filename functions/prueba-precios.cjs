const assert = require('node:assert/strict');

const project = 'demo-ferreteria-precios';
const firestore = process.env.FIRESTORE_EMULATOR_HOST;
const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (process.env.GCLOUD_PROJECT !== project ||
    !/^127\.0\.0\.1:\d+$/.test(firestore ?? '') ||
    !/^127\.0\.0\.1:\d+$/.test(auth ?? '')) {
  throw Error('Esta prueba solo puede ejecutarse en los emuladores locales del proyecto demo.');
}

const base = `http://${firestore}/v1/projects/${project}/databases/(default)/documents/`;
let passed = 0;
function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => {
    const encoded = value === null ? {nullValue: null}
      : typeof value === 'string' ? {stringValue: value}
      : typeof value === 'boolean' ? {booleanValue: value}
      : value instanceof Date ? {timestampValue: value.toISOString()}
      : Array.isArray(value) ? {arrayValue: {values: value.map(v => ({integerValue: String(v)}))}}
      : Number.isInteger(value) ? {integerValue: String(value)} : {doubleValue: value};
    return [key, encoded];
  }));
}
async function request(url, {method = 'GET', token, data} = {}) {
  const response = await fetch(url, {
    method,
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
    body: data === undefined ? undefined : JSON.stringify(data),
    signal: AbortSignal.timeout(15000),
  });
  return {status: response.status, body: await response.json()};
}
async function account(dni, role, profileDni = dni) {
  const signup = await request(`http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-api-key`, {
    method: 'POST', data: {email: dni + '@acceso.ferreteria.invalid', password: 'SoloEmulador123', returnSecureToken: true},
  });
  assert.equal(signup.status, 200);
  if (role) {
    const profile = await request(base + 'usuarios/' + signup.body.localId, {
      method: 'PATCH', token: 'owner', data: {fields: fields({dni: profileDni, rol: role, nombre: 'Personal local'})},
    });
    assert.equal(profile.status, 200);
  }
  return signup.body.idToken;
}
async function update(token, changes, deleted = []) {
  const query = new URLSearchParams();
  for (const key of [...Object.keys(changes), ...deleted]) query.append('updateMask.fieldPaths', key);
  return request(base + 'productos/rodillo?' + query, {
    method: 'PATCH', token, data: {fields: fields(changes)},
  });
}
function check(title, result, expected) {
  assert.equal(result.status, expected, `${title}: ${JSON.stringify(result.body.error ?? result.body)}`);
  passed++;
  console.log(`OK ${passed}: ${title}`);
}

(async () => {
  const admin = await account('10000001', 'Administrador');
  const seller = await account('10000002', 'Vendedor');
  const invalid = await account('10000003', 'Administrador', '10000009');
  const unknown = await account('10000004');
  const product = {
    codigo: 'ROD-002', nombre: 'Rodillo para Acabado 9 pulgadas', descripcion: 'Rodillo de prueba',
    categoriaId: 'cat-2', marca: 'Pintor', unidad: 'Unidad', precioVenta: 21.9, precioCompra: 0,
    stock: 10, tipoVisual: 'rodillo', colorHex: 4284513675, coloresHex: [], stockMinimo: 5,
    fuente: 'Catálogo de prueba', urlFuente: '', fechaPrecio: null, calidad: 0,
  };
  const seed = await request(base + 'productos/rodillo', {
    method: 'PATCH', token: 'owner', data: {fields: fields({...product, activo: true, creadoEn: new Date()})},
  });
  assert.equal(seed.status, 200);
  check('Administrador cambia el precio de venta', await update(admin, {precioVenta: 24.9}), 200);
  const read = await request(base + 'productos/rodillo', {token: seller});
  check('Vendedor puede leer el precio actualizado en la misma base', read, 200);
  assert.equal(read.body.fields.precioVenta.doubleValue, 24.9);
  check('Guardado completo del formulario web con merge', await update(admin, {...product, precioVenta: 25.5, precioCompra: 12}), 200);
  check('Vendedor no puede modificar precios', await update(seller, {precioVenta: 1}), 403);
  check('Vendedor conserva permiso para cambiar solo stock', await update(seller, {stock: 8}), 200);
  check('Vendedor no puede guardar stock negativo', await update(seller, {stock: -1}), 403);
  check('Vendedor no puede guardar stock fraccionario', await update(seller, {stock: 1.5}), 403);
  check('Vendedor no puede cambiar la visibilidad', await update(seller, {activo: false}), 403);
  check('Sin sesión no se pueden editar precios', await update(null, {precioVenta: 1}), 403);
  check('Perfil con DNI que no coincide no puede editar', await update(invalid, {precioVenta: 1}), 403);
  check('Cuenta sin perfil no puede editar', await update(unknown, {precioVenta: 1}), 403);
  check('Administrador puede desactivar un producto', await update(admin, {activo: false}), 200);
  check('Administrador puede mover a papelera', await update(admin, {activo: false, eliminadoEn: new Date()}), 200);
  check('Administrador puede restaurar', await update(admin, {activo: true}, ['eliminadoEn']), 200);
  check('Vendedor no puede crear productos', await request(base + 'productos/nuevo', {
    method: 'PATCH', token: seller, data: {fields: fields(product)},
  }), 403);
  check('Administrador puede crear productos', await request(base + 'productos/nuevo', {
    method: 'PATCH', token: admin, data: {fields: fields(product)},
  }), 200);
  check('Vendedor no puede eliminar productos', await request(base + 'productos/nuevo', {method: 'DELETE', token: seller}), 403);
  check('Administrador puede eliminar productos', await request(base + 'productos/nuevo', {method: 'DELETE', token: admin}), 200);
  check('Sin sesión no se puede leer el catálogo', await request(base + 'productos/rodillo'), 403);
  const final = await request(base + 'productos/rodillo', {token: admin});
  assert.equal(final.body.fields.precioVenta.doubleValue, 25.5);
  assert.equal(final.body.fields.stock.integerValue, '8');
  assert.equal(final.body.fields.activo.booleanValue, true);
  assert.equal(final.body.fields.eliminadoEn, undefined);
  assert.ok(final.body.fields.creadoEn.timestampValue, 'El merge debe conservar la fecha original.');
  console.log(`${passed} pruebas satisfactorias, sin cambios en los datos reales.`);
})().catch(error => {console.error(error.message); process.exitCode = 1;});
