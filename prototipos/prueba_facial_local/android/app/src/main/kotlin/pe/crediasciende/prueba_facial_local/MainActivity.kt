package pe.crediasciende.prueba_facial_local

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private lateinit var motor: MotorFacial
    private var parpadeos: AnalizadorParpadeos? = null
    private val procesando = java.util.concurrent.atomic.AtomicBoolean(false)


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        motor = MotorFacial(applicationContext)
        val canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "crediasciende/prueba_facial")
        canal
            .setMethodCallHandler { call, result ->
                if (call.method == "parpadeos") {
                    val bytes = call.argument<ByteArray>("imagen")
                    val width = call.argument<Int>("ancho") ?: 0
                    val height = call.argument<Int>("alto") ?: 0
                    val rotation = call.argument<Int>("rotacion") ?: -1
                    val foto = call.argument<Boolean>("foto") ?: false
                    if (bytes == null || bytes.isEmpty() || bytes.size > 6_000_000) {
                        result.error("imagen", "Imagen no válida.", null)
                    } else worker.execute {
                        try {
                            val analizador = parpadeos ?: AnalizadorParpadeos().also { parpadeos = it }
                            val datos = analizador.analizar(bytes, width, height, rotation, foto)
                            runOnUiThread { if (!isDestroyed) result.success(datos) }
                        } catch (_: Exception) {
                            runOnUiThread { if (!isDestroyed) result.error("parpadeos", "No se pudo analizar la cámara.", null) }
                        } finally { bytes.fill(0) }
                    }
                } else if (call.method != "extraer") {
                    result.notImplemented()
                } else {
                    val bytes = call.argument<ByteArray>("imagen")
                    if (bytes == null || bytes.isEmpty() || bytes.size > 20_000_000) {
                        result.error("imagen", "Imagen no válida.", null)
                    } else if (!procesando.compareAndSet(false, true)) {
                        bytes.fill(0)
                        result.error("ocupado", "El motor sigue ocupado. Cierra completamente la app y vuelve a abrirla.", null)
                    } else {
                        val ultimaEtapa = java.util.concurrent.atomic.AtomicReference("Esperando al motor")
                        val respuesta = RespuestaLimitada(result, { !isDestroyed }, { ultimaEtapa.get() })
                        worker.execute {
                            try {
                                // Liberar el detector y sus recursos antes de ejecutar SFace.
                                runOnUiThread { if (!isDestroyed) canal.invokeMethod("etapa", "Liberando el detector de parpadeos…") }
                                parpadeos?.cerrar()
                                parpadeos = null
                                val datos = motor.extraer(bytes) { etapa ->
                                    ultimaEtapa.set(etapa)
                                    runOnUiThread { if (!isDestroyed) canal.invokeMethod("etapa", etapa) }
                                }
                                ultimaEtapa.set("Devolviendo el resultado a la pantalla")
                                respuesta.success(datos)
                            } catch (error: Exception) {
                                val mensaje = if (error is IllegalArgumentException) error.message
                                    else "No se pudo procesar la imagen en este celular."
                                runOnUiThread { if (!isDestroyed) respuesta.error("procesamiento", mensaje, null) }
                            } catch (_: LinkageError) {
                                runOnUiThread { if (!isDestroyed) respuesta.error("modelo", "El motor no es compatible con este dispositivo.", null) }
                            } finally { bytes.fill(0); procesando.set(false) }
                        }
                    }
                }
            }
    }

    override fun onDestroy() {

        worker.execute { parpadeos?.cerrar() }
        worker.shutdown()
        super.onDestroy()
    }
}
