from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import hashlib # Untuk hashing password sederhana (disarankan pakai passlib/bcrypt untuk production)

from core import config
from core.database import get_db
from core.models import User, HealthProfile, EmailVerification
from core.schemas import (
    UserAuth, UserRegister, VerifyEmailRequest, ResendCodeRequest,
    HealthProfileCreate, HealthProfileResponse,
)
from services.email_service import generate_verification_code, send_verification_email

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])

# Fungsi Hash Sederhana
def hash_password(password: str):
    return hashlib.sha256(password.encode()).hexdigest()

def hash_code(code: str):
    return hashlib.sha256(code.encode()).hexdigest()


# ── Helper Verifikasi Email ───────────────────────────────────────────
def _active_verification(db: Session, user_id: int):
    """Ambil kode verifikasi terakhir yang belum dipakai."""
    return (
        db.query(EmailVerification)
        .filter(EmailVerification.user_id == user_id, EmailVerification.is_used == False)
        .order_by(EmailVerification.created_at.desc())
        .first()
    )

def _issue_verification_code(db: Session, user: User) -> bool:
    """
    Buat kode OTP baru untuk user, matikan kode lama, lalu kirim ke emailnya.
    Mengembalikan True kalau email berhasil dikirim.
    """
    # Kode lama langsung dianggap terpakai supaya hanya ada satu kode aktif
    db.query(EmailVerification).filter(
        EmailVerification.user_id == user.id,
        EmailVerification.is_used == False,
    ).update({"is_used": True})

    now = datetime.utcnow()
    code = generate_verification_code()

    verification = EmailVerification(
        user_id=user.id,
        code_hash=hash_code(code),
        created_at=now,
        expires_at=now + timedelta(minutes=config.VERIFICATION_CODE_EXPIRE_MINUTES),
        attempts=0,
        is_used=False,
    )
    db.add(verification)
    db.commit()

    return send_verification_email(user.email, code)


# ── Register & Verifikasi ─────────────────────────────────────────────
@router.post("/register")
def register_user(data: UserRegister, db: Session = Depends(get_db)):
    # Cek apakah username sudah ada
    existing_user = db.query(User).filter(User.username == data.username).first()
    if existing_user and existing_user.is_verified:
        raise HTTPException(status_code=400, detail="Username sudah terdaftar")

    # Cek apakah email sudah dipakai akun lain
    existing_email = db.query(User).filter(User.email == data.email).first()
    if existing_email and existing_email.is_verified:
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")

    if existing_email and existing_user and existing_email.id != existing_user.id:
        raise HTTPException(
            status_code=400,
            detail="Username dan email dipakai oleh pendaftaran berbeda yang belum diverifikasi",
        )

    # Pendaftaran yang belum selesai diverifikasi boleh dilanjutkan/ditimpa
    new_user = existing_user or existing_email
    if new_user:
        new_user.username = data.username
        new_user.email = data.email
        new_user.password_hash = hash_password(data.password)
    else:
        new_user = User(
            username=data.username,
            email=data.email,
            password_hash=hash_password(data.password),
            is_verified=False,
        )
        db.add(new_user)

    db.commit()
    db.refresh(new_user)

    email_sent = _issue_verification_code(db, new_user)

    return {
        "message": "Kode verifikasi telah dikirim ke email Anda",
        "user_id": new_user.id,
        "email": new_user.email,
        "requires_verification": True,
        "email_sent": email_sent,
        "resend_cooldown": config.VERIFICATION_RESEND_COOLDOWN_SECONDS,
    }


@router.post("/verify-email")
def verify_email(data: VerifyEmailRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email tidak terdaftar")

    if user.is_verified:
        return {"message": "Email sudah terverifikasi", "user_id": user.id, "is_verified": True}

    verification = _active_verification(db, user.id)
    if not verification:
        raise HTTPException(
            status_code=400,
            detail="Kode verifikasi tidak ditemukan. Silakan kirim ulang kode.",
        )

    if datetime.utcnow() > verification.expires_at:
        verification.is_used = True
        db.commit()
        raise HTTPException(
            status_code=400,
            detail="Kode verifikasi sudah kedaluwarsa. Silakan kirim ulang kode.",
        )

    if verification.attempts >= config.VERIFICATION_MAX_ATTEMPTS:
        verification.is_used = True
        db.commit()
        raise HTTPException(
            status_code=429,
            detail="Terlalu banyak percobaan. Silakan kirim ulang kode.",
        )

    if verification.code_hash != hash_code(data.code):
        verification.attempts += 1
        db.commit()
        sisa = config.VERIFICATION_MAX_ATTEMPTS - verification.attempts
        raise HTTPException(
            status_code=400,
            detail=f"Kode verifikasi salah. Sisa percobaan: {sisa}",
        )

    verification.is_used = True
    user.is_verified = True
    db.commit()

    return {
        "message": "Verifikasi berhasil",
        "user_id": user.id,
        "is_verified": True,
    }


@router.post("/resend-code")
def resend_verification_code(data: ResendCodeRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email tidak terdaftar")

    if user.is_verified:
        raise HTTPException(status_code=400, detail="Email sudah terverifikasi")

    # Batasi frekuensi pengiriman ulang (default 60 detik)
    last = _active_verification(db, user.id)
    if last:
        elapsed = (datetime.utcnow() - last.created_at).total_seconds()
        remaining = int(config.VERIFICATION_RESEND_COOLDOWN_SECONDS - elapsed)
        if remaining > 0:
            raise HTTPException(
                status_code=429,
                detail=f"Tunggu {remaining} detik sebelum mengirim ulang kode",
            )

    email_sent = _issue_verification_code(db, user)
    if not email_sent:
        raise HTTPException(status_code=502, detail="Gagal mengirim email. Coba lagi nanti.")

    return {
        "message": "Kode verifikasi baru telah dikirim",
        "email": user.email,
        "resend_cooldown": config.VERIFICATION_RESEND_COOLDOWN_SECONDS,
    }


# ── Login ─────────────────────────────────────────────────────────────
@router.post("/login")
def login_user(data: UserAuth, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username, User.password_hash == hash_password(data.password)).first()
    if not user:
        raise HTTPException(status_code=401, detail="Username atau password salah")

    # Akun lama (tanpa email) tetap bisa masuk seperti biasa
    if user.email and not user.is_verified:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "EMAIL_NOT_VERIFIED",
                "email": user.email,
                "message": "Email belum diverifikasi. Silakan cek kode verifikasi Anda.",
            },
        )

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
