# Dashboard basado en el funcionamiento del proyecto

Actualización posterior: a solicitud del usuario se retiró la cabecera grande
«Asistencia de hoy», incluidos fecha, contadores y hora de actualización.
El panel empieza con los indicadores y un botón de actualización compacto.
La descripción de la cabecera que sigue corresponde al diseño inicial.

## Revisión funcional

Se revisaron los módulos de administración, usuarios, sedes, autenticación,
asistencias, horarios, regularización, geolocalización, biometría y alertas;
sus entidades, fuentes de datos y reglas de acceso relacionadas con el panel.
Esta revisión define información para el Dashboard; no constituye una auditoría
exhaustiva de seguridad de cada archivo del proyecto.

El trabajo diario del administrador consiste en seguir marcaciones, revisar
jornadas y mantener cargos/sedes utilizables. Los datos existentes permiten
presentar esta información sin crear colecciones, modificar reglas o descargar
el historial completo.

## Información elegida

| Zona | Información y criterio |
| --- | --- |
| Cabecera | Fecha del resumen y hora de consulta, trabajadores activos, sedes activas y jornadas correctas de hoy. Los contadores de personal y sedes abren sus módulos. |
| Con marcaciones hoy | Personas activas con rol trabajador, inicio de labores no futuro y al menos una marca de hoy. Cuatro marcas no cuentan como cuatro personas. |
| Sin marcaciones hoy | El mismo personal en labores sin ninguna marca hoy. Domingo: no aplica. No es un indicador de faltas ni tardanza. |
| Jornadas incompletas | Jornadas de hoy cuyo evaluador existente devuelve Pendiente. Pueden estar en curso. |
| Jornadas observadas | Jornadas completas de hoy con incidencias según el evaluador común de horarios, ubicación y rostro. |
| Seguimiento | Filtros para incompletas, observadas, personas sin marcas y configuración del personal activo. Se muestran seis casos y se pueden desplegar más. Las flechas abren la ficha correspondiente. |
| Configuración | Cargo no reconocido por el mismo resolutor de horarios que usa la app, sede inexistente o inactiva. No se interpretan como incidencias biométricas ni como faltas. |
| Cobertura por sede | Trabajadores activos en labores asignados a cada sede que ya tienen alguna marca hoy. Cuenta por sede asignada, aunque una marca histórica proceda de otra. No mide jornadas cerradas ni certifica presencia física. Incluye únicamente sedes guardadas, no opciones predeterminadas sin guardar. |
| Últimas jornadas | Hasta cuatro jornadas recientes, con fecha, hora de la última marca, sede y estado. Se separan de los totales diarios. Las observaciones no vuelcan las notas administrativas completas en el resumen. |

Los administradores e inactivos no cuentan en la cobertura de trabajadores.
Sus marcaciones existentes sí conservan su jornada y evaluación en el historial.
Las jornadas de hoy se evalúan por sus marcas guardadas, incluso si el perfil
cambió de cargo. La regla de sábado continuo y domingo no laborable se conserva.

## Información que no se inventa

No hay un módulo de permisos, vacaciones o justificaciones que permita convertir
automáticamente la ausencia de marcas en una falta. Tampoco existe una base de
planilla para mostrar descuentos o pagos. No se calculan tendencias semanales
a partir de las cuatro jornadas recientes: sería una muestra incompleta.

Biometría y dispositivo siguen dentro de la ficha, con sus comprobaciones de
identidad, código, versión y autorización. El Dashboard no descarga vectores ni
referencias faciales para construir contadores. Las alertas de intentos de
marcación no se mezclan con jornadas observadas: una alerta puede existir sin
una asistencia aceptada. El módulo de auditoría permanece fuera de la navegación.

## Implementación y validación

- Nuevo modelo de resumen separa cálculos de presentación y permite probarlos
  sin Firebase. Se conserva la consulta acotada de actividad reciente y la
  lectura completa del día implementadas por el servicio actual.
- Cabecera con degradado institucional, cuatro indicadores, tarjetas principales
  con borde y sombra suave, filtros compactos, estados con color y texto.
- Escritorio con seguimiento/cobertura en dos columnas; pantallas pequeñas o
  texto ampliado apilan el contenido sin recortar nombres ni valores.
- Carga y errores explícitos; un error no se representa con ceros ficticios.
  Actualización manual mediante el botón de la cabecera.
- Pruebas de agregación, fechas, horarios guardados, sábado/domingo, inicio
  futuro, alias de cargos, sedes, filtros, acceso a ficha, reintento y diseño
  a 320/768/1400 píxeles con texto a escala 1 y 2.
- Captura local de revisión con datos sintéticos; no se modificaron perfiles,
  marcas, sedes ni autorizaciones reales para verificar el diseño.
- Validación final: análisis general de Flutter sin incidencias; 52 pruebas
  automatizadas aprobadas y una prueba adicional de captura visual aprobada
  (53 comprobaciones en la ejecución conjunta).
