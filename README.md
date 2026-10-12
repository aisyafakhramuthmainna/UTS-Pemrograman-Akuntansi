# UTS Pemrograman Akuntansi

## Voucher Kas Keluar dan Pengelolaan Persediaan

Proyek ini dibuat untuk memenuhi tugas Ujian Tengah Semester (UTS) mata kuliah Pemrograman Akuntansi.

### 1. Fitur Aplikasi

- Formulir Voucher Kas Keluar.
- Pemilihan akun pada rincian jurnal.
- Pengisian nilai debit dan kredit.
- Pemeriksaan keseimbangan debit dan kredit pada antarmuka aplikasi.

### 2. Struktur Proyek

```text
UTS-Pemrograman-Akuntansi/
├── src/
│   ├── App.jsx
│   ├── main.jsx
│   └── styles.css
├── supabase/
│   └── sql/
│       ├── 01_accounting_schema.sql
│       ├── 02_inventory_trigger.sql
│       └── 03_test_inventory_trigger.sql
├── .env.example
├── .gitignore
├── index.html
├── package.json
└── package-lock.json
```

### 3. Database

Folder `supabase/sql/` berisi:

- `01_accounting_schema.sql`: skema database akuntansi.
- `02_inventory_trigger.sql`: trigger untuk memperbarui stok persediaan dan memvalidasi transaksi.
- `03_test_inventory_trigger.sql`: skrip pengujian trigger persediaan.

### 4. Menjalankan Aplikasi

Pastikan Node.js sudah terpasang, kemudian jalankan perintah berikut di terminal:

```bash
npm install
npm run dev
```

Buka alamat lokal yang ditampilkan oleh Vite di terminal.

### 5. Konfigurasi Supabase

Salin `.env.example` menjadi `.env`, kemudian isi konfigurasi sesuai proyek Supabase yang digunakan. Jangan mengunggah file `.env`, password database, atau secret key ke repository publik.

### 6. Pengujian

Pengujian trigger persediaan mencakup pembelian, penjualan, penolakan penjualan melebihi stok, dan penolakan penyesuaian yang menyebabkan stok negatif.

### 7. Repository

https://github.com/aisyafakhramuthmainna/UTS-Pemrograman-Akuntansi

---

**Catatan:** Koneksi langsung aplikasi ke Supabase dan penyimpanan voucher perlu diverifikasi secara terpisah sebelum dinyatakan sebagai fitur yang telah berjalan.
