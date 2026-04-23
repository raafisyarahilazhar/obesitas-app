from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from starlette.concurrency import run_in_threadpool
from sqlalchemy.orm import Session
from PIL import Image
import io

from core.database import get_db
from core.models import HealthProfile

# Menggunakan 1 model utama yang berisi 29 kelas makanan
from core.model_indonesian_food_v1 import yolo_food_model 

from services.detection_service import detect_multiple
from services.nutrition_service import get_nutrition
from services.portion_service import estimate_weight, calculate_nutrition_by_weight

router = APIRouter(prefix="/scan", tags=["AI Scanner"])

def calculate_iou(box1, box2):
    """Fungsi NMS untuk mencegah kotak deteksi ganda pada 1 makanan"""
    x1, y1 = max(box1[0], box2[0]), max(box1[1], box2[1])
    x2, y2 = min(box1[2], box2[2]), min(box1[3], box2[3])
    
    intersection = max(0, x2 - x1) * max(0, y2 - y1)
    area1 = (box1[2] - box1[0]) * (box1[3] - box1[1])
    area2 = (box2[2] - box2[0]) * (box2[3] - box2[1])
    union = area1 + area2 - intersection
    return intersection / union if union > 0 else 0

@router.post("/")
async def scan_food(
    file: UploadFile = File(...), 
    user_id: int = Form(...), 
    db: Session = Depends(get_db)
):
    # 1. AMBIL DATA PASIEN (Termasuk Target Kalori & BMI)
    profile = db.query(HealthProfile).filter(HealthProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil kesehatan tidak ditemukan. Silakan isi data diri terlebih dahulu.")

    # 2. BACA GAMBAR KAMERA
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"File gambar tidak valid: {str(e)}")

    # 3. DETEKSI YOLO (1 Model Saja)
    raw_detections = await run_in_threadpool(detect_multiple, yolo_food_model, image)
    all_raw = sorted(raw_detections, key=lambda x: x["confidence"], reverse=True)

    # 4. FILTER NMS
    final_filtered = []
    for d in all_raw:
        keep = True
        for f in final_filtered:
            if calculate_iou(d["bbox"], f["bbox"]) > 0.5:
                keep = False
                break
        if keep: 
            final_filtered.append(d)

    # ---------------------------------------------------------
    # 5. ALGORITMA "AI NUTRITIONIST" (FOKUS OBESITAS & DEFISIT)
    # ---------------------------------------------------------
    
    # A. Tentukan Jatah Kalori per 1x Makan
    # Normalnya 30% dari total harian. TAPI jika Obesitas (BMI >= 30), jatah diperketat jadi 25%.
    persentase_budget = 0.25 if profile.bmi >= 30.0 else 0.30 
    meal_budget_kcal = profile.daily_calories_target * persentase_budget
    
    # B. Kumpulkan data mentah makanan di piring
    detected_items_data = []
    total_standard_calories = 0.0
    
    for det in final_filtered:
        label_yolo = det["label"]
        nutrition_base = get_nutrition(label_yolo)
        
        if not nutrition_base: 
            continue # Abaikan jika makanan belum terdaftar di CSV
            
        weight_std = estimate_weight(det["bbox"], image.size, label_yolo)
        nutrition_std = calculate_nutrition_by_weight(nutrition_base, weight_std)
        
        cal_std = nutrition_std["calories"]
        total_standard_calories += cal_std
        
        detected_items_data.append({
            "label": label_yolo,
            "confidence": det["confidence"],
            "base_nutrition": nutrition_base,
            "standard_weight": weight_std,
            "medical_status_asli": nutrition_std.get("medical_status", "Aman")
        })

    # C. Hitung Rasio Pemotongan Porsi
    ratio = 1.0
    # Jika total kalori di piring melebihi jatah makan 1x makan, AI akan memotong porsi
    if total_standard_calories > meal_budget_kcal and total_standard_calories > 0:
        ratio = meal_budget_kcal / total_standard_calories

    # D. Bangun JSON Output Final
    results = []
    for item in detected_items_data:
        # Hitung berat anjuran (Dibulatkan ke puluhan terdekat agar tidak aneh, misal 83g jadi 80g)
        recommended_weight = max(10, int(round((item["standard_weight"] * ratio) / 10) * 10))
        
        # Kalkulasi ulang gizi berdasarkan berat anjuran AI
        final_nutrition = calculate_nutrition_by_weight(item["base_nutrition"], recommended_weight)
        original_status = item["medical_status_asli"]
        
        # MANIPULASI TEKS UNTUK FLUTTER: 
        # Jika porsi dipotong, paksa sisipkan kata "Batasi Porsi" agar UI Flutter berubah Oranye
        if ratio < 1.0:
            ai_advice = f"Batasi Porsi (AI memotong porsi dari {item['standard_weight']}g menjadi {recommended_weight}g agar Anda tidak over-kalori. {original_status})"
        else:
            ai_advice = original_status

        results.append({
            "food_name": item["label"],
            "confidence": round(item["confidence"], 4),
            # Kita langsung timpa estimasi berat dengan BERAT ANJURAN AI.
            # Jadi saat user klik "Simpan ke Jurnal", data diet sehat inilah yang tersimpan.
            "estimated_weight_grams": recommended_weight, 
            "nutrition_facts": {
                "calories": final_nutrition["calories"],
                "carbohydrates": final_nutrition["carbohydrates"]
            },
            "medical_status": ai_advice
        })

    return {
        "status": "success", 
        "total_detected": len(results),
        "detailed_data": results
    }