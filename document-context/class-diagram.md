# Class Diagram: Sistem Kasir & Refill Hybrid (Multi-Tenancy & Freemium)

Dokumen ini memuat rancangan Class Diagram yang menggambarkan struktur data (*Models*), State Management (*Providers*), serta interaksi antara lapisan layanan (*Services*) untuk mengelola arsitektur *hybrid* (SQLite lokal dan Firestore cloud) yang terintegrasi dengan sistem *Multi-Tenancy* (berbasis UID) dan *Freemium* (RevenueCat).

```mermaid
classDiagram
    %% ==========================================
    %% BAGIAN 1: MODEL DATA (ENTITAS)
    %% ==========================================

    class Category {
      +String id
      +String userId
      +String name
      +DateTime updatedAt
      +toMap() Map
      +fromMap(Map) Category
    }

    class Product {
      +String id
      +String userId
      +String name
      +String categoryId
      +int costPrice
      +int sellPrice
      +int stock
      +int lowStockThreshold
      +DateTime updatedAt
      +toMap() Map
      +fromMap(Map) Product
    }

    class PosTransaction {
      +String id
      +String userId
      +DateTime timestamp
      +int totalAmount
      +int cashReceived
      +int changeAmount
      +String paymentMethod
      +bool isSynced
      +toMap() Map
      +fromMap(Map) PosTransaction
    }

    class PosTransactionItem {
      +String id
      +String transactionId
      +String productId
      +String productName
      +int qty
      +int unitPrice
      +int subtotal
      +toMap() Map
      +fromMap(Map) PosTransactionItem
    }

    class RefillRecord {
      +String id
      +String userId
      +DateTime timestamp
      +String type
      +int price
      +bool isSynced
      +toMap() Map
      +fromMap(Map) RefillRecord
    }

    class AppSettings {
      +String storeName
      +String storeAddress
      +String storePhone
      +int refillPriceAntar
      +int refillPriceAmbil
      +String currencySymbol
      +toMap() Map
      +fromMap(Map) AppSettings
    }

    class Owner {
      +String uid
      +String email
      +String name
      +bool isPremium
    }

    class Cashier {
      +String id
      +String userId
      +String name
      +String pin
      +bool isActive
      +toMap() Map
      +fromMap(Map) Cashier
    }

    %% ==========================================
    %% BAGIAN 2: SERVICES (CORE LOGIC)
    %% ==========================================

    class DatabaseService {
      <<SQLite Local (Offline)>>
      -Database _db
      +insertCategory(Category)
      +insertProduct(Product)
      +updateProductStock(String, int)
      +insertPosTransaction(PosTransaction)
      +insertCashier(Map)
      +getCashiers(String userId) List~Map~
      +getUnsyncedPosTransactions(String userId) List~PosTransaction~
      +markPosTransactionSynced(String id)
    }

    class FirestoreService {
      <<Firebase Cloud (Online)>>
      -FirebaseFirestore _firestore
      +addCategory(Category)
      +batchAddPosTransactions(List)
      +batchAddRefillRecords(List)
      %% Data disimpan dalam users/{uid}/...
    }

    class SyncService {
      <<Background Worker>>
      -Connectivity _connectivity
      -DatabaseService _localDb
      -FirestoreService _cloudDb
      +startListening()
      +syncAll()
      %% Mengecek RevenueCatService().isPremium
    }

    class RevenueCatService {
      <<Monetization Gateway>>
      +bool isPremium
      +initialize()
      +checkPremiumStatus()
    }
    
    class NotificationService {
      <<Local Notifications>>
      +init()
      +showLowStockNotification(String, int)
    }
    
    class ExportService {
      <<File Exporter>>
      +exportToPdf()
      +exportToExcel()
    }

    %% ==========================================
    %% BAGIAN 3: PROVIDERS (STATE MANAGEMENT)
    %% ==========================================

    class AuthProvider {
      +User user
      +bool isLoggedIn
      +signIn(email, password)
      +signOut()
    }

    class SessionProvider {
      +bool isActive
      +String activeRole
      +String activeName
      +loginAsOwner(String name)
      +loginAsCashier(Cashier)
      +lockScreen()
    }

    class CashierProvider {
      +List~Cashier~ cashiers
      +loadCashiers()
      +addCashier(name, pin)
      +updateCashier(id, name, pin)
      +deleteCashier(id)
    }
    
    class CategoryProvider {
      +List~Category~ categories
      +loadCategories()
      +addCategory(name, userId)
      +updateCategory(Category)
      +deleteCategory(id)
    }

    %% ==========================================
    %% RELASI & KARDINALITAS
    %% ==========================================

    %% Komposisi: 1 Transaksi punya banyak Item
    PosTransaction "1" *-- "many" PosTransactionItem : contains
    
    %% Relasi: 1 Kategori memiliki banyak Produk
    Category "1" <-- "many" Product : belongs to

    %% Dependensi: DatabaseService mengelola model-model
    DatabaseService ..> Category : manages
    DatabaseService ..> Product : manages
    DatabaseService ..> PosTransaction : manages
    DatabaseService ..> RefillRecord : manages
    DatabaseService ..> Cashier : manages

    %% Dependensi: AuthProvider mengelola sesi Firebase Auth (Owner)
    AuthProvider ..> Owner : authenticates

    %% Dependensi: SyncService mengatur sinkronisasi
    SyncService --> DatabaseService : reads unsynced
    SyncService --> FirestoreService : writes to cloud
    SyncService ..> RevenueCatService : checks premium status

    %% Dependensi: Providers memanggil Service/Model
    CashierProvider --> DatabaseService : queries
    CashierProvider ..> Cashier : stores state
    SessionProvider ..> Cashier : utilizes for login
    CategoryProvider --> DatabaseService : queries
    CategoryProvider ..> Category : stores state
```
