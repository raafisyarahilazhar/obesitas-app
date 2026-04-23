from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import hashlib # Untuk hashing password sederhana (disarankan pakai passlib/bcrypt untuk production)

from core.database import get_db
from core.models import User, HealthProfile
from core.schemas import UserAuth, HealthProfileCreate, HealthProfileResponse

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])

# Fungsi Hash Sederhana
def hash_password(password: str):
    return hashlib.sha256(password.encode()).hexdigest()

@router.post("/register")
def register_user(data: UserAuth, db: Session = Depends(get_db)):
    # Cek apakah username sudah ada
    existing_user = db.query(User).filter(User.username == data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username sudah terdaftar")
    
    new_user = User(username=data.username, password_hash=hash_password(data.password))
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {"message": "Registrasi berhasil", "user_id": new_user.id}

@router.post("/login")
def login_user(data: UserAuth, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username, User.password_hash == hash_password(data.password)).first()
    if not user:
        raise HTTPException(status_code=401, detail="Username atau password salah")
    
    return {"message": "Login berhasil", "user_id": user.id}

@router.post("/profile/{user_id}", response_model=HealthProfileResponse)
def create_or_update_health_profile(user_id: int, data: HealthProfileCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    # KALKULASI PINTAR UNTUK OBESITAS
    height_m = data.height_cm / 100
    bmi = round(data.weight_kg / (height_m ** 2), 1)
    
    # Menghitung kalori maintenance kasar
    maintenance_calories = data.weight_kg * 24 * 1.2
    
    # Menentukan Target Defisit Kalori berdasarkan BMI
    if bmi >= 30:
        target_calories = maintenance_calories - 600 # Defisit besar untuk Obesitas
    elif bmi >= 25:
        target_calories = maintenance_calories - 400 # Defisit sedang untuk Overweight
    else:
        target_calories = maintenance_calories # Maintenance untuk Normal

    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    
    if profile:
        # Update jika sudah ada
        profile.name = data.name
        profile.age = data.age
        profile.height_cm = data.height_cm
        profile.weight_kg = data.weight_kg
        profile.bmi = bmi
        profile.daily_calories_target = int(target_calories)
    else:
        # Buat baru jika belum ada
        profile = HealthProfile(
            user_id=user_id, name=data.name, age=data.age, 
            height_cm=data.height_cm, weight_kg=data.weight_kg, 
            bmi=bmi, daily_calories_target=int(target_calories)
        )
        db.add(profile)
    
    db.commit()
    db.refresh(profile)
    
    return profile