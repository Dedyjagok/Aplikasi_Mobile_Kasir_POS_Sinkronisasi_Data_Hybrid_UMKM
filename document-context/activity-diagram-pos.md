# Activity Diagram: Modul POS (Kasir Kelontong)

Dokumen ini memuat Activity Diagram (Diagram Aktivitas) yang menggambarkan alur kerja langkah demi langkah untuk satu siklus transaksi di Modul POS Produk, mulai dari pemilihan barang hingga proses mencetak struk.

## 1. Gambar Activity Diagram

```mermaid
flowchart TD
    subgraph Pelanggan
        A1([Membawa barang belanjaan])
        A2([Menyerahkan uang pembayaran])
        A3([Menerima struk dan barang])
    end
    
    subgraph Kasir
        B1(Membuka halaman POS)
        B2(Memilih produk dari katalog)
        B3(Menekan tombol Checkout/Bayar)
        B4(Menginput nominal uang pelanggan)
        B5(Menekan tombol Simpan & Cetak Struk)
    end
    
    subgraph Sistem
        C1(Memasukkan produk ke keranjang belanja)
        C2(Menampilkan total tagihan)
        C3(Menghitung nominal kembalian otomatis)
        C4[(Menyimpan transaksi ke SQLite\n& Mengurangi Stok lokal)]
        C5(Mengirim format ESC/POS ke Printer)
    end

    %% Alur Proses (Flow)
    A1 --> B1
    B1 --> B2
    B2 --> C1
    C1 --> B3
    B3 --> C2
    C2 --> A2
    A2 --> B4
    B4 --> C3
    C3 --> B5
    B5 --> C4
    C4 --> C5
    C5 --> A3
```

---

## 2. Penjelasan Alur (Activity Flow)

Diagram di atas menjelaskan alur interaksi Kasir pada fitur **Point of Sales (POS)**:

1. **Mulai Transaksi**: Kasir masuk ke halaman utama POS yang menampilkan grid/daftar produk kelontong.
2. **Pilih Produk & Masuk Keranjang**: Kasir menyentuh item produk yang dibeli oleh pelanggan. Sistem secara otomatis akan memasukkannya ke dalam *Cart* (Keranjang).
   - *Looping*: Jika pelanggan membeli lebih dari satu barang, kasir dapat terus memilih produk lain.
3. **Checkout / Bayar**: Setelah semua barang dimasukkan, kasir menekan tombol bayar untuk beralih ke layar konfirmasi keranjang.
4. **Input Pembayaran**: Sistem menampilkan total tagihan. Kasir kemudian menginput jumlah uang tunai yang diberikan oleh pelanggan.
5. **Kalkulasi Kembalian**: Sistem akan menghitung otomatis nominal uang kembalian yang harus diberikan kasir kepada pelanggan.
6. **Simpan Transaksi (Proses Offline-First)**: Kasir menekan tombol konfirmasi untuk menyelesaikan transaksi. Di balik layar, Sistem akan:
   - Menyimpan detail transaksi (ID, total, kembalian, daftar item) ke database lokal SQLite dengan status `is_synced = false` (belum disinkronkan ke cloud).
   - Mengurangi angka jumlah stok produk yang dibeli dari tabel katalog SQLite lokal.
7. **Halaman Sukses & Opsi Cetak Struk**: Layar akan menampilkan bahwa pembayaran berhasil. Pada layar ini kasir ditawarkan untuk mencetak nota pembelian (struk).
   - Jika ditekan cetak, sistem akan mengubah format transaksi ke ESC/POS dan mengirimkannya melalui koneksi Bluetooth ke Printer Thermal 58mm.
8. **Selesai**: Transaksi berakhir dan kasir siap untuk melayani pembeli berikutnya (kembali ke layar utama POS).

> **Catatan Sinkronisasi:** Sinkronisasi ke Firebase/Firestore (Cloud) **tidak secara eksplisit memblokir** atau memperlambat transaksi kasir ini. Sinkronisasi berjalan secara independen di latar belakang *(background)* ketika sistem mendeteksi ketersediaan internet.
