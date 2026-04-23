def estimate_weight(bbox, image_size, food_type):
    # Standar porsi per 1 sajian (dalam gram) disesuaikan dengan 29 nama YOLO
    standard_serving_weight = {
        "Apple": 150, "Ayam Goreng": 100, "Bakso": 200, "Banana": 118,
        "Burger": 150, "Capcay": 150, "Chocolate Chip Cookie": 30,
        "Donat": 50, "Ikan Goreng": 100, "Kentang Goreng": 100,
        "Kiwi": 70, "Mie Goreng": 150, "Nasi Goreng": 200, "Nasi Putih": 150,
        "Nugget": 100, "Pempek": 150, "Pineapples": 100, "Pizza": 120,
        "Rendang Sapi": 100, "Sate": 150, "Spaghetti": 150, "Steak": 150,
        "Strawberry": 50, "Tahu Goreng": 50, "Telur Goreng": 50,
        "Telur Rebus": 50, "Tempe Goreng": 50, "Terong Balado": 100,
        "Tumis Kangkung": 100
    }
    return standard_serving_weight.get(food_type, 100) 

def calculate_nutrition_by_weight(nutrition, weight_grams):
    factor = weight_grams / 100.0
    return {
        "calories": round(nutrition["calories"] * factor, 1),
        "carbohydrates": round(nutrition["carbs"] * factor, 1),
        # Mengambil status medis langsung dari CSV
        "medical_status": nutrition.get("medical_status", "Aman") 
    }