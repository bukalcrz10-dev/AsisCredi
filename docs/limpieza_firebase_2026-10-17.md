# Limpieza conservadora de Firebase — 17 de octubre de 2026

Nota posterior: el usuario solicitó después retirar completamente las dos
auditorías. Ese cambio de código, reglas y datos se documenta en
[retiro de auditorías](retiro_auditorias_2026-10-17.md). Lo que sigue registra
la primera limpieza, anterior a esa nueva solicitud.

Proyecto revisado: `asistenciageolocalizacio-368fc`.

## Resultado aplicado

Se eliminó **un documento de configuración biométrica revocada sin propietario
existente**. No existía el UID en Authentication ni en `usuarios`, ni tenía
asistencias, credenciales biométricas, vínculo privado o subcolecciones.

Antes de eliminar se guardó una copia completa del documento. Se volvieron a
consultar las relaciones y se utilizó una escritura con precondición de
`updateTime`, para cancelar si alguien cambiaba el documento tras el respaldo.
La lectura posterior confirmó que ya no existe.

## Inventario antes y después

| Recurso | Antes | Después |
| --- | ---: | ---: |
| Cuentas de Authentication | 4 | 4 |
| Perfiles de usuarios | 4 | 4 |
| Sedes | 2 | 2 |
| Asistencias | 4 | 4 |
| Alertas | 46 | 46 |
| Auditorías administrativas | 39 | 39 |
| Auditorías de regularizaciones | 1 | 1 |
| Configuraciones biométricas | 5 | 4 |
| Credenciales biométricas | 2 | 2 |
| Vínculos biométricos privados | 2 | 2 |
| Funciones de segunda generación | 5 | 5 |
| Buckets de fuentes de funciones | 2 | 2 |
| Bases de Firestore / sitios de Hosting | 1 / 1 | 1 / 1 |

La comprobación comparó nombres y `updateTime` de todos los documentos
conservados, además de los identificadores/estados de las cuentas de Auth y el
SHA-256 del respaldo eliminado. No se detectaron otros cambios en los datos.

## Recursos conservados

- Las auditorías siguen utilizándose en transacciones de administración y
  regularización, aunque su módulo ya no aparezca en el menú.
- Las alertas documentan intentos e incidencias; no se consideran basura por no
  tener una marcación asociada o por pertenecer a un perfil antiguo.
- Hay biometría de un usuario que ya no existe, pero con asistencias históricas
  asociadas. Se conserva su configuración, credencial y vínculo para mantener
  el contexto de esos registros y sus comprobantes.
- Las configuraciones revocadas de cuentas existentes preservan la versión y
  el estado de autorización. Revocado no significa innecesario.
- Las cuatro cuentas tienen perfil; no se detectaron cuentas sin perfil que
  requieran recuperar un alta incompleta. No se eliminó ninguna cuenta.
- Hosting, reglas, índices, proveedores de acceso y asignaciones de sedes no
  se modificaron. No se habilitaron APIs ni se cambió facturación.

## Funciones antiguas pendientes por bloqueo de Google

La app actual no llama a estas cinco funciones de la antigua administración:

- `actualizarTrabajadorHttp`
- `crearTrabajadorConAcceso`
- `crearTrabajadorConAccesoHttp`
- `restablecerContrasenaTrabajadorHttp`
- `restablecerContrasenaTrabajador`

Google permite listarlas, pero su lectura individual devolvió HTTP 403 con el
mensaje de revisar la cuenta de facturación. La descarga de las fuentes de las
cinco funciones también devolvió 403. Se guardaron sus metadatos disponibles en
el listado, pero **no se obtuvo una copia recuperable de su código**. Por eso no
se intentó eliminarlas en esta limpieza. No se eliminaron sus dos buckets de
fuentes y cargas, que siguen asociados a esos despliegues.

Este es un bloqueo del servicio remoto, no un rechazo de aprobación de las
herramientas. No se solicitó ni activó facturación para intentar superarlo.

## Respaldos y trazabilidad

Los archivos locales están en
`respaldos_locales/firebase/2026-10-17/`, excluidos de Git por contener
identificadores internos y metadatos del proyecto:

- `configuracion-revocada-0.json`: documento original, con campos y versión.
- `inventario-antes.json` e `inventario-despues.json`: inventarios de revisión.
- `plan.json`: recurso seleccionado y bloqueos al respaldar funciones.
- `resultado.json`: documento eliminado, hora de confirmación, hash del
  respaldo y verificación posterior.
- Un JSON de metadatos por función antigua. No son respaldos de código.

El respaldo del documento permite restaurar sus campos en su ruta original,
únicamente si esa ruta sigue sin existir. No debe sobrescribirse una nueva
configuración si la cuenta se restablece posteriormente.

No se copiaron vectores faciales al inventario ni se publicaron los respaldos
en el sitio web. Esta tarea modifica datos remotos; no necesita recompilar la
app ni cambiar su diseño.
