import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Update dengan nama file model yang baru
# MODEL_PATH_FINDER = os.path.join(BASE_DIR, "ml", "food_finder.pt")
# MODEL_PATH_COMBINATION = os.path.join(BASE_DIR, "ml", "food_combination.pt")
# MODEL_PATH_FOOD = os.path.join(BASE_DIR, "ml", "food_v1.pt")
MODEL_PATH_FOOD = os.path.join(BASE_DIR, "ml", "last_best.pt")

# Pertahankan threshold di 45% agar tidak mendeteksi objek sembarangan
CONFIDENCE_THRESHOLD = 0.45
CLIP_CONFIDENCE_THRESHOLD = 0.2


# ── Loader .env sederhana (tanpa library tambahan) ────────────────────
def _load_dotenv():
    """Baca file backend/.env (kalau ada) dan masukkan ke os.environ."""
    env_path = os.path.join(BASE_DIR, ".env")
    if not os.path.exists(env_path):
        return
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_dotenv()


# ── Konfigurasi Verifikasi Email ──────────────────────────────────────
# Isi lewat file backend/.env supaya kredensial tidak ikut ter-commit.
# Contoh untuk Gmail (wajib pakai App Password, bukan password akun):
#   SMTP_HOST=smtp.gmail.com
#   SMTP_PORT=587
#   SMTP_USER=emailanda@gmail.com
#   SMTP_PASSWORD=xxxxxxxxxxxxxxxx
#   SMTP_FROM_NAME=FoodScan AI
SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "").strip()
# Google menampilkan App Password sebagai "abcd efgh ijkl mnop".
# Spasinya hanya untuk kemudahan membaca dan HARUS dibuang saat login SMTP,
# kalau tidak Gmail menolak dengan error 535 BadCredentials.
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "").replace(" ", "")
SMTP_FROM_EMAIL = os.getenv("SMTP_FROM_EMAIL", SMTP_USER)
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "FoodScan AI")
SMTP_USE_TLS = os.getenv("SMTP_USE_TLS", "true").lower() == "true"   # STARTTLS (port 587)
SMTP_USE_SSL = os.getenv("SMTP_USE_SSL", "false").lower() == "true"  # SSL langsung (port 465)

# Aturan kode OTP
VERIFICATION_CODE_LENGTH = 6
VERIFICATION_CODE_EXPIRE_MINUTES = 10   # kode kedaluwarsa setelah 10 menit
VERIFICATION_MAX_ATTEMPTS = 5           # maksimal salah input per kode
VERIFICATION_RESEND_COOLDOWN_SECONDS = 60  # jeda tombol "Kirim Ulang" (00:59 di UI)

# Kalau SMTP belum dikonfigurasi, kode OTP hanya dicetak di terminal server
# supaya alur registrasi tetap bisa dites saat development.
EMAIL_DEV_MODE = not bool(SMTP_HOST and SMTP_USER and SMTP_PASSWORD)
