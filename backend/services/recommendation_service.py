import random

def get_obesity_recommendation(calories: float, weight_grams: float, bmi: float):
    # Hitung Kepadatan Kalori (Kalori per 100 gram)
    if weight_grams <= 0:
        return "safe"
        
    caloric_density = (calories / weight_grams) * 100
    
    # Jika pengguna Overweight / Obese (BMI >= 25)
    if bmi >= 25.0:
        # Jika makanan memiliki lebih dari 250 kcal per 100g (contoh: gorengan, pizza, kue manis)
        if caloric_density > 250:
            return "warning" # Peringatan: Makanan padat kalori
            
    # Jika BMI normal atau makanan rendah kalori (seperti sayur/buah)
    return "safe"

MENU_POOL = {
    "sarapan": [
        {"saran": "Telur rebus, ubi ungu, atau oatmeal dengan buah.", "fokus": "Protein & Serat untuk energi stabil.", "tags": ["umum", "diabetes"]},
        {"saran": "Smoothie bayam, pisang, dan chia seeds.", "fokus": "Kaya serat dan antioksidan.", "tags": ["umum", "vegetarian"]},
        {"saran": "Roti gandum utuh dengan alpukat dan tomat.", "fokus": "Lemak sehat untuk menahan lapar.", "tags": ["umum", "vegan"]}
    ],
    "makan_siang": [
        {"saran": "Nasi merah, dada ayam panggang, dan porsi sayur hijau melimpah.", "fokus": "Nutrisi lengkap (Isi Piringku).", "tags": ["umum"]},
        {"saran": "Salad dada ayam dengan dressing olive oil matang.", "fokus": "Rendah karbohidrat, tinggi protein.", "tags": ["low-carb", "diabetes"]},
        {"saran": "Kentang rebus, ikan salmon/kembung panggang, dan tumis brokoli.", "fokus": "Omega-3 tinggi untuk anti-inflamasi.", "tags": ["umum", "pescatarian"]}
    ],
    "selingan_sore": [
        {"saran": "Apel potong atau pir segar.", "fokus": "Rendah Indeks Glikemik.", "tags": ["umum", "diabetes"]},
        {"saran": "Segenggam kacang almond atau edamame rebus.", "fokus": "Protein nabati ringan pengganjal perut.", "tags": ["umum", "vegan"]},
        {"saran": "Yogurt plain rendah lemak dengan potongan stroberi.", "fokus": "Probiotik untuk pencernaan.", "tags": ["umum"]}
    ],
    "makan_malam": [
        {"saran": "Sup bening sayuran dan tahu/tempe rebus.", "fokus": "Sangat mudah dicerna saat tidur.", "tags": ["umum", "vegan"]},
        {"saran": "Tumis buncis bawang putih dan sepotong ikan kukus.", "fokus": "Rendah kalori namun mengenyangkan.", "tags": ["umum", "low-carb"]},
        {"saran": "Telur orak-arik (sedikit minyak) dengan sayur kol dan wortel.", "fokus": "Praktis dan tinggi protein.", "tags": ["umum"]}
    ]
}

# 2. LOGIKA UTAMA YANG DINAMIS
def generate_meal_schedule(target_calories: int, user_conditions: list = ["umum"]):
    """
    Menghasilkan jadwal makan dengan menu yang dirotasi secara acak 
    berdasarkan kolam data dan preferensi/kondisi pasien.
    """
    
    # Template struktur waktu dan porsi dasar
    meal_slots = {
        "sarapan": {"porsi": 0.25, "jam": "06:00 - 08:30"},
        "makan_siang": {"porsi": 0.35, "jam": "12:00 - 13:30"},
        "selingan_sore": {"porsi": 0.10, "jam": "15:30 - 16:30"},
        "makan_malam": {"porsi": 0.30, "jam": "18:30 - 19:30"}
    }

    schedule = []
    
    for meal_type, slot in meal_slots.items():
        meal_calories = round(target_calories * slot["porsi"])
        
        # A. Filter menu yang cocok dengan kondisi user (misal user punya tag 'diabetes')
        # Mengecek apakah ada irisan antara tag menu dan kondisi user
        suitable_menus = [
            menu for menu in MENU_POOL[meal_type] 
            if any(tag in user_conditions for tag in menu["tags"])
        ]
        
        # Fallback: Jika tidak ada yang cocok, gunakan semua menu di kategori tersebut
        if not suitable_menus:
            suitable_menus = MENU_POOL[meal_type]
            
        # B. Pilih satu menu secara ACAK dari daftar yang cocok
        selected_menu = random.choice(suitable_menus)

        schedule.append({
            "waktu": meal_type.replace("_", " ").title(), # Format text agar cantik
            "jam": slot["jam"],
            "target_kalori": meal_calories,
            "menu_rekomendasi": selected_menu["saran"],
            "catatan_klinis": selected_menu["fokus"]
        })
    
    return schedule