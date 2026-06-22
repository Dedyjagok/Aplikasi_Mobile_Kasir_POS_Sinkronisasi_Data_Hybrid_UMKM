    # Rancangan Implementasi Teknis — POS Warung 3D Water RO
    ### (Revisi v1.1 — Pemisahan Modul POS & Refill Air RO)

    > **Versi:** 1.1.0 | **Tanggal:** 15 Mei 2026 | **Platform:** Flutter (Android)

    ---

    ## Tinjauan Dua Modul Utama

    Aplikasi ini terdiri dari **dua modul yang sepenuhnya terpisah** dan tidak saling bergantung satu sama lain:

    ```mermaid
    graph TB
        App["📱 Aplikasi Kasir\nWarung 3D Water RO"]
        App --> POS["🛒 Modul POS Produk\n(Kasir Barang Kelontong)"]
        App --> RO["💧 Modul Refill Air RO\n(Pencatatan Isi Ulang)"]

        POS --> P1["Katalog Produk"]
        POS --> P2["Keranjang Belanja"]
        POS --> P3["Proses Bayar & Kembalian"]
        POS --> P4["Cetak Struk Bluetooth"]
        POS --> P5["Riwayat Transaksi Produk"]

        RO --> R1["Catat Satu Transaksi Refill"]
        RO --> R2["Pilih Volume (5L / 10L / 15L / Galon)"]
        RO --> R3["Harga Otomatis per Volume"]
        RO --> R4["Riwayat Refill Harian"]
        RO --> R5["Rekap & Total Penjualan Bulanan"]

        style POS fill:#1a73e8,color:#fff
        style RO fill:#00897b,color:#fff
        style App fill:#37474f,color:#fff
    ```

    > [!IMPORTANT]
    > **Modul POS Produk** = Kasir normal seperti minimarket. Ada keranjang, scan/pilih produk, total, bayar, cetak struk.
    >
    > **Modul Refill Air RO** = Pencatatan sederhana. Setiap pelanggan datang isi ulang → catat 1 entry (volume + harga). Di akhir bulan, lihat rekap total penjualan refill.

    ---

    ## 1. Daftar Library (Dependencies) Flutter

    | Kategori | Nama Library | Versi | Fungsi Utama |
    |---|---|---|---|
    | **Core Firebase** | `firebase_core` | `^3.x` | Inisialisasi dasar seluruh layanan Firebase |
    | **Database Cloud** | `cloud_firestore` | `^5.x` | Sinkronisasi data ke cloud |
    | **Autentikasi** | `firebase_auth` | `^5.x` | Login pemilik (Email & Password) |
    | **Cloud Messaging** | `firebase_messaging` | `^15.x` | Notifikasi push ke HP pemilik |
    | **Database Lokal** | `sqflite` | `^2.x` | Database SQLite di perangkat (offline-first) |
    | **Path Helper** | `path` | `^1.x` | Menentukan lokasi file SQLite |
    | **Status Koneksi** | `connectivity_plus` | `^6.x` | Deteksi internet untuk sinkronisasi |
    | **Cetak Struk** | `blue_thermal_printer` | `^1.x` | Printer thermal Bluetooth 58mm (ESC/POS) |
    | **Format Data** | `intl` | `^0.19.x` | Format mata uang IDR, tanggal, bulan |
    | **State Management** | `provider` | `^6.x` | Aliran data antara database dan UI |
    | **Langganan (IAP)** | `purchases_flutter` | `^6.x` | Integrasi In-App Purchases via RevenueCat |
    | **Grafik / Chart** | `fl_chart` | `^0.6x.x` | Membuat grafik visual (Bar Chart) statistik produk |

    ### Konfigurasi `pubspec.yaml`

    ```yaml
    dependencies:
    flutter:
        sdk: flutter
    firebase_core: ^3.6.0
    cloud_firestore: ^5.4.4
    firebase_auth: ^5.3.1
    firebase_messaging: ^15.1.3
    sqflite: ^2.3.3+1
    path: ^1.9.0
    connectivity_plus: ^6.0.5
    blue_thermal_printer: ^1.1.2
    intl: ^0.19.0
    provider: ^6.1.2
    cupertino_icons: ^1.0.8
    purchases_flutter: ^6.6.0
    ```

    ---

    ## 2. Autentikasi & Role-Based Access (Firebase Auth)

    Sistem ini membedakan peran (Role) antara dua tipe pengguna untuk menjaga keamanan dan kerapian data:

    - **Owner (Pemilik)**: Memiliki akses penuh ke sistem. Berwenang melihat semua riwayat/rekap transaksi, mengatur CMS barang baru, mengatur CMS harga refill, serta CMS detail struk.
    - **Kasir (Staf)**: Memiliki akses terbatas yang berfokus pada operasional. Hanya dapat mengakses Modul POS (transaksi penjualan & cetak struk) dan Modul Refill (input catatan isi ulang air).

    - **Metode:** Hybrid (Firebase Auth untuk Aktivasi Perangkat, Sistem Profil PIN untuk operasional harian)
    - **Alur:**
      1. **Aktivasi Perangkat:** Owner melakukan *login* 1x menggunakan Email & Password Firebase (melalui `LoginScreen`). Setelah itu sesi tersimpan permanen.
      2. **Operasional Harian:** Setiap aplikasi dibuka, akan muncul `LockScreen` (Layar Pilih Profil). Kasir memilih namanya dan memasukkan **PIN 4 Digit** yang telah diatur oleh Owner di menu Pengaturan. Owner juga bisa login dari Lock Screen menggunakan *password* Firebase.
      3. **Masuk Aplikasi:** Berdasarkan PIN/Profil yang dipilih, aplikasi menyesuaikan fitur yang bisa diakses (Home).

    ### File Terkait
    #### [NEW] `lib/screens/auth/login_screen.dart` (Khusus aktivasi owner)
    #### [NEW] `lib/screens/auth/lock_screen.dart` (Gerbang harian kasir/owner)
    #### [NEW] `lib/services/auth_service.dart`
    #### [MODIFY] `lib/main.dart` — Routing berlapis (auth.isLoggedIn -> session.isActive -> Home)

    ---

    ## 3. MODUL 1 — POS Produk (Kasir Barang Kelontong)

    ### Cara Kerja
    Kasir membuka layar POS → memilih produk dari katalog → produk masuk keranjang → hitung total → input uang bayar → hitung kembalian → simpan transaksi → cetak struk (opsional).

    ### Alur Transaksi POS

    ```mermaid
    sequenceDiagram
        participant K as Kasir
        participant App as Layar POS
        participant DB as SQLite Lokal
        participant P as Printer Bluetooth

        K->>App: Pilih Produk dari Katalog
        App->>App: Tambah ke Keranjang
        K->>App: Tekan "Bayar"
        App-->>K: Input Nominal Uang Diterima
        App->>App: Hitung Kembalian
        App->>DB: Simpan Transaksi (is_synced=false)
        App->>DB: Kurangi Stok Produk
        K->>App: Tekan "Cetak Struk"
        App->>P: Kirim Data ESC/POS via Bluetooth
        P-->>K: 🖨️ Struk Tercetak
    ```

    ### Skema Database SQLite — Modul POS

    ```sql
    -- Kategori Produk
    CREATE TABLE categories (
      id            TEXT PRIMARY KEY,
      user_id       TEXT NOT NULL,
      name          TEXT NOT NULL,
      updated_at    TEXT
    );

    -- Katalog Produk
    CREATE TABLE products (
      id            TEXT PRIMARY KEY,
      user_id       TEXT NOT NULL,
      name          TEXT NOT NULL,
      category_id   TEXT,
      cost_price    INTEGER NOT NULL,
      sell_price    INTEGER NOT NULL,
      stock         INTEGER NOT NULL DEFAULT 0,
      low_stock_threshold INTEGER DEFAULT 5,
      updated_at    TEXT,
      FOREIGN KEY (category_id) REFERENCES categories(id)
    );

    -- Header Transaksi Produk
    CREATE TABLE pos_transactions (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    timestamp       TEXT NOT NULL,
    total_amount    INTEGER NOT NULL,
    cash_received   INTEGER NOT NULL,
    change_amount   INTEGER NOT NULL,
    payment_method  TEXT DEFAULT 'Tunai',
    is_synced       INTEGER DEFAULT 0   -- 0=false, 1=true
    );

    -- Detail Item Transaksi
    CREATE TABLE pos_transaction_items (
    id                 TEXT PRIMARY KEY,
    transaction_id     TEXT NOT NULL,
    product_id         TEXT NOT NULL,
    product_name       TEXT NOT NULL,
    qty                INTEGER NOT NULL,
    unit_price         INTEGER NOT NULL,
    subtotal           INTEGER NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES pos_transactions(id)
    );

    -- Akun Kasir (Sistem PIN)
    CREATE TABLE cashiers (
      id            TEXT PRIMARY KEY,
      user_id       TEXT NOT NULL,
      name          TEXT NOT NULL,
      pin           TEXT NOT NULL,
      is_active     INTEGER DEFAULT 1
    );
    ```

    ### Struktur Collection Firestore — Multi-Tenancy

    ```text
    Firestore/
    ├── users/
    │   └── {uid} (ID Pemilik Toko)
    │       └── profile: { name, email, isPremium, dll }
    ├── product_categories/
    │   └── {category_id}
    │       ├── user_id: {uid}
    │       ├── name: "Snack"
    │       └── updated_at: Timestamp
    ├── products/
    │   └── {product_id}
    │       ├── user_id: {uid}
    │       ├── name, category_id, cost_price, sell_price, stock, dll
    │       └── updated_at: Timestamp
    ├── pos_transactions/
    │   └── {transaction_id}
    │       ├── user_id: {uid}
    │       ├── timestamp, total_amount, cash_received, dll
    │       └── items: [ { product_id, product_name, qty, unit_price, subtotal } ]
    ```

    ### Format Struk Thermal 58mm

    ```
    ================================
        WARUNG 3D WATER RO
    Jl. [Alamat Lengkap Toko]
        Telp: 08xx-xxxx-xxxx
    ================================
    No: TRX-20260515-001
    Tgl: 15/05/2026  14:30 WIB
    --------------------------------
    Snack Chitato
    2 x Rp  8.000   Rp  16.000
    Minuman Teh Kotak
    3 x Rp  5.000   Rp  15.000
    --------------------------------
    TOTAL          :  Rp  31.000
    TUNAI          :  Rp  50.000
    KEMBALIAN      :  Rp  19.000
    ================================
        Terima Kasih! 🙏
    Silakan Datang Kembali
    ================================
    ```

    ### Screen & File — Modul POS

    | File | Deskripsi |
    |---|---|
    | `lib/screens/pos/pos_screen.dart` | Layar kasir utama — grid/list pilih produk |
    | `lib/screens/pos/cart_screen.dart` | Keranjang belanja, input bayar, hitung kembalian |
    | `lib/screens/pos/receipt_screen.dart` | Preview struk, tombol cetak Bluetooth |
    | `lib/screens/pos/history_pos_screen.dart` | Riwayat transaksi produk, filter tanggal |
    | `lib/screens/products/product_list_screen.dart` | Manajemen katalog produk |
    | `lib/screens/products/product_form_screen.dart` | Tambah / edit produk |
    | `lib/services/printer_service.dart` | Koneksi Bluetooth, format & kirim ESC/POS |
    | `lib/providers/cart_provider.dart` | State keranjang belanja aktif |
    | `lib/providers/product_provider.dart` | State katalog produk |

    ---

    ## 4. MODUL 2 — Refill Air Reverse Osmosis (Pencatatan Isi Ulang)

    ### Cara Kerja
    **Sangat sederhana.** Setiap kali ada pelanggan isi ulang air RO → kasir membuka layar refill → pilih volume → harga muncul otomatis → tekan "Simpan". Tidak ada keranjang, tidak ada cetak struk. Di akhir bulan, buka halaman rekap untuk lihat total penjualan refill.

    ### Alur Pencatatan Refill

    ```mermaid
    flowchart LR
        A["Pelanggan Datang\nIsi Ulang Air RO"] --> B["Buka Layar\nRefill Air RO"]
        B --> C["Pilih Volume\n5L / 10L / 15L / Galon 19L"]
        C --> D["Harga Otomatis\nMuncul"]
        D --> E["Tekan 'Simpan'"]
        E --> F["✅ Tersimpan ke SQLite\n(is_synced = false)"]
        F --> G{"Online?"}
        G -- "Ya" --> H["Sinkron ke Firestore\n(is_synced = true)"]
        G -- "Tidak" --> I["Tunggu Koneksi\nPulih"]

        style F fill:#00897b,color:#fff
        style H fill:#1a73e8,color:#fff
    ```

    ### Pilihan Volume & Harga (Contoh — Dapat Dikonfigurasi)

    | Volume | Harga Default |
    |---|---|
    | 5 Liter | Rp 2.500 |
    | 10 Liter | Rp 5.000 |
    | 15 Liter | Rp 7.500 |
    | Galon 19 Liter | Rp 15.000 |

    > [!NOTE]
    > Harga per volume dapat diubah dari halaman **Pengaturan Harga Refill** tanpa perlu update kode. Harga disimpan di Firestore collection `refill_pricing`.

    ### Skema Database SQLite — Modul Refill

    ```sql
    -- Riwayat Pencatatan Refill
    CREATE TABLE refill_records (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL,
    timestamp   TEXT NOT NULL,       -- Tanggal & waktu isi ulang
    type        TEXT NOT NULL,       -- "antar" atau "ambil"
    price       INTEGER NOT NULL,    -- Harga saat transaksi
    is_synced   INTEGER DEFAULT 0    -- 0=belum sinkron, 1=sudah sinkron
    );

    ```

    ### Struktur Collection Firestore — Modul Refill

    ```
    Firestore/
    ├── refill_records/
    │   └── {record_id}
    │       ├── user_id: {uid}
    │       ├── timestamp: Timestamp
    │       ├── type: "antar" / "ambil"
    │       ├── price: 15000
    │       └── is_synced: true
    ```

    ### Layar Rekap Bulanan

    Halaman rekap menampilkan ringkasan penjualan refill per bulan:

    ```
    ╔════════════════════════════════╗
    ║   REKAP REFILL — MEI 2026      ║
    ╠════════════════════════════════╣
    ║  5 Liter    →  23 transaksi    ║
    ║                Rp  57.500      ║
    ║  10 Liter   →  41 transaksi    ║
    ║                Rp 205.000      ║
    ║  19 Liter   →  67 transaksi    ║
    ║                Rp 1.005.000    ║
    ╠════════════════════════════════╣
    ║  TOTAL TRANSAKSI : 131         ║
    ║  TOTAL PENDAPATAN: Rp 1.267.500║
    ╚════════════════════════════════╝
    ```

    ### Screen & File — Modul Refill

    | File | Deskripsi |
    |---|---|
    | `lib/screens/refill/refill_entry_screen.dart` | Layar input pencatatan refill (pilih volume → simpan) |
    | `lib/screens/refill/refill_history_screen.dart` | Riwayat harian — daftar semua pencatatan refill |
    | `lib/screens/refill/refill_monthly_screen.dart` | Rekap bulanan — total per volume & total pendapatan |
    | `lib/screens/refill/refill_pricing_screen.dart` | Pengaturan harga refill per volume |
    | `lib/providers/refill_provider.dart` | State modul refill |
    | `lib/services/refill_service.dart` | CRUD SQLite & Firestore untuk data refill |

    ---

    ## 5. Mekanisme Sinkronisasi Cloud (Fitur Premium via RevenueCat)

    Aplikasi ini menggunakan model bisnis **Freemium**. Fungsi kasir dan pencatatan sepenuhnya gratis menggunakan database lokal (SQLite). Fitur sinkronisasi ke Firebase (Cloud Backup) dan Pantau Jarak Jauh dikunci sebagai fitur berbayar (Langganan Bulanan/Tahunan) yang ditangani oleh **RevenueCat**.

    ```mermaid
    flowchart TD
        subgraph "📱 Perangkat (Offline-First)"
            A["Simpan Transaksi"] --> B["SQLite Lokal\nis_synced = false"]
            B --> C{"Internet\nAktif?"}
            C -- "Online ✅" --> CheckPremium{"Apakah Akun\nPremium?"}
            C -- "Offline ❌" --> F["Data Aman di Lokal\nTunggu Koneksi"]
        end

        subgraph "☁️ Cloud Firestore"
            D["pos_transactions/\nrefill_records/"]
        end
        
        subgraph "💰 Monetisasi (RevenueCat)"
            Paywall["Tampilkan Paywall\nLangganan Pro"]
        end

        CheckPremium -- "Belum Premium" --> Paywall
        CheckPremium -- "Premium ✅" --> E["Kirim Batch ke Firestore"]
        
        E -- "Sukses" --> G["Update is_synced = true\ndi SQLite"]
        F -.->|"Koneksi Pulih"| C

        style B fill:#2e7d32,color:#fff
        style D fill:#ff6d00,color:#fff
        style G fill:#1a73e8,color:#fff
        style Paywall fill:#fbc02d,color:#000
    ```

    ### File Terkait
    #### [NEW] `lib/services/revenuecat_service.dart`
    - Inisialisasi API Key RevenueCat (Play Store/App Store).
    - Cek status langganan (`CustomerInfo`).
    - Fetch *Offerings* (Paket Langganan).
    #### [NEW] `lib/screens/premium/paywall_screen.dart`
    - Layar promosi fitur Cloud Backup & Multi-Device.
    - Tombol Beli Langganan (Bulanan/Tahunan).
    #### [MODIFY] `lib/services/sync_service.dart`
    - Cek status `revenuecat_service` terlebih dahulu. Jika belum premium, hentikan fungsi *upload* Firestore dan biarkan data berstatus `is_synced = false` di SQLite lokal.

    ---

    ## 6. Fitur Notifikasi (FCM)

    | Jenis | Trigger | Keterangan |
    |---|---|---|
    | **Stok Rendah** | Stok produk ≤ `low_stock_threshold` setelah transaksi POS | Hanya berlaku untuk modul POS, bukan refill |
    | **Ringkasan Harian** | Setiap malam (jadwal via Cloud Function) | Rekap total penjualan produk + total refill hari ini |

    ---

    ## 7. Struktur Folder Proyek Lengkap

    ```
    lib/
    ├── main.dart
    │
    ├── models/
    │   ├── product_model.dart
    │   ├── pos_transaction_model.dart
    │   └── refill_record_model.dart         ← Model khusus refill
    │
    ├── services/
    │   ├── auth_service.dart
    │   ├── database_service.dart            ← SQLite: init & query kedua modul
    │   ├── firestore_service.dart           ← Firestore: kedua modul
    │   ├── sync_service.dart                ← Sinkronisasi hybrid kedua modul
    │   ├── printer_service.dart             ← Hanya untuk modul POS
    │   ├── refill_service.dart              ← Logic khusus modul refill
    │   └── notification_service.dart
    │
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── product_provider.dart
    │   ├── cart_provider.dart
    │   ├── refill_provider.dart             ← State khusus modul refill
    │   └── connectivity_provider.dart
    │
    ├── screens/
    │   ├── auth/
    │   │   └── login_screen.dart
    │   ├── home/
    │   │   └── home_screen.dart             ← Halaman utama: 2 pilihan modul
    │   │
    │   ├── pos/                             ← 🛒 MODUL POS PRODUK
    │   │   ├── pos_screen.dart
    │   │   ├── cart_screen.dart
    │   │   ├── receipt_screen.dart
    │   │   └── history_pos_screen.dart
    │   │
    │   ├── products/                        ← Manajemen katalog (untuk POS)
    │   │   ├── product_list_screen.dart
    │   │   └── product_form_screen.dart
    │   │
    │   └── refill/                          ← 💧 MODUL REFILL AIR RO
    │       ├── refill_entry_screen.dart
    │       ├── refill_history_screen.dart
    │       ├── refill_monthly_screen.dart
    │       └── refill_pricing_screen.dart
    │
    └── widgets/
        ├── product_card.dart
        ├── cart_item_tile.dart
        ├── connectivity_badge.dart
        └── module_card.dart                 ← Kartu pilihan modul di Home
    ```

    ---

    ## 8. Halaman Utama (Home Screen)

    Setelah login, pemilik/kasir disambut halaman utama dengan **dua tombol modul besar**:

    ```
    ┌─────────────────────────────────────┐
    │        Warung 3D Water RO           │
    │                                     │
    │  ┌─────────────┐  ┌─────────────┐  │
    │  │             │  │             │  │
    │  │  🛒 Kasir   │  │  💧 Refill  │  │
    │  │   Produk    │  │   Air RO    │  │
    │  │             │  │             │  │
    │  └─────────────┘  └─────────────┘  │
    │                                     │
    │  Stok Menipis: 2 produk ⚠️         │
    │  Refill Hari Ini: 14 transaksi     │
    └─────────────────────────────────────┘
    ```

    ---

    ## 9. Urutan Implementasi (10 Fase)

    | Fase | Komponen | Modul |
    |---|---|---|
    | **Fase 1** | Setup Firebase, `pubspec.yaml`, konfigurasi `main.dart` | Keduanya |
    | **Fase 2** | Firebase Auth — Login Screen | Keduanya |
    | **Fase 3** | Model data (`product`, `pos_transaction`, `refill_record`) | Keduanya |
    | **Fase 4** | Database Service — SQLite (kedua skema tabel) | Keduanya |
    | **Fase 5** | Firestore Service — CRUD cloud kedua modul | Keduanya |
    | **Fase 6** | Home Screen — navigasi 2 modul | Keduanya |
    | **Fase 7** | Modul POS: screen, cart provider, manajemen produk | POS Produk |
    | **Fase 8** | Printer Service — Bluetooth ESC/POS & Receipt Screen | POS Produk |
    | **Fase 9** | Modul Refill: entry, riwayat, rekap bulanan, harga | Refill Air RO |
    | **Fase 10** | Sync Service (hybrid) + Notification Service (FCM) | Keduanya |

    ---

    ## 10. Rencana Verifikasi

    ### Modul POS Produk
    - [ ] Produk tampil di layar kasir dan bisa ditambah ke keranjang
    - [ ] Hitung total, kembalian akurat
    - [ ] Transaksi tersimpan di SQLite dengan `is_synced = false` saat offline
    - [ ] Struk tercetak dengan format benar via Bluetooth printer 58mm
    - [ ] Notifikasi stok rendah muncul setelah produk terjual habis

    ### Modul Refill Air RO
    - [ ] Input refill berhasil disimpan dalam 1 tap (pilih volume → simpan)
    - [ ] Riwayat harian menampilkan semua record dengan tanggal & waktu
    - [ ] Rekap bulanan menampilkan total per volume dan total pendapatan
    - [ ] Harga refill bisa diubah dari pengaturan dan langsung berlaku

    ### Sinkronisasi & Umum
    - [ ] Sinkronisasi otomatis terjadi saat koneksi pulih (kedua modul)
    - [ ] Login/logout berjalan tanpa error
    - [ ] Uji pada HP Android min. Android 8.0 (API 26)

    ---

    ## Pertanyaan Terbuka

    > [!IMPORTANT]
    > Mohon konfirmasi sebelum implementasi dimulai:

    1. **Harga Refill Default** — Berapa harga untuk setiap volume refill (5L, 10L, 15L, Galon 19L)? Apakah ada ukuran volume lain yang perlu ditambahkan?
    2. **Catatan Pelanggan Refill** — Apakah perlu mencatat nama pelanggan di setiap transaksi refill, atau cukup volume + harga + waktu saja?
    3. **Detail Struk** — Apa alamat lengkap toko dan nomor HP untuk header struk POS?
    4. **Cetak untuk Refill** — Apakah pencatatan refill perlu opsi cetak nota juga, atau murni hanya pencatatan digital?
    5. **Firebase Project** — Apakah `google-services.json` yang ada sudah dikonfigurasi ke project Firebase yang benar?
    6. **Low Stock Threshold** — Berapa angka default stok minimum produk sebelum notifikasi dikirim?

    Jawaban :

    1. Harga Refill Default 
    5000 untuk refil air dan di antar, 4000 untuk refil air dan di ambil customer langsung
    2. Catatan Pelanggan Refill tidak perlu
    3. Detail Struk ya, buatkan template text kosong nanti yang akan di isi, nama warung, alamat, dan nomor telepon, pastikan itu juga CMS, dan keseluruhan fitur itu CMS, untuk fleksibelitas, bisa di pakai di UMKM lain
    4. Cetak untuk Refill tidak perlu
    5. Firebase Project sudah benar service googlenya
    6. Low Stock Threshold angka minimum kasih saja default 10

    ---

    ## 11. Fitur Tutorial Interaktif (In-App Onboarding)

    ### Deskripsi
    Fitur panduan interaktif berbasis karakter maskot **RO Man** (`assets/images/RO_man_TheGuide.png`) yang muncul saat pengguna pertama kali membuka aplikasi. Tutorial memperkenalkan setiap elemen UI pada layar `HomeScreen` dan kemudian mengarahkan pengguna ke halaman **Katalog Produk** (`ProductListScreen`).

    ### Mekanisme Kerja

    ```mermaid
    flowchart TD
        A["User masuk HomeScreen"] --> B{"Tutorial sudah\npernah ditampilkan?"}
        B -- "Belum" --> C["Tampilkan TutorialOverlay"]
        C --> D["Langkah 1: Perkenalan RO Man"]
        D --> E["Langkah 2-7: Highlight setiap\nelemen UI Dashboard"]
        E --> F["Langkah 8: Pesan penutup"]
        F --> G["Navigasi ke ProductListScreen"]
        G --> H["Simpan flag ke SharedPreferences"]
        B -- "Sudah" --> I["Langsung ke Dashboard biasa"]
        
        style C fill:#0097A7,color:#fff
        style G fill:#00695C,color:#fff
    ```

    ### Fitur Utama
    - **Animasi Typewriter**: Teks muncul karakter per karakter layaknya sedang diketik
    - **Tap to Speed Up**: Ketuk layar untuk mempercepat animasi teks (35ms → 8ms per karakter)
    - **Highlight Pulse**: Area target di-highlight dengan efek glow berdenyut berwarna cyan
    - **Skip Button**: Tombol untuk melewati seluruh tutorial kapan saja
    - **Karakter Animasi**: RO Man muncul dari samping layar dengan efek `elasticOut`
    - **Speech Bubble**: Balon teks muncul dengan animasi `scaleTransition`
    - **Persistent State**: Status tutorial disimpan di `SharedPreferences` agar hanya tampil sekali
    - **Reusable Widget**: `TutorialOverlay` dapat digunakan di layar manapun dengan langkah berbeda

    ### Alur Tutorial HomeScreen (8 Langkah)

    | No. | Target Highlight | Pesan |
    | 1 | — (Perkenalan) | Sapaan RO Man dan instruksi interaksi |
    | 2 | Chip "Stok Menipis" | Penjelasan ringkasan stok |
    | 3 | Chip "Refill Hari Ini" | Penjelasan ringkasan refill |
    | 4 | Kartu Kasir Produk | Penjelasan modul POS |
    | 5 | Kartu Refill Air RO | Penjelasan modul Refill |
    | 6 | Menu Katalog Produk | Penjelasan manajemen produk |
    | 7 | Menu Laporan POS | Penjelasan menu laporan & statistik |
    | 8 | — (Penutup) | Pesan selesai dan navigasi ke Katalog |

    ### Dependensi Tambahan

    | Library | Versi | Fungsi |
    |---------|-------|--------|
    | `shared_preferences` | `^2.3.4` | Menyimpan status tutorial (sudah/belum ditampilkan) |

    ### File Terkait

    | File | Deskripsi |
    |------|-----------|
    | `lib/screens/products/product_category_screen.dart` | Integrasi tutorial halaman kategori produk & intersepsi PopScope |
    | `assets/images/RO_man_TheGuide.png` | Aset gambar karakter maskot RO Man |
    | `pubspec.yaml` | Registrasi aset gambar dan dependensi `shared_preferences` |

    ### Alur Tutorial Modul Katalog & Kategori (Multi-Screen Onboarding)

    Setelah tutorial `HomeScreen` selesai, alur berpindah ke halaman **Katalog Produk** untuk mengajarkan manajemen produk dan kategori secara interaktif dengan sistem navigasi otomatis penuh:

    ```mermaid
    flowchart TD
        Start["Selesai Home Tutorial"] --> NavList["Navigasi ke ProductListScreen\nstage = 'list_intro'"]
        NavList --> ShowListIntro["Tampilkan pengenalan list\nHighlight Row Cari/Filter"]
        ShowListIntro --> HighlightAdd["Highlight Tombol Tambah (+)\n(Interactive Clickable)"]
        HighlightAdd -- "Ketuk Selesai" --> NavForm["Buka ProductFormScreen\nstage = 'form_intro'"]
        NavForm --> ShowFormIntro["Tampilkan pengenalan form"]
        ShowFormIntro -- "Ketuk Selesai" --> NavCat["Navigasi ke ProductCategoryScreen\nstage = 'category_intro'"]
        NavCat --> ShowCatIntro["Tampilkan penjelasan Kategori\nHighlight FAB '+ Kategori'"]
        ShowCatIntro -- "User mengklik FAB & Simpan Kategori" --> BackForm["Kembali ke ProductFormScreen\nstage = 'form_add_product'"]
        BackForm --> GuideAddProduct["Panduan mengisi produk contoh\nHighlight tombol Simpan"]
        GuideAddProduct -- "User mengklik Simpan" --> BackListEdit["Kembali ke ProductListScreen\nstage = 'list_highlight_edit'"]
        BackListEdit --> HighlightEdit["Highlight Tombol Edit\n(Pesan penutup tutorial)"]
        HighlightEdit -- "Tutorial Selesai" --> Finish["Update stage = 'completed'"]

        style HighlightAdd fill:#0097A7,color:#fff
        style NavForm fill:#00695C,color:#fff
        style NavCat fill:#00695C,color:#fff
        style BackForm fill:#00695C,color:#fff
        style GuideAddProduct fill:#0097A7,color:#fff
        style HighlightEdit fill:#0097A7,color:#fff
    ```

    ### Detail Implementasi Teknis

    1. **State / Stage Key (`tutorial_catalog_stage`)**:
       - Menggunakan key string di `SharedPreferences` untuk menentukan stage aktif secara global sehingga layar tujuan mengetahui langkah mana yang harus ditampilkan.
    2. **Otomatis Direct / Navigasi Terpadu & Validasi Kategori**:
       - **Katalog ke Form**: Setelah membaca penjelasan awal katalog produk dan disorot tombol "+" (Tambah) di kanan atas pada `ProductListScreen`, ketukan "Selesai" di `TutorialOverlay` akan otomatis membuka `ProductFormScreen` (memperbarui stage ke `'form_intro'`).
       - **Form ke Kategori**: Setelah perkenalan form, ketukan "Selesai" di `TutorialOverlay` akan otomatis membuka `ProductCategoryScreen` (memperbarui stage ke `'category_intro'`).
       - **Validasi Kategori Kosong saat Back**: Di `ProductCategoryScreen`, ketika pengguna berada dalam tahap tutorial (`stage == 'category_intro'`) dan mencoba kembali (lewat tombol Back AppBar maupun Android Back/PopScope), sistem akan memvalidasi apakah database lokal memiliki minimal 1 kategori. Jika kosong, navigasi diblokir dan ditampilkan `SnackBar` instruksi. Aksi kembali hanya diperbolehkan setelah minimal 1 kategori ditambahkan atau jika pengguna melewati tutorial dengan mengetuk "Skip Tutorial".
       - **Kategori Kembali ke Form**: Saat berada di halaman `ProductCategoryScreen`, pengisian kategori baru dan penyimpanan berhasil via tombol **Simpan** (atau ketika menekan kembali saat kategori sudah ada) akan mengubah stage ke `'form_add_product'` dan melakukan `Navigator.pop(context, 'go_to_form')` kembali ke `ProductFormScreen`.
       - **Skip Tutorial**: Jika pengguna mengetuk "Skip Tutorial" pada `ProductCategoryScreen`, callback `onSkip` dijalankan untuk memperbarui status stage ke `'completed'` secara permanen dan segera mengembalikan pengguna ke `ProductListScreen` tanpa memaksa validasi data kategori.
    3. **Interactive Pass-Through (`RenderHoleHitTest` / `HoleHitTestWidget`)**:
       - Agar pengguna dapat mengklik tombol yang sedang di-highlight (misalnya tombol FAB '+ Kategori' atau tombol 'Simpan/Edit') tanpa terhalang overlay modal penuh, dibuat custom render object `RenderHoleHitTest` yang mewarisi `RenderProxyBox`.
       - Jika koordinat event klik berada di dalam area `holeRect` (kotak target yang diperbesar dengan padding), `hitTest` mengembalikan nilai `false`. Flutter akan meneruskan event input tersebut ke widget di bawah overlay secara otomatis.
    4. **Pencegahan Error Layout Query di Build Phase**:
       - Untuk mencegah crash `SchedulerBinding.handleDrawFrame` yang disebabkan query posisi target widget (`_getTargetRect()`) saat layout sedang dibuat, kalkulasi posisi dibungkus dengan `WidgetsBinding.instance.addPostFrameCallback`.
       - Di halaman `ProductCategoryScreen`, widget `PopScope` dan tombol back di AppBar diintersepsi untuk memicu validasi kategori sebelum navigasi diizinkan.

