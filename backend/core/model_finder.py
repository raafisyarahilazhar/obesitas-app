from ultralytics import YOLO
from core.config import MODEL_PATH_FINDER

def load_finder_model():
    try:
        # Load YOLOv8 model
        model = YOLO(MODEL_PATH_FINDER)
        print("✅ Model Food Finder (YOLOv8) berhasil dimuat!")
        return model
    except Exception as e:
        print(f"🔥 ERROR memuat Food Finder: {e}")
        return None

yolo_finder_model = load_finder_model()