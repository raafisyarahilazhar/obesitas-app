import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Update dengan nama file model yang baru
# MODEL_PATH_FINDER = os.path.join(BASE_DIR, "ml", "food_finder.pt")
# MODEL_PATH_COMBINATION = os.path.join(BASE_DIR, "ml", "food_combination.pt")
MODEL_PATH_FOOD = os.path.join(BASE_DIR, "ml", "food_v1.pt")

# Pertahankan threshold di 45% agar tidak mendeteksi objek sembarangan
CONFIDENCE_THRESHOLD = 0.45
CLIP_CONFIDENCE_THRESHOLD = 0.2