# Activity Diagram: Pemilik / Owner (CRUD & Laporan)

Dokumen ini memuat Activity Diagram yang menggambarkan alur kerja manajerial yang dilakukan oleh Pemilik (Owner), meliputi proses Create, Read, Update, Delete (CRUD) untuk Katalog Produk serta proses melihat Laporan/Rekapitulasi transaksi.

## 1. Activity Diagram: Manajemen Katalog Produk (CRUD)

Diagram ini menunjukkan alur ketika Owner ingin menambah produk baru, mengedit harga/stok, atau menghapus produk dari katalog.

```mermaid
flowchart TD
    subgraph Owner [👤 Aktor: Pemilik / Owner]
        Start([Mulai])
        BukaMenu(Buka Menu Katalog Produk)
        PilihAksi{Pilih Aksi?}
        
        InputBaru(Input Data Produk Baru)
        PilihEdit(Pilih Produk & Ubah Data)
        PilihHapus(Pilih Produk & Konfirmasi Hapus)
        
        SimpanBaru(Tekan 'Simpan')
        SimpanEdit(Tekan 'Update')
        
        End([Selesai])
    end

    subgraph Sistem [💻 Aplikasi]
        TampilDaftar(Tampilkan Daftar Produk)
        Validasi(Validasi Input Form)
        ProsesHapus(Proses Hapus Data)
        TampilSukses(Tampilkan Pesan Sukses / Refresh)
    end

    subgraph DB [🗄️ Database: SQLite]
        InsertDB[(Insert Data Baru)]
        UpdateDB[(Update Data Produk)]
        DeleteDB[(Delete Data Produk)]
    end

    %% Flow Alur Kerja
    Start --> BukaMenu
    BukaMenu --> TampilDaftar
    TampilDaftar --> PilihAksi
    
    %% Alur Create (Tambah)
    PilihAksi -- Tambah Produk --> InputBaru
    InputBaru --> SimpanBaru
    SimpanBaru --> Validasi
    Validasi -- Valid --> InsertDB
    InsertDB --> TampilSukses
    
    %% Alur Update (Edit)
    PilihAksi -- Edit Produk --> PilihEdit
    PilihEdit --> SimpanEdit
    SimpanEdit --> Validasi
    Validasi -- Valid --> UpdateDB
    UpdateDB --> TampilSukses
    
    %% Jika form tidak valid (kosong, salah ketik)
    Validasi -- Tidak Valid --> InputBaru
    
    %% Alur Delete (Hapus)
    PilihAksi -- Hapus Produk --> PilihHapus
    PilihHapus --> ProsesHapus
    ProsesHapus --> DeleteDB
    DeleteDB --> TampilSukses
    
    %% Kembali ke awal setelah sukses
    TampilSukses --> TampilDaftar
    
    %% Keluar
    PilihAksi -- Keluar Menu --> End
    
    %% Styling Swimlane
    style Owner fill:#f9f9f9,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5
    style Sistem fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,stroke-dasharray: 5 5
    style DB fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5
```

---

## 2. Activity Diagram: Laporan & Rekapitulasi (Lain-lain)

Diagram ini menunjukkan alur ketika Owner meninjau riwayat penjualan (Modul POS) dan rekapitulasi bulanan (Modul Refill Air RO).

```mermaid
flowchart TD
    subgraph Owner [👤 Aktor: Pemilik / Owner]
        Start2([Mulai])
        BukaDashboard(Buka Layar Beranda / Home)
        PilihLaporan{Pilih Menu\nLaporan?}
        
        PilihTglPOS(Pilih Filter Tanggal)
        PilihBulanRefill(Pilih Filter Bulan)
        
        End2([Selesai])
    end

    subgraph Sistem [💻 Aplikasi]
        TampilDashboard(Tampilkan Pilihan Modul)
        AmbilDataPOS(Proses Pencarian Riwayat POS)
        TampilRiwayatPOS(Tampilkan List Transaksi & Total Pendapatan POS)
        
        AmbilDataRefill(Kalkulasi Total Transaksi Refill per Volume)
        TampilRekapRefill(Tampilkan Dashboard Rekap Bulanan Refill)
    end

    subgraph DB [🗄️ Database: SQLite]
        QueryPOS[(Query pos_transactions\nberdasarkan tanggal)]
        QueryRefill[(Query refill_records\nberdasarkan bulan)]
    end

    %% Flow Alur Kerja
    Start2 --> BukaDashboard
    BukaDashboard --> TampilDashboard
    TampilDashboard --> PilihLaporan
    
    %% Alur Riwayat POS
    PilihLaporan -- Riwayat POS --> PilihTglPOS
    PilihTglPOS --> AmbilDataPOS
    AmbilDataPOS --> QueryPOS
    QueryPOS --> TampilRiwayatPOS
    TampilRiwayatPOS --> End2
    
    %% Alur Rekap Refill
    PilihLaporan -- Rekap Refill Bulanan --> PilihBulanRefill
    PilihBulanRefill --> AmbilDataRefill
    AmbilDataRefill --> QueryRefill
    QueryRefill --> TampilRekapRefill
    TampilRekapRefill --> End2
    
    %% Keluar
    PilihLaporan -- Kembali --> End2
    
    %% Styling Swimlane
    style Owner fill:#f9f9f9,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5
    style Sistem fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,stroke-dasharray: 5 5
    style DB fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5
```
