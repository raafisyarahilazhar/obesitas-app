-- Migrasi: fitur Verifikasi Email saat registrasi
-- Jalankan sekali di database `foodscan_obesity` (mis. lewat phpMyAdmin / MySQL CLI):
--   mysql -u root foodscan_obesity < migrations/001_email_verification.sql
--
-- Tabel `email_verifications` otomatis dibuat saat server FastAPI dijalankan
-- (Base.metadata.create_all di app.py), tapi kolom baru pada tabel `users`
-- harus ditambahkan manual lewat skrip ini.

ALTER TABLE users
    ADD COLUMN email VARCHAR(255) NULL AFTER username,
    ADD COLUMN is_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER password_hash;

ALTER TABLE users
    ADD UNIQUE INDEX ix_users_email (email);

-- Akun lama (belum punya email) tetap bisa login seperti biasa.
UPDATE users SET is_verified = 1 WHERE email IS NULL;

-- Tabel kode OTP (kalau ingin dibuat manual, tanpa menjalankan server dulu)
CREATE TABLE IF NOT EXISTS email_verifications (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT          NOT NULL,
    code_hash   VARCHAR(255) NOT NULL,
    created_at  DATETIME     NOT NULL,
    expires_at  DATETIME     NOT NULL,
    attempts    INT          NOT NULL DEFAULT 0,
    is_used     TINYINT(1)   NOT NULL DEFAULT 0,
    INDEX ix_email_verifications_user_id (user_id),
    CONSTRAINT fk_email_verifications_user
        FOREIGN KEY (user_id) REFERENCES users (id)
);
