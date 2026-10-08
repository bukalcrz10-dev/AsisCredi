# Sesion del trabajador

La APP movil presenta «Mantener mi sesión iniciada», desmarcada al abrir el
formulario. La opcion afecta a la sesion que se inicia correctamente y al usuario
correspondiente en este dispositivo; no almacena contrasenas.

- Marcada: conserva la sesion de Firebase, sujeta a los controles existentes del
  perfil activo y al cierre manual.
- Desmarcada: vence tras 15 minutos sin interaccion. Tocar, desplazar o usar el
  teclado fisico cuenta como actividad; las actualizaciones automaticas no.
- Se persiste la ultima actividad para comprobar la caducidad al reiniciar.
  El tiempo con el celular bloqueado o la APP en segundo plano tambien cuenta.
- El cierre automatico espera las operaciones de registrarMarcacion en curso.
  Luego cierra las rutas superpuestas, como camara o dialogos, y la sesion.
- Los botones existentes de cerrar sesion siguen llamando a Firebase signOut.
- Las sesiones anteriores sin preferencia guardada requieren un nuevo ingreso.
- La politica aplica a la APP movil; el panel web mantiene su comportamiento.

Es una politica local de la APP, basada en el reloj del dispositivo. No sustituye
reglas de Firestore ni revoca sesiones en otros dispositivos. Un retroceso del
reloj respecto a la actividad guardada invalida la sesion temporal. Si Android
suspende o termina el proceso, se comprueba el vencimiento al regresar.

## Prueba manual

1. Instalar el APK actualizado e ingresar con la casilla desmarcada.
2. Dejar la APP sin usar durante 15 minutos, tambien probar con pantalla bloqueada.
   Al volver debe pedir el ingreso; si habia una escritura de marcacion en curso,
   esperara su finalizacion antes del cierre automatico.
3. Repetir, interactuando antes de los 15 minutos: el plazo se renueva.
4. Ingresar con la casilla marcada, cerrar y reabrir la APP: conserva la sesion.
5. Usar el boton de cerrar sesion con la casilla previamente marcada: debe salir.
6. Reabrir una sesion temporal despues de mas de 15 minutos: pide nuevo ingreso.
