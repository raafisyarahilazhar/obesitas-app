from ultralytics import YOLO
from core.config import MODEL_PATH_COMBINATION

def load_combination_model():
    try:
        # Load YOLOv8 model
        model = YOLO(MODEL_PATH_COMBINATION)
        print("✅ Model Food Combination (YOLOv8) berhasil dimuat!")
        return model
    except Exception as e:
        print(f"🔥 ERROR memuat Food Combination: {e}")
        return None

yolo_combination_model = load_combination_model()