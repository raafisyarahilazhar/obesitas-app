from sqlalchemy import Column, Integer, String, Float, ForeignKey, Date, Time
from sqlalchemy.orm import relationship
from core.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    health_profile = relationship("HealthProfile", back_populates="owner", uselist=False)
    meal_logs = relationship("MealLog", back_populates="owner") # Relasi ke jurnal

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