## Perbaikan Bug Onboarding / Tutorial Katalog Produk (15 Juni 2026)

- **Masalah**: Setelah menambah kategori dan menyimpan produk baru, saat kembali ke `ProductListScreen`, tutorial diulang dari awal (welcome intro) bukan diselesaikan dengan menyorot (highlight) tombol edit pada kartu produk baru.
- **Penyebab**:
  1. Pada `ProductFormScreen`, callback `onComplete` dari `TutorialOverlay` untuk stage `form_add_product` secara prematur memperbarui `tutorial_catalog_stage` menjadi `'completed'` sebelum tombol "Tambah Produk" (`_save`) ditekan. Akibatnya, `_save()` tidak dapat mengubah status stage menjadi `'list_highlight_edit'`.
  2. Menekan tombol "+" secara manual di `ProductListScreen` (AppBar / empty state) membuka `ProductFormScreen` secara langsung tanpa melalui `ProductCategoryScreen` jika stage adalah `'list_intro'`.
- **Solusi/Perbaikan**:
  1. Di `ProductFormScreen`, `onComplete` untuk `form_add_product` tidak lagi menimpa stage ke `'completed'` secara prematur, sehingga stage tetap `'form_add_product'`. Ketika tombol `_keySaveButton` ditekan dan `_save()` selesai, stage diperbarui dengan benar menjadi `'list_highlight_edit'`.
  2. Di `ProductFormScreen`, ditambahkan handler `onComplete` untuk `form_intro` agar navigasi otomatis ke `ProductCategoryScreen` berjalan semestinya.
  3. Di `ProductListScreen`, event klik pada tombol "+" (AppBar) maupun tombol empty state "Tambah Produk" di-redirect ke `ProductCategoryScreen` (mengubah status ke `'category_intro'`) agar alur tutorial tetap utuh dan konsisten.
  4. Menambahkan callback `onSkip` pada `TutorialOverlay` di `ProductListScreen` dan `ProductFormScreen` agar ketika pengguna membatalkan/melewati petunjuk, status stage langsung diset ke `'completed'`.
  5. **Pop-with-Result (Penyelesaian Sinkronisasi Navigasi)**: Menggantikan navigasi `pushReplacement` pada `ProductCategoryScreen` dengan `Navigator.pop(context, 'go_to_form')` ketika kategori berhasil dibuat. Di `ProductListScreen`, pemanggilan `Navigator.push(ProductCategoryScreen)` menangkap result ini. Jika result bernilai `'go_to_form'`, maka `ProductListScreen` akan segera melakukan `push` ke `ProductFormScreen`. Hal ini menjamin bahwa rute aslinya tidak langsung selesai dan status tutorial diperbarui secara tepat waktu setelah form produk ditutup/disimpan.
  6. **Intersepsi Back Button di ProductFormScreen**: Membungkus `ProductFormScreen` dengan `PopScope` dan mengimplementasikan leading `IconButton` yang memicu `_goBack()`. Navigasi kembali diblokir dan menampilkan `SnackBar` peringatan ketika user berada dalam tahapan tutorial (`form_intro` atau `form_add_product`) kecuali jika user menekan "Skip Tutorial" (yang merubah status stage ke `'completed'` sebelum memicu pop).

