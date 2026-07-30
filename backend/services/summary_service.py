"""
Perhitungan ringkasan gizi harian.

Tabel `meal_logs` hanya menyimpan kalori & karbohidrat, jadi protein dan lemak
dihitung ulang dari CSV gizi memakai nama makanan + berat porsi yang tercatat.
Dipakai bersama oleh router Dashboard dan Riwayat agar angkanya selalu sama.
"""
from services.nutrition_service import get_nutrition

# Pembagian makronutrien dari total kalori harian (Angka Kecukupan Gizi umum).
# Karbohidrat & protein = 4 kkal/gram, lemak = 9 kkal/gram.
CARBS_CALORIE_SHARE = 0.55
PROTEIN_CALORIE_SHARE = 0.20
FAT_CALORIE_SHARE = 0.25


def macro_targets(daily_calories: int) -> dict:
    """Ubah target kalori harian menjadi target gram karbo/protein/lemak."""
    kalori = daily_calories or 0
    return {
        "carbs": round(kalori * CARBS_CALORIE_SHARE / 4),
        "protein": round(kalori * PROTEIN_CALORIE_SHARE / 4),
        "fat": round(kalori * FAT_CALORIE_SHARE / 9),
    }


def log_detail(log) -> dict:
    """Satu baris meal_log lengkap dengan protein & lemak hasil hitung ulang."""
    gizi = get_nutrition(log.food_name)
    faktor = (log.weight_grams or 0) / 100.0

    return {
        "food_name": log.food_name,
        "time": log.time.strftime("%H:%M") if log.time else "-",
        "weight_grams": log.weight_grams,
        "calories": log.calories,
        "carbs": log.carbs,
        "protein": round(gizi["protein"] * faktor, 1) if gizi else 0.0,
        "fat": round(gizi["fat"] * faktor, 1) if gizi else 0.0,
    }


def summarize(logs, daily_calories_target: int) -> tuple:
    """
    Hitung total gizi dari sekumpulan meal_log.
    Mengembalikan (ringkasan, daftar_item_terperinci).
    """
    items = [log_detail(log) for log in logs]
    targets = macro_targets(daily_calories_target)

    total_kalori = sum(i["calories"] or 0 for i in items)
    total_karbo = sum(i["carbs"] or 0 for i in items)
    total_protein = sum(i["protein"] for i in items)
    total_lemak = sum(i["fat"] for i in items)

    ringkasan = {
        "calories_target": daily_calories_target,
        "calories_consumed": round(total_kalori, 1),

        "carbs_target": targets["carbs"],
        "carbs_consumed": round(total_karbo, 1),
        "protein_target": targets["protein"],
        "protein_consumed": round(total_protein, 1),
        "fat_target": targets["fat"],
        "fat_consumed": round(total_lemak, 1),

        # Nama lama dipertahankan agar layar yang belum diperbarui tetap jalan
        "sugar_target": targets["carbs"],
        "sugar_consumed": round(total_karbo, 1),
    }

    return ringkasan, items
