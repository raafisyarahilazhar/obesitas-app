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

# Kategori makanan untuk ditampilkan di halaman Favorit.
# CSV gizi tidak punya kolom kategori, jadi dipetakan dari nama makanan.
_FOOD_CATEGORIES = {
    "bakso": "Makanan Utama", "burger": "Makanan Utama", "mie goreng": "Makanan Utama",
    "nasi goreng": "Makanan Utama", "nasi putih": "Makanan Utama",
    "pempek": "Makanan Utama", "pizza": "Makanan Utama",
    "spaghetti": "Makanan Utama", "sate": "Makanan Utama",

    "ayam goreng": "Lauk Protein", "ikan goreng": "Lauk Protein",
    "nugget": "Lauk Protein", "rendang sapi": "Lauk Protein", "steak": "Lauk Protein",
    "tahu": "Lauk Protein", "tempe": "Lauk Protein",
    "telur goreng": "Lauk Protein", "telur rebus": "Lauk Protein",

    "capcay": "Sayuran", "terong balado": "Sayuran", "tumis kangkung": "Sayuran",

    "apple": "Buah", "banana": "Buah", "kiwi": "Buah",
    "pineapples": "Buah", "strawberry": "Buah",

    "chocolate chip cookie": "Camilan", "donat": "Camilan", "kentang goreng": "Camilan",
}

def get_food_category(food_name: str) -> str:
    return _FOOD_CATEGORIES.get(food_name.strip().lower(), "Lainnya")

def get_nutrition(food_name: str):
    # UBAH NAMA DARI YOLO JADI HURUF KECIL SAAT MENCARI
    kunci_pencarian = food_name.strip().lower()
    data = _NUTRITION_DB.get(kunci_pencarian)
    
    if not data:
        print(f"❌ Peringatan: Makanan '{food_name}' tidak ditemukan di CSV!")
        
    return data