package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val abrirInformeRequest = 4801

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "asistencia/informes")
            .setMethodCallHandler { call, result ->
                if (call.method != "abrirUbicacion") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val uri = call.argument<String>("destino")?.let(Uri::parse)
                if (uri == null || uri.scheme != "content") {
                    result.error("ubicacion_invalida", "Ubicación no disponible", null)
                    return@setMethodCallHandler
                }
                try {
                    // El navegador de documentos abre la carpeta del archivo,
                    // sin solicitar acceso a todo el almacenamiento.
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri)
                        }
                    }
                    startActivityForResult(intent, abrirInformeRequest)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("ubicacion_no_disponible", "No se pudo abrir Archivos", null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != abrirInformeRequest || resultCode != Activity.RESULT_OK) return
        val uri = data?.data ?: return
        try {
            startActivity(Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, contentResolver.getType(uri) ?: "application/octet-stream")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            })
        } catch (error: Exception) {
            Toast.makeText(this, "No hay una aplicación disponible para abrir este archivo.", Toast.LENGTH_LONG).show()
        }
    }
}
