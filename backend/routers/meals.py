from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import date, datetime

from core.database import get_db
from core.models import User, HealthProfile, MealLog
from services.recommendation_service import generate_meal_schedule

router = APIRouter(prefix="/meals", tags=["Meals"])

class MealLogEntry(BaseModel):
    user_id: int # Ubah jadi int karena ID di MySQL adalah Integer
    food_name: str
    weight_grams: float
    calories: float
    carbs: float
    
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