- **Perbaikan Loop Tutorial via Tombol Back di ProductFormScreen (15 Juni 2026)**:
  - **Masalah**: Pengguna dapat menutup/menyelesaikan overlay petunjuk pada langkah interaktif (seperti tombol "+ Kategori" atau "Tambah Produk") dengan menekan tombol "Selesai" pada balon dialog, sehingga overlay hilang padahal data/produk belum benar-benar ditambah. Jika overlay hilang, pengguna tidak dapat menekan "Skip Tutorial" dan jika menekan tombol back, mereka terhambat oleh `PopScope`. Jika pengguna memaksa/keluar secara tidak wajar, status tutorial tersangkut di `'form_add_product'`, menyebabkan loop tutorial intro ketika membuka halaman katalog produk.
  - **Penyebab**: Balon dialog tutorial (`TutorialOverlay`) menampilkan tombol "Selesai"/"Lanjut" pada langkah interaktif terakhir secara default.
  - **Solusi**:
    1. Menambahkan opsi `showNextButton` pada `TutorialStep` (default `true`). Jika diset ke `false`, tombol "Lanjut"/"Selesai" pada balon dialog disembunyikan.
    2. Mengeset `showNextButton: false` pada langkah interaktif `ProductCategoryScreen` (penambahan kategori) dan `ProductFormScreen` (penambahan produk). Hal ini memaksa pengguna untuk berinteraksi langsung dengan widget target (tombol "+ Kategori" atau "Tambah Produk") atau memilih tombol "Skip Tutorial" (melewati tutorial).
    3. Memperbarui `onSkip` di `ProductFormScreen` agar tidak hanya mengubah status ke `'completed'` tetapi juga langsung memicu `Navigator.pop(context)` demi kenyamanan dan kecepatan keluar dari alur tutorial.

