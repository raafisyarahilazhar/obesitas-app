import csv
import os

_NUTRITION_DB = {}

def load_nutrition_database(filepath="./dataset/nutrition_dataset.csv"):
    global _NUTRITION_DB
    if not os.path.exists(filepath):
        print(f"CRITICAL ERROR: File {filepath} tidak ditemukan!")
        return

    with open(filepath, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # UBAH NAMA JADI HURUF KECIL & HAPUS SPASI BERLEBIH SAAT DISIMPAN
            kunci_nama = row['food_name'].strip().lower()
            
            _NUTRITION_DB[kunci_nama] = {
                "calories": float(row['calories_per_100g']),
                "carbs": float(row['carbs_per_100g']),
                "protein": float(row['protein_per_100g']),
                "fat": float(row['fat_per_100g']),
                "medical_status": row['medical_status_obesitas']
            }
    print(f"✅ Berhasil memuat {len(_NUTRITION_DB)} data makanan dari CSV (Kebal Case-Sensitive).")

def get_all_food_names():
    return list(_NUTRITION_DB.keys())

def get_nutrition(food_name: str):
    # UBAH NAMA DARI YOLO JADI HURUF KECIL SAAT MENCARI
    kunci_pencarian = food_name.strip().lower()
    data = _NUTRITION_DB.get(kunci_pencarian)
    
    if not data:
        print(f"❌ Peringatan: Makanan '{food_name}' tidak ditemukan di CSV!")
        
    return data