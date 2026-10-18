# Retiro de las auditorías — 17 de octubre de 2026

El usuario solicitó retirar de Firebase las dos auditorías, después de quitar
su pantalla del panel. `alertas` es independiente y se conserva.

Nota posterior: el usuario solicitó después retirar también el almacenamiento
de alertas. Esa tarea se documenta en [retiro de alertas](retiro_alertas_2026-10-17.md).

## Cambios

- Se retiraron las escrituras a `auditoriaAdministrativa` en altas/ediciones
  de trabajadores, guardado de sedes y autorizaciones de rostro/celular.
- Se retiraron `auditoriaRegularizaciones`, la referencia `ultimaAuditoriaId`
  de las nuevas correcciones y el módulo de auditoría que ya no tenía ruta.
- Se conservan las transacciones de corrección: se leen y comparan las marcas
  originales antes de escribir y se cancela todo ante un conflicto.
- El motivo de una corrección sigue siendo obligatorio, de 1 a 500 caracteres,
  y queda en `observacion` de la asistencia modificada. No crea otra colección.
- Las comprobaciones de sesión, administrador activo y prohibición de cambiar
  el propio acceso continúan vigentes.
- Las reglas permiten crear marcas manuales válidas a un administrador activo.
  Para marcas existentes solo permiten modificar `fechaHora` y `observacion`.
  No permiten alterar identidad, sede, horario, bloque, ubicación o validación
  facial de una marca existente ni eliminar asistencias.
- Las reglas de los trabajadores y la vinculación biométrica no cambian. Las
  dos colecciones retiradas quedan sin permisos de cliente y no pueden ser
  recreadas por una pestaña antigua. Esa pestaña debe recargarse para guardar
  operaciones administrativas con la nueva versión.

## Respaldo y operación remota

La copia privada está en
`respaldos_locales/firebase/2026-10-17/retiro_auditoria/`, excluida de Git:

- `codigo-antes/`: archivos anteriores, con extensión `.dart.bak` para no
  incorporarlos al análisis de la aplicación.
- `reglas-publicadas-antes.json`: versión real de reglas antes del cambio,
  comprobada contra el archivo local original.
- `firestore-antes.json`: respaldo inicial de 39 auditorías administrativas,
  una regularización y las asistencias, con inventario del resto.
- `firestore-final-antes.json`: respaldo actualizado inmediatamente antes
  de eliminar; se escribe después de verificar las nuevas reglas publicadas.
- `operacion.json`: rutas exactas, precondiciones, hash SHA-256 del respaldo,
  confirmación del lote y resultado de la verificación.
- `firestore-despues.json`: inventario posterior.

La eliminación se ejecuta únicamente tras publicar y comprobar las nuevas
reglas. El lote elimina solo las dos colecciones indicadas y retira el campo
obsoleto `ultimaAuditoriaId` de las asistencias que lo tengan. Cada escritura
exige que la versión del documento siga coincidiendo con el respaldo.

La comprobación posterior verifica que las colecciones no se listen, que las
asistencias conserven todos sus campos salvo la referencia retirada y que los
documentos de las demás colecciones mantengan su `updateTime`.

## Validación

Resultado remoto confirmado: se publicaron la web y las reglas; se eliminaron
los 39 registros de `auditoriaAdministrativa` y el registro de
`auditoriaRegularizaciones`, y se retiró una referencia `ultimaAuditoriaId`.
Las dos colecciones dejaron de aparecer en `listCollectionIds`. Se compararon
las asistencias campo por campo (salvo esa referencia) y el resto de documentos
por versión: sus datos se conservaron. El SHA-256 de la web servida coincide
con la compilación validada. La operación final está en `operacion.json`.

- Análisis general Flutter: sin incidencias.
- Suite completa Flutter: **251 pruebas aprobadas**.
- Reglas Firestore en emulador local: **134 pruebas aprobadas**, sin omisiones.
  Incluyen denegación de las auditorías retiradas, regularización histórica y
  en lote, restricciones de campos, perfiles inactivos, horarios y biometría.
- Las pruebas no modifican los datos reales. La operación remota se registra
  por separado en los respaldos anteriores.

No se requiere otra APK para el trabajador: las operaciones administrativas
afectadas están en el panel web y se conservan las reglas de marcación móvil.
No se modifican las funciones antiguas bloqueadas por Google ni su facturación.