## Implementasi Tutorial POS (Kasir) Interaktif (15 Juni 2026)

- **Masalah/Kebutuhan**: Menyambung alur onboarding tutorial dari penutupan katalog produk ke simulasi transaksi POS produk kelontong secara penuh agar pengguna memahami alur kerja kasir POS dari memilih produk, memasukkan uang pembayaran, hingga mencetak struk.
- **Penyelesaian**:
  1. **Alur Transaksi Multi-Layar**:
     - **ProductListScreen**: Menambahkan highlight back button ketika stage `'list_highlight_edit'` selesai, mengarahkan pengguna kembali ke Dashboard.
     - **HomeScreen**: Mendeteksi stage `'home_pos_intro'` untuk menyorot modul **Kasir Produk**. Tapping akan mengubah stage ke `'pos_intro'` dan masuk ke kasir.
     - **PosScreen**: Memperkenalkan kolom pencarian, list produk, dan mengarahkan pengguna memilih produk pertama. Setelah produk dipilih, tombol keranjang (FAB/AppBar) disorot untuk lanjut ke `CartScreen`.
     - **CartScreen**: Menampilkan total belanja dan mendesak input uang tunai diterima. Menggunakan listener `onChanged` di field input uang tunai untuk otomatis mengganti stage ke `'cart_payment_active'` dan menyorot tombol "Proses Pembayaran" saat uang tunai $\ge$ total belanja.
     - **ReceiptScreen**: Setelah transaksi POS diproses, menyajikan detail struk belanja serta menyorot info koneksi printer Bluetooth dan tombol cetak.
  2. **Intersepsi Back Navigation (PopScope)**:
     - Mencegah pengguna membatalkan alur tutorial secara tidak sengaja dengan mengunci navigasi kembali (`canPop: false`) di halaman POS, Keranjang, dan Struk Penjualan, kecuali dengan menekan tombol **Skip Tutorial** (yang akan menyetel stage tutorial ke `'completed'` secara permanen).
     - Menghindari race condition pada navigasi kembali `ProductListScreen` ke `HomeScreen` dengan menggunakan `canPop: false` selama tutorial aktif dan melakukan pop manual secara asinkron setelah stage di SharedPreferences terupdate secara utuh.

  3. **Perbaikan Transisi ProductListScreen ke HomeScreen (16 Juni 2026)**:
     - Memperbaiki bug di `TutorialOverlay` di mana langkah tanpa tombol "Selesai/Lanjut" (seperti mengklik tombol back) dapat dilompati jika pengguna secara tidak sengaja mengetuk layar (memicu `_onTapScreen` yang salah membaca `showNextButton`). Perbaikan ini memastikan bahwa pada langkah interaktif tanpa tombol lanjut, overlay tutorial akan bertahan hingga pengguna benar-benar berinteraksi dengan tombol target, sehingga status navigasi tutorial (seperti `home_pos_intro`) tersimpan sempurna.

