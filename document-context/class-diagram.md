# Class Diagram: Sistem Kasir & Refill Hybrid

Dokumen ini memuat rancangan Class Diagram yang menggambarkan struktur data (*Models*), relasi antar entitas, serta interaksi antara lapisan layanan (*Services*) untuk mengelola arsitektur *hybrid* (SQLite lokal dan Firestore cloud).

```mermaid
classDiagram
    %% ==========================================
    %% BAGIAN 1: MODEL DATA (ENTITAS)
    %% ==========================================

    class Product {
      +String id
      +String name
      +String category
      +int costPrice
      +int sellPrice
      +int stock
      +int lowStockThreshold
      +DateTime updatedAt
      +toSqliteMap() Map
      +fromSqliteMap(Map) Product
    }

    class PosTransaction {
      +String id
      +DateTime timestamp
      +int totalAmount
      +int cashReceived
      +int changeAmount
      +String paymentMethod
      +bool isSynced
      +toSqliteMap() Map
      +toFirestoreMap() Map
    }

    class PosTransactionItem {
      +String id
      +String transactionId
      +String productId
      +String productName
      +int qty
      +int unitPrice
      +int subtotal
      +toSqliteMap() Map
      +toFirestoreMap() Map
    }

    class RefillRecord {
      +String id
      +DateTime timestamp
      +String type
      +int price
      +bool isSynced
      +toSqliteMap() Map
      +toFirestoreMap() Map
    }

    class AppSettings {
      +String storeName
      +String storeAddress
      +String storePhone
      +int refillPriceAntar
      +int refillPriceAmbil
      +String currencySymbol
    }

    %% ==========================================
    %% BAGIAN 2: SERVICES (LOGIC HYBRID)
    %% ==========================================

    class DatabaseService {
      <<SQLite Local (Offline)>>
      -Database _db
      +insertProduct(Product)
      +updateProductStock(String, int)
      +insertPosTransaction(PosTransaction)
      +getUnsyncedPosTransactions() List~PosTransaction~
      +insertRefillRecord(RefillRecord)
      +getUnsyncedRefillRecords() List~RefillRecord~
      +markPosTransactionSynced(String id)
      +markRefillRecordSynced(String id)
    }

    class FirestoreService {
      <<Firebase Cloud (Online)>>
      -FirebaseFirestore _firestore
      +addPosTransaction(PosTransaction)
      +addRefillRecord(RefillRecord)
    }

    class SyncService {
      <<Background Worker>>
      -Connectivity _connectivity
      -DatabaseService _dbService
      -FirestoreService _firestoreService
      +startMonitoring()
      +syncPendingData()
    }

    %% ==========================================
    %% RELASI & KARDINALITAS
    %% ==========================================

    %% Komposisi: 1 Transaksi punya banyak Item
    PosTransaction "1" *-- "many" PosTransactionItem : contains

    %% Dependensi: DatabaseService mengelola model-model
    DatabaseService ..> Product : manages
    DatabaseService ..> PosTransaction : manages
    DatabaseService ..> PosTransactionItem : manages
    DatabaseService ..> RefillRecord : manages
    DatabaseService ..> AppSettings : manages

    %% Dependensi: FirestoreService mengelola model cloud
    FirestoreService ..> PosTransaction : pushes
    FirestoreService ..> RefillRecord : pushes

    %% Relasi Sinkronisasi Hybrid
    SyncService --> DatabaseService : reads unsynced (is_synced=0)
    SyncService --> FirestoreService : writes to cloud
    SyncService --> DatabaseService : updates status (is_synced=1)
```
