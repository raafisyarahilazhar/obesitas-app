from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import semua router
from routers import auth, dashboard, scanner, meals

# IMPORT FUNGSI LOAD CSV DI SINI
from services.nutrition_service import load_nutrition_database

# Import model & engine untuk membuat tabel yang belum ada (mis. email_verifications)
from core.database import Base, engine
from core import models  # noqa: F401  (memastikan semua model terdaftar di Base)

app = FastAPI(
    title="Hybrid Food AI (Diabetic & Obesity Focus)",
    description="Backend terstruktur untuk pendeteksi makanan, pelacakan gizi, dan rekomendasi klinis.",
    version="3.0.0"
)

# Konfigurasi CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# PANGGIL FUNGSI LOAD CSV DI SINI (Sebelum me-load router)
load_nutrition_database()

# Buat tabel yang belum ada (tabel lama tidak diubah)
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"[DB] Gagal menyiapkan tabel database: {e}")

# Daftarkan Router ke aplikasi utama
app.include_router(auth.router)
app.include_router(dashboard.router)
app.include_router(scanner.router)
app.include_router(meals.router)

@app.get("/", tags=["Health Check"])
def read_root():
    return {
        "status": "Online",
        "message": "Server FoodScan API Berjalan Sempurna!",
        "endpoints": ["/auth", "/dashboard", "/scan", "/meals"]
    }