### Fase 20: Tutorial Onboarding Otomatis Owner & Manajemen Kasir (Lintas Layar)
- **Kebutuhan**: Memperkenalkan metrik utama Dashboard Owner, mengatur profil toko, serta **mewajibkan** Owner membuat setidaknya 1 profil Kasir agar aplikasi bisa dioperasikan. Alur tutorial berjalan mulus lintas 3 layar.
- **Penyelesaian**:
  1. **State Machine SharedPreferences (`tutorial_owner_stage`)**:
     Menggabungkan berbagai *flags* menjadi satu sistem *stage* (0 - 5):
     - `0`: Tutorial Dashboard Owner awal.
     - `1`: Tutorial Settings Screen (Form Profil Toko, dsb).
     - `2`: Tutorial Cashier Management Screen (Wajib mengisi kasir).
     - `3`: Tutorial Settings Screen (Sorot tombol Back untuk kembali).
     - `4`: Tutorial Dashboard Owner final (Sorot Menu Titik Tiga -> Kunci Layar).
     - `5` / `completed`: Tutorial selesai.
  2. **Auto-Navigation & Pemblokiran Back (`PopScope`)**:
     - Sistem otomatis berpindah layar dari Dashboard -> Settings -> Cashier menggunakan navigasi otomatis setelah pengguna menyelesaikan *step* di setiap tahapan tutorial.
     - Menggunakan `PopScope` di halaman Manajemen Kasir untuk memblokir penekanan tombol Back (di Android maupun AppBar) apabila daftar kasir kosong (state = 2). Menjamin Owner selalu memiliki minimal 1 profil Kasir sebelum bisa kembali beroperasi.
  3. **Sorotan (Highlight) Berkesinambungan**:
     - Tutorial memberikan panduan dari halaman awal, mengisi pengaturan, mengatur pegawai (kasir), dan memandu *kembali* (sorot tombol kembali di AppBar) sampai instruksi akhir untuk pindah ke *Lock Screen*.
