from sqlalchemy import Column, Integer, String, Float, ForeignKey, Date, Time, Boolean, DateTime
from sqlalchemy.orm import relationship
from core.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    # nullable=True agar akun lama (sebelum fitur verifikasi) tetap valid
    email = Column(String(255), unique=True, index=True, nullable=True)
    password_hash = Column(String(255), nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    health_profile = relationship("HealthProfile", back_populates="owner", uselist=False)
    meal_logs = relationship("MealLog", back_populates="owner") # Relasi ke jurnal
    verifications = relationship(
        "EmailVerification", back_populates="owner", cascade="all, delete-orphan"
    )

# --- TABEL KODE VERIFIKASI EMAIL ---
class EmailVerification(Base):
    __tablename__ = "email_verifications"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)

    code_hash = Column(String(255), nullable=False)  # kode OTP tidak disimpan polos
    created_at = Column(DateTime, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, default=0, nullable=False)
    is_used = Column(Boolean, default=False, nullable=False)

    owner = relationship("User", back_populates="verifications")

class HealthProfile(Base):
    __tablename__ = "health_profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    name = Column(String(100), nullable=False)
    age = Column(Integer, nullable=False)
    height_cm = Column(Float, nullable=False)
    weight_kg = Column(Float, nullable=False)
    bmi = Column(Float, nullable=True)
    daily_calories_target = Column(Integer, nullable=True)
    owner = relationship("User", back_populates="health_profile")

# --- TAMBAHKAN TABEL INI ---
class MealLog(Base):
    __tablename__ = "meal_logs"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    date = Column(Date, nullable=False)
    time = Column(Time, nullable=False)
    
    food_name = Column(String(100), nullable=False)
    weight_grams = Column(Float, nullable=False)
    calories = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)
    
    owner = relationship("User", back_populates="meal_logs")

# --- MAKANAN YANG DISEMBUNYIKAN DARI DAFTAR FAVORIT ---
# Favorit dihitung otomatis dari jumlah scan, jadi "Hapus dari Favorit"
# dicatat sebagai pengecualian, bukan menghapus riwayat makan.
class FavoriteExclusion(Base):
    __tablename__ = "favorite_exclusions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    food_name = Column(String(100), nullable=False)
    created_at = Column(DateTime, nullable=False)