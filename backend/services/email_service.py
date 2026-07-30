import smtplib
import ssl
import secrets
from email.message import EmailMessage

from core import config


def generate_verification_code(length: int = None) -> str:
    """Buat kode OTP numerik acak (default 6 digit)."""
    length = length or config.VERIFICATION_CODE_LENGTH
    return "".join(str(secrets.randbelow(10)) for _ in range(length))


def _build_message(to_email: str, code: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = f"{code} adalah kode verifikasi FoodScan AI Anda"
    msg["From"] = f"{config.SMTP_FROM_NAME} <{config.SMTP_FROM_EMAIL}>"
    msg["To"] = to_email

    minutes = config.VERIFICATION_CODE_EXPIRE_MINUTES

    msg.set_content(
        f"Halo,\n\n"
        f"Kode verifikasi akun FoodScan AI Anda adalah: {code}\n\n"
        f"Kode ini berlaku selama {minutes} menit.\n"
        f"Abaikan email ini jika Anda tidak mendaftar di FoodScan AI.\n\n"
        f"Salam sehat,\nTim FoodScan AI"
    )

    # Versi HTML mengikuti gaya aplikasi (merah #D32F2F)
    msg.add_alternative(
        f"""\
<html>
  <body style="margin:0;padding:24px;background:#F7F7F7;
               font-family:Segoe UI,Helvetica,Arial,sans-serif;color:#1C1C1E;">
    <div style="max-width:480px;margin:0 auto;background:#FFFFFF;border-radius:20px;overflow:hidden;
                box-shadow:0 8px 32px rgba(0,0,0,0.08);">
      <div style="background:linear-gradient(135deg,#D32F2F,#7F0000);padding:32px 28px;">
        <h1 style="margin:0;color:#FFFFFF;font-size:22px;font-weight:800;">FoodScan AI</h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.8);font-size:13px;">
          Verifikasi alamat email Anda
        </p>
      </div>
      <div style="padding:28px;">
        <p style="margin:0 0 8px;font-size:15px;font-weight:700;">Verifikasi Email</p>
        <p style="margin:0 0 20px;font-size:13px;color:#8E8E93;line-height:1.6;">
          Masukkan kode di bawah ini pada aplikasi untuk menyelesaikan pendaftaran akun Anda.
        </p>
        <div style="background:#FFEBEE;border-radius:14px;padding:18px;text-align:center;">
          <span style="font-size:30px;font-weight:800;letter-spacing:10px;color:#D32F2F;">{code}</span>
        </div>
        <p style="margin:20px 0 0;font-size:12px;color:#8E8E93;line-height:1.6;">
          Kode berlaku selama {minutes} menit. Jangan bagikan kode ini kepada siapa pun.
          Abaikan email ini jika Anda tidak merasa mendaftar.
        </p>
      </div>
    </div>
  </body>
</html>""",
        subtype="html",
    )

    return msg


def send_verification_email(to_email: str, code: str) -> bool:
    """
    Kirim kode OTP ke email user.

    Kalau SMTP belum dikonfigurasi (EMAIL_DEV_MODE), kode dicetak di terminal
    server supaya alur registrasi tetap bisa diuji saat development.
    """
    if config.EMAIL_DEV_MODE:
        print("=" * 60)
        print("[DEV MODE] SMTP belum dikonfigurasi di backend/.env")
        print(f"   Kode verifikasi untuk {to_email} : {code}")
        print(f"   Berlaku {config.VERIFICATION_CODE_EXPIRE_MINUTES} menit.")
        print("=" * 60)
        return True

    msg = _build_message(to_email, code)

    try:
        if config.SMTP_USE_SSL:
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL(config.SMTP_HOST, config.SMTP_PORT, context=context, timeout=20) as server:
                server.login(config.SMTP_USER, config.SMTP_PASSWORD)
                server.send_message(msg)
        else:
            with smtplib.SMTP(config.SMTP_HOST, config.SMTP_PORT, timeout=20) as server:
                server.ehlo()
                if config.SMTP_USE_TLS:
                    server.starttls(context=ssl.create_default_context())
                    server.ehlo()
                server.login(config.SMTP_USER, config.SMTP_PASSWORD)
                server.send_message(msg)

        print(f"[EMAIL] Kode verifikasi terkirim ke {to_email}")
        return True

    except Exception as e:
        print(f"[EMAIL] Gagal mengirim email ke {to_email}: {e}")
        return False
