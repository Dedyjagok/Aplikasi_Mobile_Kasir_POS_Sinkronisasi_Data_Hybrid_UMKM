/// Model pengaturan aplikasi (CMS) — dapat diubah dari layar Pengaturan
/// dan disinkronkan ke Firestore agar persisten di semua perangkat.
class AppSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String receiptFooter;
  final int refillPriceAntar; // harga isi ulang + diantar
  final int refillPriceAmbil; // harga isi ulang + ambil sendiri
  final int lowStockThreshold; // batas stok minimum sebelum notifikasi
  final String currencySymbol;
  final String ownerPin; // PIN untuk login owner (offline)

  const AppSettings({
    this.storeName = 'Nama Warung Anda',
    this.storeAddress = 'Alamat Warung',
    this.storePhone = '08xxxxxxxxxx',
    this.receiptFooter = 'Terima Kasih! Silakan Datang Kembali.',
    this.refillPriceAntar = 5000,
    this.refillPriceAmbil = 4000,
    this.lowStockThreshold = 10,
    this.currencySymbol = 'Rp',
    this.ownerPin = '123456', // default PIN
  });

  Map<String, dynamic> toMap() => {
        'store_name': storeName,
        'store_address': storeAddress,
        'store_phone': storePhone,
        'receipt_footer': receiptFooter,
        'refill_price_antar': refillPriceAntar,
        'refill_price_ambil': refillPriceAmbil,
        'low_stock_threshold': lowStockThreshold,
        'currency_symbol': currencySymbol,
        'owner_pin': ownerPin,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        storeName: map['store_name'] ?? 'Nama Warung Anda',
        storeAddress: map['store_address'] ?? 'Alamat Warung',
        storePhone: map['store_phone'] ?? '08xxxxxxxxxx',
        receiptFooter:
            map['receipt_footer'] ?? 'Terima Kasih! Silakan Datang Kembali.',
        refillPriceAntar: map['refill_price_antar'] ?? 5000,
        refillPriceAmbil: map['refill_price_ambil'] ?? 4000,
        lowStockThreshold: map['low_stock_threshold'] ?? 10,
        currencySymbol: map['currency_symbol'] ?? 'Rp',
        ownerPin: map['owner_pin'] ?? '123456',
      );

  AppSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? receiptFooter,
    int? refillPriceAntar,
    int? refillPriceAmbil,
    int? lowStockThreshold,
    String? currencySymbol,
    String? ownerPin,
  }) =>
      AppSettings(
        storeName: storeName ?? this.storeName,
        storeAddress: storeAddress ?? this.storeAddress,
        storePhone: storePhone ?? this.storePhone,
        receiptFooter: receiptFooter ?? this.receiptFooter,
        refillPriceAntar: refillPriceAntar ?? this.refillPriceAntar,
        refillPriceAmbil: refillPriceAmbil ?? this.refillPriceAmbil,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        ownerPin: ownerPin ?? this.ownerPin,
      );
}
