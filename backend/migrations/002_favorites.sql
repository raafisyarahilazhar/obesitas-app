-- Migrasi: halaman Favorit
--
-- Favorit TIDAK punya tabel daftar makanan — daftarnya dihitung on the fly
-- dari tabel `meal_logs` (makanan yang discan minimal 5x).
-- Tabel di bawah hanya mencatat makanan yang sengaja disembunyikan user
-- lewat menu "Hapus dari Favorit", supaya riwayat makannya tetap utuh.
--
-- Tabel ini otomatis dibuat saat server FastAPI dijalankan
-- (Base.metadata.create_all di app.py). Skrip ini hanya untuk pembuatan manual.

CREATE TABLE IF NOT EXISTS favorite_exclusions (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT          NOT NULL,
    food_name  VARCHAR(100) NOT NULL,
    created_at DATETIME     NOT NULL,
    INDEX ix_favorite_exclusions_user_id (user_id),
    CONSTRAINT fk_favorite_exclusions_user
        FOREIGN KEY (user_id) REFERENCES users (id)
);
