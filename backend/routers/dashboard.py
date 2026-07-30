from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date

from core.database import get_db
from core.models import HealthProfile, MealLog
from services.summary_service import summarize

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/{user_id}")
def get_daily_dashboard(user_id: int, db: Session = Depends(get_db)):
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil tidak ditemukan. Lakukan onboarding terlebih dahulu.")

    # Ambil log hari ini dari database
    today_logs = db.query(MealLog).filter(MealLog.user_id == user_id, MealLog.date == date.today()).all()

    # Ringkasan gizi (protein & lemak dihitung ulang dari CSV)
    summary, history_formatted = summarize(today_logs, profile.daily_calories_target)

    return {
        "user": {
            "name": profile.name,
            "bmi": profile.bmi,
            "status": "Obesitas" if profile.bmi >= 30 else "Overweight" if profile.bmi >= 25 else "Normal",
            "age": profile.age,
            "weight_kg": profile.weight_kg,
            "height_cm": profile.height_cm
        },
        "today_summary": summary,
        "meals_history_today": history_formatted
    }
