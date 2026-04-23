from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date

from core.database import get_db
from core.models import HealthProfile, MealLog

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/{user_id}")
def get_daily_dashboard(user_id: int, db: Session = Depends(get_db)):
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil tidak ditemukan. Lakukan onboarding terlebih dahulu.")

    # Ambil log hari ini dari database
    today_logs = db.query(MealLog).filter(MealLog.user_id == user_id, MealLog.date == date.today()).all()

    consumed_calories = sum(log.calories for log in today_logs)
    consumed_carbs = sum(log.carbs for log in today_logs)

    # Format history untuk Flutter
    history_formatted = [
        {
            "food_name": log.food_name,
            "time": log.time.strftime("%H:%M"),
            "weight_grams": log.weight_grams,
            "calories": log.calories,
            "carbs": log.carbs
        } for log in today_logs
    ]

    return {
        "user": {
            "name": profile.name, 
            "bmi": profile.bmi, 
            "status": "Obesitas" if profile.bmi >= 30 else "Overweight" if profile.bmi >= 25 else "Normal",
            "age": profile.age,
            "weight_kg": profile.weight_kg,
            "height_cm": profile.height_cm
        },
        "today_summary": {
            "calories_target": profile.daily_calories_target,
            "calories_consumed": round(consumed_calories, 1),
            "sugar_target": 150, # Target karbohidrat kasar harian
            "sugar_consumed": round(consumed_carbs, 1),
        },
        "meals_history_today": history_formatted
    }