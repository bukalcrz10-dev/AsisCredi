import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  Bytes, serverTimestamp, Timestamp, collection, deleteDoc, doc, getDoc, getDocs, query,
  setDoc, setLogLevel, updateDoc, where, writeBatch,
} from 'firebase/firestore';

// Nunca usar el proyecto real: todas las operaciones (incluido el borrado de
// fixtures) apuntan exclusivamente a este proyecto demo en loopback.
const projectId = 'demo-asiscredi-reglas';
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (host !== '127.0.0.1:8185') {
  throw new Error('Ejecuta con el emulador local 127.0.0.1:8185 y el proyecto demo.');
}
let env;
setLogLevel('silent');
const viernes = '2026-10-09';
const sabado = '2026-10-10';
const domingo = '2026-10-11';
const uids = { asesor: 'asesor-prueba', plataforma: 'plataforma-prueba' };
const db = (uid = uids.plataforma) => env.authenticatedContext(uid).firestore();
const fecha = (dia, hora) => Timestamp.fromDate(new Date(`${dia}T${hora}-05:00`));

function marca({ horario = 'plataforma', uid = uids[horario], dia = viernes,
  hora = '08:30:00', bloque = 'manana', tipo = 'entrada', cambios = {} } = {}) {
  return {
    usuarioId: uid, nombreUsuario: 'Persona de prueba', sedeId: 'huancayo',
    tipoMarcacion: tipo, tipoHorario: horario, bloqueJornada: bloque,
    fechaHora: fecha(dia, hora), latitud: -12.06, longitud: -75.21,
    dentroDeZona: true, rostroValidado: true,
    observacion: 'Marcacion generada desde la pantalla del trabajador.',
    correoNotificacion: 'prueba@example.invalid', urlEvidenciaFacial: null,
    notificacionEnviada: false, enlaceMapa: 'https://maps.google.com/?q=-12.06,-75.21',
    ...cambios,
  };
}
function idMarca(m) {
  const local = new Date(m.fechaHora.toMillis() - 5 * 3600000);
  const dia = local.toISOString().slice(0, 10).replaceAll('-', '');
  // Igual que Dart base64Url.encode: conserva padding y usa alfabeto URL-safe.
  const uid = Buffer.from(m.usuarioId).toString('base64').replaceAll('+', '-').replaceAll('/', '_');
  return `marcacion_${uid}_${dia}_${m.bloqueJornada}_${m.tipoMarcacion}`;
}
const tokenDe = uid => createHash('sha256').update(uid).digest('hex');
const guardar = (m, conexion = db(m.usuarioId), id = idMarca(m)) => {
  const batch = writeBatch(conexion);
  batch.set(doc(conexion, 'credencialesBiometricas', tokenDe(m.usuarioId ?? uids.plataforma), 'comprobantes', id),
    { usuarioId: m.usuarioId ?? uids.plataforma, creadoEn: serverTimestamp(), modeloFacial: 'sface-2021dec-v1', similitud: .8, parpadeos: 2 });
  batch.set(doc(conexion, 'asistencias', id), m);
  return batch.commit();
};
async function seed(path, data) {
  await env.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), path), data));
}
async function autorizarFixture(uid, token = tokenDe(uid), version = 1) {
  await seed(`configuracionBiometrica/${uid}`, {version, estado: 'activo', permitirEnrolamiento: false});
  await seed(`vinculosBiometricosPrivados/${uid}`, {version, token});
  await seed(`credencialesBiometricas/${token}`, {usuarioId: uid, version, estado: 'aprobado', modeloFacial: 'sface-2021dec-v1'});
}
async function previa(opciones = {}) {
  const m = marca(opciones);
  await seed(`asistencias/${idMarca(m)}`, m);
  return m;
}
before(async () => {
  env = await initializeTestEnvironment({
    projectId, firestore: { host: '127.0.0.1', port: 8185,
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c => {
    const batch = writeBatch(c.firestore());
    for (const [horario, uid] of Object.entries(uids)) {
      batch.set(doc(c.firestore(), 'configuracionBiometrica', uid),
        {version: 1, estado: 'activo', permitirEnrolamiento: false});
      batch.set(doc(c.firestore(), 'vinculosBiometricosPrivados', uid),
        {version: 1, token: tokenDe(uid)});
      batch.set(doc(c.firestore(), 'credencialesBiometricas', tokenDe(uid)),
        {usuarioId: uid, estado: 'aprobado', version: 1, modeloFacial: 'sface-2021dec-v1'});
      batch.set(doc(c.firestore(), 'usuarios', uid), {
        activo: true, rol: 'trabajador', cargo: horario, sedeAsignadaId: 'huancayo',
      });
    }
    batch.set(doc(c.firestore(), 'usuarios', 'admin'), { activo: true, rol: 'administrador' });
    batch.set(doc(c.firestore(), 'sedes', 'huancayo'), { nombre: 'Huancayo' });
    batch.set(doc(c.firestore(), 'sedes', 'satipo'), { nombre: 'Satipo' });
    await batch.commit();
  });
});
after(async () => { await env?.cleanup(); });

test('rechaza acceso anónimo, perfil inexistente y trabajador inactivo', async () => {
  await assertFails(guardar(marca(), env.unauthenticatedContext().firestore()));
  await assertFails(guardar(marca({ uid: 'sin-perfil' })));
  await seed(`usuarios/${uids.plataforma}`, { activo: false, rol: 'trabajador' });
  await assertFails(guardar(marca()));
  await assertSucceeds(getDoc(doc(db(), 'usuarios', uids.plataforma)));
});
test('impide escribir a nombre de otra persona y elevar privilegios', async () => {
  await assertFails(guardar(marca({ horario: 'asesor' }), db()));
  await assertFails(updateDoc(doc(db(), 'usuarios', uids.plataforma), { rol: 'administrador' }));
  await assertFails(setDoc(doc(db(), 'sedes', 'nueva'), { nombre: 'Otra' }));
});
test('Auxiliar de operaciones conserva el horario de Plataforma', async () => {
  await seed(`usuarios/${uids.plataforma}`, {
    activo: true, rol: 'trabajador', cargo: 'Auxiliar de operaciones',
    sedeAsignadaId: 'huancayo',
  });
  await assertSucceeds(guardar(marca({ horario: 'plataforma' })));
  await assertFails(guardar(marca({
    horario: 'asesor', uid: uids.plataforma, dia: '2026-10-13',
  })));
});
test('lectura propia e historial filtrado permitidos; otros usuarios y consulta global no', async () => {
  const m = await previa();
  await assertSucceeds(getDoc(doc(db(), 'asistencias', idMarca(m))));
  await assertSucceeds(getDocs(query(collection(db(), 'asistencias'), where('usuarioId', '==', uids.plataforma))));
  await assertFails(getDoc(doc(db(uids.asesor), 'asistencias', idMarca(m))));
  await assertFails(getDocs(collection(db(), 'asistencias')));
  await assertSucceeds(getDocs(collection(db('admin'), 'asistencias')));
});
test('las dos colecciones retiradas rechazan lectura y escritura incluso del administrador', async () => {
 for (const coleccion of ['auditoriaRegularizaciones', 'auditoriaAdministrativa']) {
   for (const conexion of [db('admin'), db()]) {
     const ref = doc(conexion, coleccion, 'no-recrear');
     await assertFails(setDoc(ref, {creadoEn: serverTimestamp()}));
     await assertFails(getDoc(ref));
     await assertFails(getDocs(collection(conexion, coleccion)));
   }
 }
});

test('rechaza duplicado con mismo ID, con ID alternativo y eliminación del trabajador', async () => {
  const m = marca();
  await assertSucceeds(guardar(m));
  await assertFails(guardar(m));
  await assertFails(guardar(m, db(), 'id-alternativo'));
  await assertFails(deleteDoc(doc(db(), 'asistencias', idMarca(m))));
});
test('dos dispositivos simultáneos solo pueden crear una vez', async () => {
  const m = marca();
  const results = await Promise.allSettled([guardar(m, db()), guardar(m, db())]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.filter(r => r.status === 'rejected' && r.reason.code === 'permission-denied').length, 1);
});
for (const uid of ['a', 'ab', 'abc', 'trabajador-ñ', 'uid_?']) {
  test(`conserva ID base64Url de Dart con UID ${uid}`, async () => {
    await seed(`usuarios/${uid}`, { activo: true, rol: 'trabajador', cargo: 'asesor', sedeAsignadaId: 'huancayo' });
    await autorizarFixture(uid);
    await assertSucceeds(guardar(marca({ horario: 'asesor', uid })));
  });
}
for (const horario of ['asesor', 'plataforma']) {
  for (const dia of ['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15', '2026-10-16']) {
    test(`${horario}: día laborable ${dia}`, async () => {
      await assertSucceeds(guardar(marca({ horario, dia })));
    });
  }
  test(`${horario}: domingo rechaza entrada y salida`, async () => {
    await assertFails(guardar(marca({ horario, dia: domingo })));
    await previa({ horario, dia: domingo });
    await assertFails(guardar(marca({ horario, dia: domingo, tipo: 'salida', hora: '15:00:00' })));
    await assertFails(guardar(marca({ horario, dia: domingo, tipo: 'salida', hora: '18:30:00' })));
  });
  test(`${horario}: jornada completa válida`, async () => {
    const eventos = horario === 'asesor'
      ? [['08:30:00', 'manana', 'entrada'], ['18:30:00', 'manana', 'salida']]
      : [['08:30:00', 'manana', 'entrada'], ['13:00:00', 'manana', 'salida'],
        ['15:00:00', 'tarde', 'entrada'], ['18:30:00', 'tarde', 'salida']];
    for (const [hora, bloque, tipo] of eventos) {
      await assertSucceeds(guardar(marca({ horario, hora, bloque, tipo })));
    }
  });
  test(`${horario}: sábado continuo y domingo sin marcaciones`, async () => {
    await assertSucceeds(guardar(marca({ horario, dia: sabado })));
    await assertSucceeds(guardar(marca({ horario, dia: sabado, hora: '15:00:00', tipo: 'salida' })));
    await assertFails(guardar(marca({ horario, dia: sabado, hora: '15:10:00', bloque: 'tarde' })));
    await assertFails(guardar(marca({ horario, dia: domingo })));
  });
  test(`${horario}: salida sin entrada no permitida`, async () => {
    await assertFails(guardar(marca({ horario, tipo: 'salida', hora: '18:30:00',
      bloque: horario === 'asesor' ? 'manana' : 'tarde' })));
  });
}

// Límites inclusivos por minuto: prueba el segundo anterior y los segundos
// inicial/final del rango. Las marcas previas se crean solo como fixtures.
const ventanas = [
  ['asesor', viernes, 'manana', 'entrada', '07:59:59', '08:00:00', '18:19:59', '18:20:00'],
  ['asesor', viernes, 'manana', 'salida', '18:29:59', '18:30:00', '19:30:59', '19:31:00'],
  ['plataforma', viernes, 'manana', 'entrada', '07:59:59', '08:00:00', '12:59:59', '13:00:00'],
  ['plataforma', viernes, 'manana', 'salida', '12:59:59', '13:00:00', '14:59:59', '15:00:00'],
  ['plataforma', viernes, 'tarde', 'entrada', '14:49:59', '14:50:00', '18:19:59', '18:20:00'],
  ['plataforma', viernes, 'tarde', 'salida', '18:29:59', '18:30:00', '19:30:59', '19:31:00'],
  ...['asesor', 'plataforma'].flatMap(h => [
    [h, sabado, 'manana', 'entrada', '07:59:59', '08:00:00', '14:59:59', '15:00:00'],
    [h, sabado, 'manana', 'salida', '14:59:59', '15:00:00', '16:00:59', '16:01:00'],
  ]),
];
for (const [horario, dia, bloque, tipo, ...horas] of ventanas) {
  for (const [i, hora] of horas.entries()) {
    test(`${horario} ${dia} ${bloque} ${tipo} ${hora}: ${i === 0 || i === 3 ? 'rechaza' : 'permite'}`, async () => {
      if (tipo === 'salida') await previa({ horario, dia, bloque, hora: bloque === 'tarde' ? '15:00:00' : '08:30:00' });
      const result = guardar(marca({ horario, dia, bloque, tipo, hora }));
      await (i === 0 || i === 3 ? assertFails(result) : assertSucceeds(result));
    });
  }
}
test('Plataforma permite tarde sin marcas de mañana, pero exige cerrar la mañana iniciada', async () => {
  const tarde = marca({ bloque: 'tarde', hora: '15:00:00' });
  await previa();
  await assertFails(guardar(tarde));
  await previa({ tipo: 'salida', hora: '13:00:00' });
  await assertSucceeds(guardar(tarde));
});
test('entrada tarde no puede preceder a salida de mañana', async () => {
  await previa();
  await previa({ tipo: 'salida', hora: '14:59:00' });
  await assertFails(guardar(marca({ bloque: 'tarde', hora: '14:50:00' })));
});
test('salida no puede preceder a entrada regularizada', async () => {
  await previa({ horario: 'asesor', hora: '19:00:00' });
  await assertFails(guardar(marca({ horario: 'asesor', tipo: 'salida', hora: '18:30:00' })));
});
test('entrada no permitida si existe una salida sin entrada', async () => {
  await previa({ tipo: 'salida', hora: '13:00:00' });
  await assertFails(guardar(marca()));
});
test('conserva horario de una jornada iniciada aunque cambie el cargo', async () => {
  await assertSucceeds(guardar(marca()));
  await seed(`usuarios/${uids.plataforma}`, { activo: true, rol: 'trabajador', cargo: 'asesor', sedeAsignadaId: 'huancayo' });
  await assertSucceeds(guardar(marca({ tipo: 'salida', hora: '13:00:00' })));
  await assertSucceeds(guardar(marca({ bloque: 'tarde', hora: '15:00:00' })));
  await assertFails(guardar(marca({ horario: 'asesor', uid: uids.plataforma, tipo: 'salida', hora: '18:30:00' })));
});
test('cargo sin horario, horario ajeno e histórico autoseleccionado rechazados', async () => {
  await assertFails(guardar(marca({ cambios: { tipoHorario: 'asesor' } })));
  await assertFails(guardar(marca({ cambios: { tipoHorario: 'historico' } })));
  await seed(`usuarios/${uids.plataforma}`, { activo: true, rol: 'trabajador', cargo: 'otro', sedeAsignadaId: 'huancayo' });
  await assertFails(guardar(marca()));
});
test('normaliza cargo asesora, mayúsculas y espacios como la app', async () => {
  await seed(`usuarios/${uids.asesor}`, { activo: true, rol: 'trabajador', cargo: ' ASESORA ', sedeAsignadaId: 'huancayo' });
  await assertSucceeds(guardar(marca({ horario: 'asesor' })));
});
test('sede asignada vigente: rechaza otra sede y permite Satipo después del cambio', async () => {
  await assertFails(guardar(marca({ cambios: { sedeId: 'satipo' } })));
  await seed(`usuarios/${uids.plataforma}`, { activo: true, rol: 'trabajador', cargo: 'plataforma', sedeAsignadaId: 'satipo' });
  await assertFails(guardar(marca()));
  await assertSucceeds(guardar(marca({ cambios: { sedeId: 'satipo' } })));
});
test('rechaza sede asignada inexistente', async () => {
  await seed(`usuarios/${uids.plataforma}`, { activo: true, rol: 'trabajador', cargo: 'plataforma', sedeAsignadaId: 'inexistente' });
  await assertFails(guardar(marca({ cambios: { sedeId: 'inexistente' } })));
});
for (const existente of ['sede-principal', 'sede_principal']) {
  test(`compatibilidad de sede principal con ${existente}`, async () => {
    await seed(`sedes/${existente}`, { nombre: 'Principal' });
    await seed(`usuarios/${uids.plataforma}`, { activo: true, rol: 'trabajador', cargo: 'plataforma', sedeAsignadaId: ' sede-principal ' });
    await assertSucceeds(guardar(marca({ cambios: { sedeId: existente } })));
  });
}
for (const [campo, valor] of [
  ['fechaHora', '2026-10-09'], ['latitud', 91], ['longitud', -181], ['latitud', '0'],
  ['tipoMarcacion', 'otro'], ['tipoHorario', 'otro'], ['bloqueJornada', 'otro'],
  ['dentroDeZona', false], ['rostroValidado', false], ['rostroValidado', 'true'],
  ['notificacionEnviada', true], ['observacion', {}], ['correoNotificacion', 1],
  ['urlEvidenciaFacial', []], ['nombreUsuario', ''], ['campoExtra', true],
]) {
  test(`rechaza dato inválido ${campo}=${JSON.stringify(valor)}`, async () => {
    const m = marca();
    const id = idMarca(m);
    await assertFails(guardar({ ...m, [campo]: valor }, db(), id));
  });
}
test('rechaza ausencia de campos obligatorios', async () => {
  for (const campo of ['usuarioId', 'tipoHorario', 'bloqueJornada', 'fechaHora', 'sedeId', 'latitud', 'rostroValidado']) {
    const m = marca();
    const id = idMarca(m);
    delete m[campo];
    await assertFails(guardar(m, db(), id));
  }
});
test('administrador conserva regularización histórica sin auditorías ni falsificar GPS o rostro', async () => {
 const m = marca({dia:'2020-01-01', cambios:{dentroDeZona:false,rostroValidado:false}});
 const conexion=db('admin'), ref=doc(conexion,'asistencias','id-antiguo');
 await assertSucceeds(setDoc(ref,m));
 await assertSucceeds(updateDoc(ref,{fechaHora:fecha('2020-01-01','09:00:00'),observacion:'Motivo: Corrección manual'}));
 await assertFails(updateDoc(ref,{usuarioId:uids.asesor}));
 await assertFails(updateDoc(ref,{sedeId:'otra'}));
 await assertFails(updateDoc(ref,{dentroDeZona:true}));
 await assertFails(updateDoc(ref,{rostroValidado:true}));
 await assertFails(updateDoc(ref,{fechaHora:'09:00'}));
 await assertFails(updateDoc(ref,{observacion:123}));
 await assertFails(deleteDoc(ref));
});

test('la regularización administrativa rechaza datos incompletos o campos ajenos', async () => {
 const conexion=db('admin'); const m=marca();
 await assertFails(setDoc(doc(conexion,'asistencias','incompleta'),{usuarioId:uids.plataforma}));
 await assertFails(setDoc(doc(conexion,'asistencias','campo-extra'),{...m,ultimaAuditoriaId:'retirado'}));
 await assertFails(setDoc(doc(conexion,'asistencias','gps-invalido'),{...m,latitud:91}));
 await assertFails(setDoc(doc(conexion,'asistencias','tipo-invalido'),{...m,fechaHora:'08:30'}));
});

test('cuatro correcciones se confirman en lote sin auditoría y conservan identidad GPS y horario', async () => {
 const conexion=db('admin');
 const valores=[marca(),marca({tipo:'salida',hora:'13:00:00'}),marca({bloque:'tarde',hora:'15:00:00'}),marca({bloque:'tarde',tipo:'salida',hora:'18:30:00'})];
 for(const m of valores)await seed('asistencias/'+idMarca(m),m);
 const escribir=extra=>{const batch=writeBatch(conexion);for(const m of valores)batch.update(doc(conexion,'asistencias',idMarca(m)),{observacion:'Motivo: Corrección con sustento',...extra});return batch.commit();};
 for(const extra of [{dentroDeZona:false},{usuarioId:uids.asesor},{sedeId:'otra'},{tipoHorario:'asesor'},{bloqueJornada:'otro'}])await assertFails(escribir(extra));
 await assertSucceeds(escribir({}));
 await assertFails(updateDoc(doc(db(),'asistencias',idMarca(valores[0])),{observacion:'No autorizado'}));
});

test('administrador inactivo no puede regularizar', async () => {
  await seed('usuarios/admin', { activo: false, rol: 'administrador' });
  await assertFails(guardar(marca(), db('admin')));
});
test('salida posterior a entrada regularizada con ID canónico y validaciones falsas', async () => {
  await previa({ cambios: { dentroDeZona: false, rostroValidado: false } });
  await assertSucceeds(guardar(marca({ tipo: 'salida', hora: '13:00:00' })));
});
test('conserva calendario anterior a la vigencia semanal', async () => {
  await assertSucceeds(guardar(marca({ dia: '2026-10-04' })));
  await assertSucceeds(guardar(marca({ dia: '2026-10-04', tipo: 'salida', hora: '13:00:00' })));
});
test('horario histórico solo puede continuarse desde una marca ya guardada', async () => {
  await previa({ cambios: { tipoHorario: 'historico' } });
  await assertSucceeds(guardar(marca({ tipo: 'salida', hora: '13:00:00', cambios: { tipoHorario: 'historico' } })));
});
test('la fecha del ID debe coincidir con la fecha declarada en Perú', async () => {
  const m = marca();
  await assertFails(guardar(m, db(), idMarca(m).replace('20261009', '20261010')));
});
test('no sustituye hora del dispositivo por hora de servidor', async () => {
  await assertSucceeds(guardar(marca({ dia: '2026-11-02' })));
});
test('la colección alertas retirada no permite lectura ni recreación', async () => {
 for(const conexion of [db(),db('admin')]){
   const ref=doc(conexion,'alertas','retirada');
   await assertFails(setDoc(ref,{usuarioId:uids.plataforma,atendida:false}));
   await assertFails(getDoc(ref));
   await assertFails(getDocs(collection(conexion,'alertas')));
 }
});

test('compatibilidad pendiente: entrada con ID antiguo no demuestra secuencia canónica', async () => {
  // Caso documentado que impide publicar durante una jornada con IDs antiguos:
  // no se abre una excepción insegura que permita falsificar la entrada previa.
  await seed('asistencias/id-anterior-aleatorio', marca());
  await assertFails(guardar(marca({ tipo: 'salida', hora: '13:00:00' })));
  await assertSucceeds(getDoc(doc(db(), 'asistencias', 'id-anterior-aleatorio')));
});


// Integración biométrica: todas estas operaciones apuntan al emulador demo.
const uidBio = uids.plataforma;
const tokenNuevo = 'a'.repeat(64);
function solicitud(cambios = {}) {
  return {usuarioId: uidBio, version: 2, estado: 'pendiente', modeloFacial: 'sface-2021dec-v1',
    vector: Bytes.fromUint8Array(new Uint8Array(Float64Array.from({length: 128}, (_, i) => i === 0 ? 1 : 0).buffer)), modeloCelular: 'Equipo de prueba',
    codigo: tokenNuevo.slice(-6), consentimiento: true, creadoEn: serverTimestamp(), ...cambios};
}
async function habilitarBio() {
  await setDoc(doc(db('admin'), 'configuracionBiometrica', uidBio),
    {version: 2, estado: 'pendiente', permitirEnrolamiento: true});
}
function guardarBio({token = tokenDe(uidBio), prueba = {}, m = marca(), soloPrueba = false} = {}) {
  const conexion = db();
  const batch = writeBatch(conexion);
  batch.set(doc(conexion, 'credencialesBiometricas', token, 'comprobantes', idMarca(m)), {
    usuarioId: uidBio, creadoEn: serverTimestamp(), modeloFacial: 'sface-2021dec-v1',
    similitud: .75, parpadeos: 2, ...prueba,
  });
  if (!soloPrueba) batch.set(doc(conexion, 'asistencias', idMarca(m)), m);
  return batch.commit();
}
test('biometría: no permite marcar sin comprobante del celular autorizado', async () => {
  const m = marca();
  await assertFails(setDoc(doc(db(), 'asistencias', idMarca(m)), m));
  await assertSucceeds(guardarBio());
});
test('biometría: no permite comprobante aislado sin asistencia', async () => {
  await assertFails(guardarBio({soloPrueba: true}));
});
test('biometría: otro celular y un token de otro trabajador no pueden marcar', async () => {
  await assertFails(guardarBio({token: tokenNuevo}));
  await assertFails(guardarBio({token: tokenDe(uids.asesor)}));
});
for (const prueba of [{similitud: .519}, {similitud: 1.01}, {similitud: '0.9'},
    {parpadeos: 1}, {usuarioId: uids.asesor}, {modeloFacial: 'otro'},
    {creadoEn: fecha(viernes, '08:30:00')}, {extra: true}]) {
  test(`biometría: comprobante inválido ${JSON.stringify(prueba)}`, async () => {
    await assertFails(guardarBio({prueba}));
  });
}
test('biometría: umbral exacto aceptado y comprobante no se puede reutilizar', async () => {
  await assertSucceeds(guardarBio({prueba: {similitud: .52}}));
  await assertFails(guardarBio());
  const p = doc(db(), 'credencialesBiometricas', tokenDe(uidBio), 'comprobantes', idMarca(marca()));
  await assertFails(updateDoc(p, {creadoEn: serverTimestamp()}));
  await assertFails(deleteDoc(p));
});
test('biometría: autorización privada y lista de rostros inaccesibles al trabajador', async () => {
  await assertFails(getDoc(doc(db(), 'vinculosBiometricosPrivados', uidBio)));
  await assertFails(getDocs(query(collection(db(), 'credencialesBiometricas'), where('usuarioId', '==', uidBio))));
  await assertSucceeds(getDoc(doc(db(), 'credencialesBiometricas', tokenDe(uidBio))));
  await assertFails(getDoc(doc(db(), 'credencialesBiometricas', tokenDe(uids.asesor))));
  await assertSucceeds(getDocs(collection(db('admin'), 'credencialesBiometricas')));
});
test('biometría: no permite autoautorizarse, reemplazar el vínculo ni cambiar referencia aprobada', async () => {
  await assertFails(updateDoc(doc(db(), 'configuracionBiometrica', uidBio), {permitirEnrolamiento: true}));
  await assertFails(setDoc(doc(db(), 'vinculosBiometricosPrivados', uidBio), {token: tokenNuevo, version: 1}));
  await assertFails(updateDoc(doc(db(), 'credencialesBiometricas', tokenDe(uidBio)), {vector: Array(128).fill(1)}));
  await assertFails(setDoc(doc(db(), 'credencialesBiometricas', tokenNuevo), solicitud()));
});
for (const cambios of [{estado: 'aprobado'}, {version: 1}, {usuarioId: uids.asesor},
    {vector: [1, 2]}, {vector: Array(128).fill('1')}, {consentimiento: false},
    {creadoEn: fecha(viernes, '08:30:00')}, {modeloFacial: 'otro'}, {codigo: 'bbbbbb'}]) {
  test(`biometría: rechaza solicitud inválida ${JSON.stringify(cambios).slice(0, 80)}`, async () => {
    await habilitarBio();
    await assertFails(setDoc(doc(db(), 'credencialesBiometricas', tokenNuevo), solicitud(cambios)));
  });
}
test('biometría: habilitar, solicitar, aprobar y marcar con nuevo celular', async () => {
  await habilitarBio();
  const ref = doc(db(), 'credencialesBiometricas', tokenNuevo);
  await assertSucceeds(setDoc(ref, solicitud()));
  await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref, {estado: 'aprobado'}));
  await assertFails(guardarBio({token: tokenNuevo}));
  const admin = db('admin');
  const batch = writeBatch(admin);
  batch.update(doc(admin, 'credencialesBiometricas', tokenNuevo), {estado: 'aprobado', aprobadoEn: serverTimestamp()});
  batch.set(doc(admin, 'vinculosBiometricosPrivados', uidBio), {token: tokenNuevo, version: 2});
  batch.update(doc(admin, 'configuracionBiometrica', uidBio), {estado: 'activo', permitirEnrolamiento: false});
  await assertSucceeds(batch.commit());
  await assertFails(guardarBio()); // El token anterior ya no sirve.
  await assertSucceeds(guardarBio({token: tokenNuevo}));
  await assertFails(setDoc(ref, solicitud()));
});
test('biometría: revocar bloquea acceso y marcación, conserva historial', async () => {
  const m = await previa();
  await setDoc(doc(db('admin'), 'configuracionBiometrica', uidBio),
    {version: 2, estado: 'revocado', permitirEnrolamiento: false});
  await assertFails(getDoc(doc(db(), 'credencialesBiometricas', tokenDe(uidBio))));
  await assertFails(guardarBio({m: marca({tipo: 'salida', hora: '13:00:00'})}));
  await assertSucceeds(getDoc(doc(db(), 'asistencias', idMarca(m))));
});
