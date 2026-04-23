from pydantic import BaseModel
from typing import Optional

# Skema untuk Register & Login
class UserAuth(BaseModel):
    username: str
    password: str

# Skema untuk input Profil Kesehatan Obesitas
class HealthProfileCreate(BaseModel):
    name: str
    age: int
    height_cm: float
    weight_kg: float

# Skema untuk Response Profil agar aman (tidak memunculkan password)
class HealthProfileResponse(HealthProfileCreate):
    bmi: float
    daily_calories_target: int
    
    class Config:
        from_attributes = True