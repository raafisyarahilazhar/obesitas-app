import re
from pydantic import BaseModel, Field, field_validator
from typing import Optional

# Validasi email sederhana (tanpa dependency tambahan seperti email-validator)
EMAIL_REGEX = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")


def normalize_email(value: str) -> str:
    value = (value or "").strip().lower()
    if not EMAIL_REGEX.match(value):
        raise ValueError("Format email tidak valid")
    return value


# Skema untuk Login (tetap pakai username + password)
class UserAuth(BaseModel):
    username: str
    password: str

# Skema untuk Register (sekarang butuh email untuk verifikasi)
class UserRegister(UserAuth):
    email: str

    @field_validator("email")
    @classmethod
    def check_email(cls, v: str) -> str:
        return normalize_email(v)

# Skema untuk input kode OTP dari halaman Verifikasi Email
class VerifyEmailRequest(BaseModel):
    email: str
    code: str

    @field_validator("email")
    @classmethod
    def check_email(cls, v: str) -> str:
        return normalize_email(v)

    @field_validator("code")
    @classmethod
    def strip_code(cls, v: str) -> str:
        return (v or "").strip().replace(" ", "")

# Skema untuk tombol "Kirim Ulang"
class ResendCodeRequest(BaseModel):
    email: str

    @field_validator("email")
    @classmethod
    def check_email(cls, v: str) -> str:
        return normalize_email(v)

# Skema untuk input Profil Kesehatan Obesitas
class HealthProfileCreate(BaseModel):
    name: str
    # Batas wajar agar perhitungan BMR/BMI tidak dijalankan pada data mustahil
    age: int = Field(..., ge=1, le=120)
    height_cm: float = Field(..., ge=50, le=250)
    weight_kg: float = Field(..., ge=10, le=300)

# Skema untuk Response Profil agar aman (tidak memunculkan password)
class HealthProfileResponse(HealthProfileCreate):
    bmi: float
    daily_calories_target: int

    class Config:
        from_attributes = True
