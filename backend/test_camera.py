import cv2
from PIL import Image

from core.model import yolo_model
from services.detection_service import detect_multiple
from services.clip_service import classify_food

cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    image = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

    # ================= YOLO MULTI =================
    detections = detect_multiple(yolo_model, image)

    if not detections:
        cv2.putText(frame, "No detection", (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    for det in detections:
        cropped = det["crop"]
        xmin, ymin, xmax, ymax = det["bbox"]

        # ================= CLIP =================
        result = classify_food(cropped)

        label = f"{result['label']} ({round(result['confidence'],2)})"

        # ================= DRAW BOX =================
        cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), (0,255,0), 2)

        cv2.putText(
            frame,
            label,
            (xmin, ymin - 10),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 255, 0),
            2
        )

    cv2.imshow("Food Detection Multi", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()