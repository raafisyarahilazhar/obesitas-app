from ultralytics import YOLO
from core.config import MODEL_PATH_FOOD

def load_food_model():
    try:
        # Load YOLOv8 model
        model = YOLO(MODEL_PATH_FOOD)
        print("✅ Model Food INDONESIA 29 Kelas (YOLOv8) berhasil dimuat!")
        return model
    except Exception as e:
        print(f"🔥 ERROR memuat Food INDONESIA 29 Kelas: {e}")
        return None

yolo_food_model = load_food_model()