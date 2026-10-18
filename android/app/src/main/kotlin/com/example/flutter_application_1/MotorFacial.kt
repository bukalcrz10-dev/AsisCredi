package com.example.flutter_application_1

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.SystemClock
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.core.CvType
import org.opencv.dnn.Dnn
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.FaceDetectorYN
import org.opencv.objdetect.FaceRecognizerSF
import java.io.ByteArrayInputStream
import java.io.File

/** Inferencia local. No conserva fotografías ni vectores entre llamadas. */
class MotorFacial(private val context: Context) {
    private var detector: FaceDetectorYN? = null
    private var recognizer: FaceRecognizerSF? = null

    private fun modelo(nombre: String): String {
        val destino = File(context.filesDir, nombre)
        if (!destino.exists()) {
            val temporal = File(context.filesDir, "$nombre.tmp")
            context.assets.open(nombre).use { entrada ->
                temporal.outputStream().use { salida -> entrada.copyTo(salida) }
            }
            check(temporal.renameTo(destino))
        }
        return destino.absolutePath
    }

    private fun iniciar(etapa: (String) -> Unit) {
        if (recognizer != null) return
        etapa("Cargando el motor de reconocimiento…")
        check(OpenCVLoader.initLocal())
        // Evitar paralelismo interno en dispositivos donde la inferencia se atasca.
        Core.setNumThreads(1)
        etapa("Cargando los modelos del rostro…")
        detector = FaceDetectorYN.create(modelo("face_detection_yunet_2023mar.onnx"), "",
            Size(640.0, 640.0), 0.9f, 0.3f, 5000,
            Dnn.DNN_BACKEND_OPENCV, Dnn.DNN_TARGET_CPU)
        recognizer = FaceRecognizerSF.create(modelo("face_recognition_sface_2021dec.onnx"), "",
            Dnn.DNN_BACKEND_OPENCV, Dnn.DNN_TARGET_CPU)
    }

    private fun imagenOrientada(bytes: ByteArray): Bitmap {
        val limites = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, limites)
        require(limites.outWidth > 0 && limites.outHeight > 0) { "No se pudo leer la foto." }
        var muestra = 1
        while (maxOf(limites.outWidth, limites.outHeight) / muestra > 1600) muestra *= 2
        val opciones = BitmapFactory.Options().apply { inSampleSize = muestra }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opciones)
            ?: throw IllegalArgumentException("No se pudo leer la foto.")
        try {
            val orientacion = ExifInterface(ByteArrayInputStream(bytes))
                .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            val matriz = Matrix()
            when (orientacion) {
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matriz.setScale(-1f, 1f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matriz.setRotate(180f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> matriz.setScale(1f, -1f)
                ExifInterface.ORIENTATION_TRANSPOSE -> { matriz.setRotate(90f); matriz.postScale(-1f, 1f) }
                ExifInterface.ORIENTATION_ROTATE_90 -> matriz.setRotate(90f)
                ExifInterface.ORIENTATION_TRANSVERSE -> { matriz.setRotate(-90f); matriz.postScale(-1f, 1f) }
                ExifInterface.ORIENTATION_ROTATE_270 -> matriz.setRotate(-90f)
            }
            val orientado = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matriz, true)
            if (orientado !== bitmap) bitmap.recycle()
            return orientado
        } catch (error: Exception) { bitmap.recycle(); throw error }
    }

    fun extraer(bytes: ByteArray, etapa: (String) -> Unit): Map<String, Any> {
        val inicio = SystemClock.elapsedRealtime()
        iniciar(etapa)
        val rgba = Mat(); val bgr = Mat(); val pequeno = Mat()
        val caras = Mat(); val alineada = Mat(); val vector = Mat()
        try {
            etapa("Preparando la imagen capturada…")
            val bitmap = imagenOrientada(bytes)
            try { Utils.bitmapToMat(bitmap, rgba) } finally { bitmap.recycle() }
            Imgproc.cvtColor(rgba, bgr, Imgproc.COLOR_RGBA2BGR)
            val escala = minOf(1.0, 640.0 / maxOf(bgr.cols(), bgr.rows()))
            Imgproc.resize(bgr, pequeno, Size((bgr.cols() * escala).toInt().toDouble(),
                (bgr.rows() * escala).toInt().toDouble()))
            detector!!.setInputSize(pequeno.size())
            etapa("Localizando el rostro en la imagen…")
            detector!!.detect(pequeno, caras)
            require(caras.rows() == 1) {
                if (caras.rows() == 0) "No se detectó una cara. Mejora la luz y mira de frente."
                else "Hay más de una cara. Toma la foto sin otras personas."
            }
            require(caras.get(0, 2)[0] >= 80 && caras.get(0, 3)[0] >= 80) {
                "Acerca tu cara a la cámara y vuelve a capturar."
            }
            val cara = caras.row(0)
            try { recognizer!!.alignCrop(pequeno, cara, alineada) } finally { cara.release() }
            require(alineada.rows() == 112 && alineada.cols() == 112 &&
                alineada.type() == CvType.CV_8UC3) {
                "El recorte del rostro no tiene el formato esperado. Repite la captura."
            }
            etapa("Calculando el rostro en modo compatible (CPU, 1 hilo)…")
            recognizer!!.feature(alineada, vector)
            etapa("Validando el resultado del reconocimiento…")
            require(vector.total() == 128L) { "El modelo devolvió un resultado inesperado." }
            require(vector.type() == CvType.CV_32FC1) { "El vector facial tiene un tipo inesperado." }
            etapa("Leyendo los 128 valores del rostro…")
            val valores = FloatArray(128)
            vector.get(0, 0, valores)
            etapa("Comprobando los valores obtenidos…")
            require(valores.all { it.isFinite() } && valores.any { it != 0f }) { "Captura no válida. Reintenta." }
            return mapOf("vector" to valores.map { it.toDouble() },
                "milisegundos" to (SystemClock.elapsedRealtime() - inicio))
        } finally {
            etapa("Liberando las imágenes procesadas…")
            listOf(rgba, bgr, pequeno, caras, alineada, vector).forEach { it.release() }
        }
    }
}
