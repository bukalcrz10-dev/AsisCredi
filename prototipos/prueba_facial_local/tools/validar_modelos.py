"""Prueba de humo en escritorio; no certifica precisión ni ejecución Android."""
import json
import sys
from pathlib import Path

raiz = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(raiz / '.dart_tool/prueba-facial-python'))
import cv2 as cv
import numpy as np

modelos = Path(__file__).resolve().parents[1] / 'android/app/src/main/assets'
fixtures = raiz / '.dart_tool/prueba-facial-fixtures'
cv.setNumThreads(1)
detector = cv.FaceDetectorYN.create(str(modelos / 'face_detection_yunet_2023mar.onnx'), '', (640, 640), 0.9)
recognizer = cv.FaceRecognizerSF.create(str(modelos / 'face_recognition_sface_2021dec.onnx'), '',
    cv.dnn.DNN_BACKEND_OPENCV, cv.dnn.DNN_TARGET_CPU)


def caras(imagen):
    detector.setInputSize((imagen.shape[1], imagen.shape[0]))
    _, encontrados = detector.detect(imagen)
    return [] if encontrados is None else encontrados


def vector(imagen):
    encontrados = caras(imagen)
    assert len(encontrados) == 1
    alineada = recognizer.alignCrop(imagen, encontrados[0])
    assert alineada.shape == (112, 112, 3) and alineada.dtype == np.uint8
    resultado = recognizer.feature(alineada)
    assert resultado.shape == (1, 128) and np.isfinite(resultado).all()
    return resultado


a = cv.imread(str(fixtures / 'imagen_a.jpg'))
b = cv.imread(str(fixtures / 'imagen_b.jpg'))
assert a is not None and b is not None
va, vb = vector(a), vector(b)
alterada = cv.convertScaleAbs(a, alpha=0.9, beta=12)
score_misma = float(recognizer.match(va, vector(alterada), cv.FaceRecognizerSF_FR_COSINE))
score_distinta = float(recognizer.match(va, vb, cv.FaceRecognizerSF_FR_COSINE))
assert score_misma >= 0.363
assert score_distinta < 0.363
assert len(caras(np.zeros((640, 640, 3), np.uint8))) == 0
assert len(caras(np.hstack([a, a]))) == 2
print(json.dumps({'opencv': cv.__version__, 'dimension_vector': 128,
    'misma_imagen_luz_modificada': score_misma,
    'imagenes_distintas': score_distinta, 'sin_cara': 'detectado',
    'dos_caras': 'detectado', 'alcance': 'humo escritorio, no precisión en celulares'}, indent=2))
