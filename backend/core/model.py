import torch
import pathlib
from core.config import MODEL_PATH, CONFIDENCE_THRESHOLD

# fix windows
pathlib.PosixPath = pathlib.WindowsPath

def load_model():
    model = torch.hub.load(
        'ultralytics/yolov5',
        'custom',
        path=MODEL_PATH,
        source='github'
    )
    model.conf = CONFIDENCE_THRESHOLD
    model.iou = 0.40
    model.eval()
    return model

yolo_model = load_model()