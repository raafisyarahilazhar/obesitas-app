from PIL import Image

def detect_multiple(model, image):
    # KUNCI: Turunkan ke 0.1 untuk testing, dan hidupkan verbose
    results = model.predict(image, conf=0.1, verbose=True) 
    detections = []
    
    model_names = model.names 

    print("\n--- MEMULAI DETEKSI YOLO ---")
    for r in results:
        for box in r.boxes:
            conf = float(box.conf[0])
            cls_id = int(box.cls[0])
            label = model_names[cls_id] 
            coords = box.xyxy[0].tolist()
            
            # Print langsung ke terminal agar kita tahu AI melihat apa
            print(f"🤖 YOLO MENDETEKSI: '{label}' dengan yakin {conf*100:.1f}%")
            
            detections.append({
                "label": label,
                "confidence": conf,
                "bbox": coords
            })
            
    print(f"--- TOTAL OBJEK YOLO: {len(detections)} ---\n")
    return detections