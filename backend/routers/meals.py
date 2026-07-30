from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session
from datetime import date, datetime

from core.database import get_db
from core.models import User, HealthProfile, MealLog, FavoriteExclusion
from services.recommendation_service import generate_meal_schedule
from services.nutrition_service import get_nutrition, get_food_category
from services.summary_service import summarize

router = APIRouter(prefix="/meals", tags=["Meals"])

# Makanan baru muncul di halaman Favorit setelah discan sebanyak ini
MIN_SCAN_FAVORIT = 5

class MealLogEntry(BaseModel):
    user_id: int # Ubah jadi int karena ID di MySQL adalah Integer
    food_name: str
    weight_grams: float
    calories: float
    carbs: float

class FavoriteAction(BaseModel):
    food_name: str

@router.post("/log")
def log_meal(data: MealLogEntry, db: Session = Depends(get_db)):
    # Simpan ke MySQL
    new_log = MealLog(
        user_id=data.user_id,
        date=date.today(),
        time=datetime.now().time(),
        food_name=data.food_name,
        weight_grams=data.weight_grams,
        calories=data.calories,
        carbs=data.carbs
    )
    db.add(new_log)
    db.commit()

    # Cek sisa kalori untuk rekomendasi
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == data.user_id).first()
    if profile:
        today_logs = db.query(MealLog).filter(MealLog.user_id == data.user_id, MealLog.date == date.today()).all()
        total_cal_today = sum(log.calories for log in today_logs)
        remaining = profile.daily_calories_target - total_cal_today
        
        advice = "Porsi berhasil disimpan."
        if remaining < 200:
            advice = "Awas! Target kalori harian Anda sudah hampir habis. Pertimbangkan untuk puasa."
        elif remaining > 500:
            advice = f"Disimpan. Anda masih memiliki sisa {round(remaining)} kcal untuk hari ini."
        return {"status": "success", "smart_recommendation_next_meal": advice}

    return {"status": "success", "smart_recommendation_next_meal": "Berhasil disimpan."}

# ── Riwayat makan per tanggal ─────────────────────────────────────────
@router.get("/history/{user_id}")
def get_meal_history(user_id: int, tanggal: str = None, db: Session = Depends(get_db)):
    """
    Riwayat makan pada satu tanggal (default hari ini) beserta ringkasan giziya.
    Parameter `tanggal` memakai format YYYY-MM-DD, dipakai oleh filter
    "Hari Ini / Kemarin / Pilih Tanggal" di halaman Riwayat.
    """
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil tidak ditemukan. Lakukan onboarding terlebih dahulu.")

    if tanggal:
        try:
            target_date = date.fromisoformat(tanggal)
        except ValueError:
            raise HTTPException(status_code=400, detail="Format tanggal harus YYYY-MM-DD")
    else:
        target_date = date.today()

    logs = (
        db.query(MealLog)
        .filter(MealLog.user_id == user_id, MealLog.date == target_date)
        .order_by(MealLog.time.asc())
        .all()
    )

    summary, items = summarize(logs, profile.daily_calories_target)

    return {
        "status": "success",
        "date": target_date.isoformat(),
        "is_today": target_date == date.today(),
        "total_items": len(items),
        "summary": summary,
        "items": items,
    }


# ── Favorit: makanan yang paling sering discan ────────────────────────
@router.get("/favorites/{user_id}")
def get_favorite_foods(user_id: int, min_scan: int = MIN_SCAN_FAVORIT, db: Session = Depends(get_db)):
    """
    Daftar makanan yang sudah discan minimal `min_scan` kali oleh user.
    Favorit tidak diinput manual, tapi dihitung dari riwayat scan.
    """
    hidden = {
        row.food_name
        for row in db.query(FavoriteExclusion).filter(FavoriteExclusion.user_id == user_id).all()
    }

    rows = (
        db.query(
            MealLog.food_name.label("food_name"),
            func.count(MealLog.id).label("scan_count"),
            func.avg(MealLog.weight_grams).label("avg_weight"),
            func.avg(MealLog.calories).label("avg_calories"),
            func.avg(MealLog.carbs).label("avg_carbs"),
            func.max(MealLog.date).label("last_date"),
        )
        .filter(MealLog.user_id == user_id)
        .group_by(MealLog.food_name)
        .having(func.count(MealLog.id) >= min_scan)
        .order_by(func.count(MealLog.id).desc())
        .all()
    )

    favorites = []
    for row in rows:
        if row.food_name in hidden:
            continue

        gizi = get_nutrition(row.food_name) or {}
        favorites.append({
            "food_name": row.food_name,
            "category": get_food_category(row.food_name),
            "scan_count": int(row.scan_count),
            "avg_weight_grams": round(float(row.avg_weight or 0)),
            "avg_calories": round(float(row.avg_calories or 0)),
            "avg_carbs": round(float(row.avg_carbs or 0), 1),
            "last_eaten": row.last_date.isoformat() if row.last_date else None,
            "per_100g": {
                "calories": gizi.get("calories"),
                "carbs": gizi.get("carbs"),
                "protein": gizi.get("protein"),
                "fat": gizi.get("fat"),
            },
            "medical_status": gizi.get("medical_status", "Data gizi tidak tersedia"),
        })

    return {
        "status": "success",
        "min_scan": min_scan,
        "total": len(favorites),
        "favorites": favorites,
    }


@router.post("/favorites/{user_id}/hide")
def hide_favorite(user_id: int, data: FavoriteAction, db: Session = Depends(get_db)):
    """Sembunyikan makanan dari daftar favorit (riwayat makan tetap utuh)."""
    sudah_ada = (
        db.query(FavoriteExclusion)
        .filter(FavoriteExclusion.user_id == user_id,
                FavoriteExclusion.food_name == data.food_name)
        .first()
    )
    if not sudah_ada:
        db.add(FavoriteExclusion(
            user_id=user_id,
            food_name=data.food_name,
            created_at=datetime.utcnow(),
        ))
        db.commit()

    return {"status": "success", "message": f"{data.food_name} dihapus dari favorit"}


@router.post("/favorites/{user_id}/unhide")
def unhide_favorite(user_id: int, data: FavoriteAction, db: Session = Depends(get_db)):
    """Kembalikan makanan yang tadinya dihapus dari favorit (tombol Urungkan)."""
    db.query(FavoriteExclusion).filter(
        FavoriteExclusion.user_id == user_id,
        FavoriteExclusion.food_name == data.food_name,
    ).delete()
    db.commit()

    return {"status": "success", "message": f"{data.food_name} dikembalikan ke favorit"}


@router.get("/schedule/{user_id}")
def get_patient_meal_plan(user_id: int, db: Session = Depends(get_db)):
    # 1. Ambil profil untuk mendapatkan target kalori harian
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil kesehatan belum diatur.")

    target_harian = profile.daily_calories_target

    # 2. Generate jadwal berdasarkan target tersebut
    plan = generate_meal_schedule(target_harian)

    return {
        "status": "success",
        "user_name": profile.name,
        "daily_target": target_harian,
        "meal_plan": plan
    }