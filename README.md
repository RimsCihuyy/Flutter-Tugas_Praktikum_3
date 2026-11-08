# Pastel Toko - Products CRUD (Flutter + PHP/MySQL)

Tugas Pratikum 3 - Pemrograman Perangkat Bergerak.

Aplikasi Flutter untuk mengelola data produk dengan CRUD lengkap
(Create, Read, Update, Delete) yang terhubung ke backend REST API PHP + MySQL
yang dijalankan dengan Docker Compose.

## Struktur Repo

```text
.
├── lib/             # Kode aplikasi Flutter (main.dart)
├── backend/         # Backend PHP + MySQL (Docker Compose)
├── pubspec.yaml
└── README.md
```

## Fitur Aplikasi

- **Read**: daftar produk (grid), detail produk, pencarian, dan filter kategori.
- **Create**: tombol "Add product" membuka form tambah produk.
- **Update**: tombol edit (ikon pensil) di halaman detail.
- **Delete**: tombol hapus (ikon tempat sampah) di halaman detail, dengan konfirmasi.

## Endpoint API yang Dipakai

| Fitur | Method | Endpoint |
| --- | --- | --- |
| Daftar produk | GET | `/products?limit=0` |
| Tambah produk | POST | `/products/add` |
| Ubah produk | PATCH | `/products/{id}` |
| Hapus produk | DELETE | `/products/{id}` |

## Cara Menjalankan

### 1. Jalankan backend

Pastikan Docker Desktop sudah berjalan, lalu di folder `backend`:

```bash
cd backend
copy .env.example .env        # Windows (Linux/macOS: cp .env.example .env)
docker compose up -d --build
docker compose exec php php /var/www/html/seed.php
```

Perintah `seed.php` mengisi database dengan data produk dari DummyJSON
(butuh koneksi internet). Cek di browser: <http://localhost:8080/products>

Port yang dipakai: 8080 (API), 8081 (phpMyAdmin), 3306 (MySQL),
5672 dan 15672 (RabbitMQ). Pastikan tidak bentrok dengan container lain.

### 2. Jalankan aplikasi Flutter

Di folder utama repo:

```bash
flutter pub get
flutter run -d chrome
```

Alamat backend diatur di `lib/main.dart` pada `ProductService.host`:

- Chrome / desktop: `localhost`
- Android emulator: `10.0.2.2`
- HP asli: IP laptop di jaringan WiFi yang sama

Untuk Android, tambahkan izin internet dan
`android:usesCleartextTraffic="true"` di `AndroidManifest.xml`
karena API memakai HTTP.

## Video Demo

<!-- Isi dengan link YouTube jika diminta -->

## Identitas

- Nama: Shorim
- Kelas: IF24B
- NIM: 240102123