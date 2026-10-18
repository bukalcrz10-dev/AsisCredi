package pe.crediasciende.prueba_facial_local

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/** Devuelve una única respuesta. El vencimiento no interrumpe código nativo. */
class RespuestaLimitada(
    private val destino: MethodChannel.Result,
    private val vigente: () -> Boolean,
    private val ultimaEtapa: () -> String
) : MethodChannel.Result {
    private val handler = Handler(Looper.getMainLooper())
    private val terminada = AtomicBoolean(false)
    private val limite = Runnable {
        error("tiempo_agotado",
            "El motor superó 40 segundos. Cierra completamente la app. Último paso: ${ultimaEtapa()}", null)
    }
    init { handler.postDelayed(limite, 40000) }

    private fun responder(accion: () -> Unit) {
        if (!terminada.compareAndSet(false, true)) return
        handler.removeCallbacks(limite)
        handler.post { if (vigente()) accion() }
    }
    override fun success(result: Any?) = responder { destino.success(result) }
    override fun error(code: String, message: String?, details: Any?) =
        responder { destino.error(code, message, details) }
    override fun notImplemented() = responder { destino.notImplemented() }
}
