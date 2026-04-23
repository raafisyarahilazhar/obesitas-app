import torch
import pathlib
from core.config import MODEL_PATH_INDONESIAN_FOOD, CONFIDENCE_THRESHOLD

# fix windows
pathlib.PosixPath = pathlib.WindowsPath

def load_model():
    model = torch.hub.load(
        'ultralytics/yolov5',
        'custom',
        path=MODEL_PATH_INDONESIAN_FOOD,
        source='github'
    )
    model.conf = CONFIDENCE_THRESHOLD
    model.iou = 0.40
    model.eval()
    return model

yolo_indonesian_food_model = load_model()