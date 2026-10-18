package com.example.flutter_application_1

import android.graphics.*
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

class AnalizadorParpadeos {
    private val detector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .enableTracking().build()
    )
    fun analizar(bytes: ByteArray, width: Int, height: Int, rotation: Int, foto: Boolean): Map<String, Any?> {
        require(width in 2..1920 && height in 2..1920 && width % 2 == 0 && height % 2 == 0)
        require(bytes.size == width * height * 3 / 2 && rotation in listOf(0, 90, 180, 270))
        val caras = Tasks.await(detector.process(
            InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21)
        ), 2, TimeUnit.SECONDS)
        val datos = mutableMapOf<String, Any?>("caras" to caras.size)
        if (caras.size != 1) return datos
        val cara = caras.single()
        datos["id"] = cara.trackingId
        datos["izquierda"] = cara.leftEyeOpenProbability?.toDouble()
        datos["derecha"] = cara.rightEyeOpenProbability?.toDouble()
        datos["giro"] = cara.headEulerAngleY.toDouble()
        datos["inclinacion"] = cara.headEulerAngleZ.toDouble()
        datos["anchoCara"] = cara.boundingBox.width().toDouble() / if (rotation % 180 == 0) width else height
        if (foto) {
            val salida = ByteArrayOutputStream()
            check(YuvImage(bytes, ImageFormat.NV21, width, height, null)
                .compressToJpeg(Rect(0, 0, width, height), 95, salida))
            val jpeg = salida.toByteArray()
            val original = requireNotNull(BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size))
            var orientada: Bitmap? = null
            try {
                orientada = Bitmap.createBitmap(original, 0, 0, original.width, original.height,
                    Matrix().apply { postRotate(rotation.toFloat()) }, true)
                val final = ByteArrayOutputStream()
                check(orientada.compress(Bitmap.CompressFormat.JPEG, 95, final))
                datos["imagen"] = final.toByteArray()
            } finally {
                if (orientada !== original) orientada?.recycle()
                original.recycle()
                jpeg.fill(0)
            }
        }
        return datos
    }
    fun cerrar() = detector.close()
}
