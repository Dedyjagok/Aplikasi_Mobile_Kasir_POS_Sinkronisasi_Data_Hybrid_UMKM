# Metode Pengujian Sistem

Pengujian sistem pada aplikasi **POS Warung 3D Water RO** menggunakan metode **Black Box Testing**. Pengujian ini berfokus pada fungsionalitas aplikasi dari sudut pandang pengguna akhir tanpa perlu memeriksa struktur kode internal. 

Skenario pengujian disusun untuk menguji setiap modul dan fitur utama pada aplikasi menggunakan parameter Black Box Testing. Setiap skenario berisi rancangan tindakan operasional yang disimulasikan beserta hasil keluaran logis yang diharapkan terjadi jika fitur tersebut beroperasi dengan baik. Rincian skenario pengujian sistem POS Warung 3D Water RO dapat dilihat pada tabel di bawah ini.

## Skenario Pengujian Sistem

| NO | Skenario Pengujian | Hasil yang diharapkan |
|:--:|---|---|
| 1 | **Login Aktivasi Perangkat (Owner)**: Memasukkan email dan password yang valid. | Sistem berhasil mengautentikasi pengguna dengan Firebase Auth dan mengunduh profil toko ke memori lokal. |
| 2 | **Login Operasional Harian (Kasir/Owner)**: Memilih profil staf dan memasukkan PIN 4 digit pada layar kunci (*Lock Screen*). | Jika PIN benar, aplikasi membuka akses dan mengarahkan pengguna ke *Dashboard* sesuai hak akses (Owner atau Kasir). |
| 3 | **Manajemen Kategori Produk**: Kasir/Owner menambah kategori barang baru dan menyimpannya. | Kategori baru berhasil disimpan di database, status sinkronisasi tertunda aktif, dan kategori langsung tersedia sebagai opsi di form produk. |
| 4 | **Manajemen Katalog Produk**: Mengisi form produk baru (Nama, Harga Modal, Harga Jual, Stok) secara lengkap lalu menyimpan. | Produk baru berhasil tampil di dalam list katalog, stok awal tercatat, dan produk dapat dipilih saat transaksi POS. |
| 5 | **Transaksi POS (Tambah ke Keranjang)**: Mengklik satu atau beberapa produk dari katalog untuk diinput ke dalam keranjang belanja. | Jumlah *badge* item pada keranjang bertambah dan total tagihan subtotal (akumulasi harga jual) terhitung secara seketika dan otomatis. |
| 6 | **Transaksi POS (Input Pembayaran)**: Kasir menginput nominal uang tunai yang dibayarkan pelanggan (nominal harus lebih besar atau sama dengan total belanja). | Sistem otomatis menghitung jumlah uang kembalian secara presisi dan seketika tombol "Proses Pembayaran" menjadi aktif. |
| 7 | **Transaksi POS (Penyelesaian Transaksi & Stok)**: Menyelesaikan transaksi pembayaran penjualan produk. | Data transaksi tersimpan aman di SQLite lokal (`is_synced=false`), stok database produk otomatis berkurang sesuai *qty* pembelian, dan antarmuka berpindah ke pratinjau struk. |
| 8 | **Modul Cetak Struk (ESC/POS)**: Menekan tombol "Cetak Struk" setelah sukses terhubung ke perangkat Printer Bluetooth 58mm. | Printer thermal merespons perintah dan langsung mencetak fisik struk pembelanjaan sesuai dengan format *layout* dan total harga yang benar. |
| 9 | **Modul Refill Air RO (Pencatatan Cepat)**: Menekan tombol menu pencatatan isi ulang galon (misal: ukuran 19L / Galon standar). | Sistem secara efisien dan instan menyimpan 1 *entry* riwayat isi ulang dengan pendapatan harga yang terikat otomatis pada volume tersebut tanpa melalui keranjang. |
| 10 | **Hak Akses Role-based (Kasir View)**: Membuka *Dashboard* (Home Screen) menggunakan profil PIN Kasir biasa. | Tombol/ikon "Pengaturan Sistem" dan akses monitoring data pemilik disembunyikan; antarmuka berfokus pada POS dan Refill harian saja. |
| 11 | **Hak Akses Role-based (Owner View)**: Membuka *Dashboard* menggunakan otorisasi tingkat Owner. | Antarmuka menampilkan ringkasan performa finansial hari ini (Pendapatan & Daftar Produk Terlaris secara *pagination*). |
| 12 | **Statistik POS & Analisis Laba**: Mengakses layar "Statistik POS" dengan mengatur filter ke periode bulan tertentu. | Menampilkan ringkasan Total Modal (*Cost Price*), Total Penjualan, Laba Bersih yang terhitung akurat, beserta grafik *Bar Chart* produk terlaris berdasarkan kategori. |
| 13 | **Fitur Export Laporan (PDF & Excel)**: Memilih opsi tekan Export (PDF / Excel) dari halaman Statistik POS. | Sistem berhasil membentuk dan mengekspor dokumen/tabel (*Peringkat, Nama, Kategori, Qty Terjual, dan Ringkasan Laba*), kemudian secara native membuka panel *Share* OS untuk dikirim atau disimpan. |
| 14 | **Sinkronisasi Data Lokal ke Cloud**: Menyalakan dan mengaktifkan koneksi internet setelah mencatat beberapa transaksi di mode *Offline*. | Layanan sinkronisasi latar belakang berjalan secara transparan dan otomatis mengunggah data transaksi ke Cloud Firestore, lalu memperbarui *flag* `is_synced` lokal menjadi `true`. |
| 15 | **Fitur Notifikasi Lokal (Peringatan Stok)**: Melakukan transaksi penjualan produk yang menyebabkan sisa stok produk menjadi kurang dari atau sama dengan batas minimum (*low_stock_threshold*). | Sistem secara otomatis dan instan memunculkan peringatan pop-up notifikasi lokal di HP ("Stok Menipis!") yang berisi informasi nama produk dan sisa stok. |
