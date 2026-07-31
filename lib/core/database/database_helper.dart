import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shop_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL UNIQUE,
          address TEXT,
          total_spent REAL DEFAULT 0,
          outstanding_balance REAL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }
  }

  // ==========================
  // 1. TABLES SETUP
  // ==========================
  Future<void> _createDatabase(Database db, int version) async {
    // PRODUCTS TABLE
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT NOT NULL,
        category TEXT,
        purchase_rate REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        supplier_name TEXT,
        purchase_date TEXT,
        notes TEXT,
        low_stock_limit INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // CUSTOMERS TABLE
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        address TEXT,
        total_spent REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // BILLS TABLE
    await db.execute('''
      CREATE TABLE bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL UNIQUE,
        customer_name TEXT,
        customer_mobile TEXT,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        gst REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        bill_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // BILL ITEMS TABLE
    await db.execute('''
      CREATE TABLE bill_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        selling_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY(bill_id) REFERENCES bills(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    // PURCHASES TABLE
    await db.execute('''
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        supplier_name TEXT,
        purchase_rate REAL NOT NULL,
        quantity INTEGER NOT NULL,
        purchase_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    // SHOP SETTINGS TABLE
    await db.execute('''
      CREATE TABLE shop_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        shop_logo TEXT,
        address TEXT,
        mobile TEXT,
        gst_number TEXT,
        footer TEXT,
        currency TEXT DEFAULT '₹'
      )
    ''');

    // SEED INITIAL DATA
    final now = DateTime.now().toIso8601String();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Initial Products
    await db.rawInsert('''
      INSERT INTO products (product_name, category, purchase_rate, quantity, supplier_name, low_stock_limit, created_at)
      VALUES 
      ('Kanjivaram Silk Saree', 'Saree', 8000, 15, 'Varanasi Weavers', 5, ?),
      ('Cotton Kurti - Block Print', 'Kurti', 600, 3, 'Jaipur Prints', 5, ?),
      ('Bridal Lehenga Set', 'Lehenga', 28000, 2, 'Delhi Fashion', 5, ?),
      ('Georgette Dupatta', 'Dupatta', 350, 25, 'Surat Mills', 5, ?),
      ('Salwar Suit Set', 'Suit', 1800, 8, 'Ludhiana Apparel', 5, ?)
    ''', [now, now, now, now, now]);

    // Initial Bills
    await db.rawInsert('''
      INSERT INTO bills (bill_number, customer_name, customer_mobile, subtotal, discount, gst, grand_total, payment_method, bill_date, created_at)
      VALUES 
      ('INV00001', 'Priya Sharma', '9876543210', 3200, 0, 160, 3360, 'Cash', ?, ?),
      ('INV00002', 'Rahul Mehta', '9123456789', 7850, 200, 392, 8042, 'UPI', ?, ?),
      ('INV00003', 'Sunita Devi', '9345678901', 1100, 0, 55, 1155, 'Card', ?, ?)
    ''', ['$todayStr 10:30:00', now, '$todayStr 12:15:00', now, '$todayStr 14:00:00', now]);

    // Initial Shop Settings
    await db.rawInsert('''
      INSERT INTO shop_settings (shop_name, address, mobile, gst_number, footer)
      VALUES ('RetailFlow', 'Main Market, Cloth Line', '9876543210', '27AAAAA0000A1Z5', 'Thank you for shopping with us!')
    ''');
  }

  // ==========================
  // 1.5 CUSTOMERS CRUD
  // ==========================
  
  Future<int> addCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    customer['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      'customers',
      customer,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers({int limit = 50, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'customers',
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    final db = await database;
    customer['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String keyword) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );
  }

  // ==========================
  // 2. PRODUCTS CRUD
  // ==========================

  Future<int> addProduct(Map<String, dynamic> product) async {
    final db = await database;

    return await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProducts({int limit = 20, int offset = 0}) async {
    final db = await database;

    return await db.query(
      'products',
      orderBy: 'product_name ASC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database;

    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<int> updateProduct(
    int id,
    Map<String, dynamic> product,
  ) async {
    final db = await database;

    product['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    String keyword,
  ) async {
    final db = await database;

    return await db.query(
      'products',
      where: '''
      product_name LIKE ?
      OR category LIKE ?
      OR supplier_name LIKE ?
    ''',
      whereArgs: [
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'product_name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT *
    FROM products
    WHERE quantity <= low_stock_limit
    ORDER BY quantity ASC
  ''');
  }

  // ==========================
  // 3. PURCHASE CRUD
  // ==========================

  Future<int> addPurchase(Map<String, dynamic> purchase) async {
    final db = await database;

    return await db.transaction((txn) async {
      final purchaseId = await txn.insert('purchases', purchase);

      // Increase Product Stock
      await txn.rawUpdate(
        '''
        UPDATE products
        SET quantity = quantity + ?
        WHERE id = ?
        ''',
        [
          purchase['quantity'],
          purchase['product_id'],
        ],
      );

      return purchaseId;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;

    return await db.query(
      'purchases',
      orderBy: 'id DESC',
    );
  }

  // ==========================
  // 4. STOCK UPDATE METHODS
  // ==========================

  Future<void> reduceStock(
    int productId,
    int qty,
  ) async {
    final db = await database;

    await db.rawUpdate(
      '''
    UPDATE products
    SET quantity = quantity - ?
    WHERE id = ?
    ''',
      [qty, productId],
    );
  }

  Future<void> increaseStock(
    int productId,
    int qty,
  ) async {
    final db = await database;

    await db.rawUpdate(
      '''
    UPDATE products
    SET quantity = quantity + ?
    WHERE id = ?
    ''',
      [qty, productId],
    );
  }

  // ==========================
  // 5. BILLS CRUD
  // ==========================

  Future<int> addBill(Map<String, dynamic> bill) async {
    final db = await database;

    return await db.insert(
      'bills',
      bill,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBills({int limit = 20, int offset = 0}) async {
    final db = await database;

    return await db.query(
      'bills',
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> createCompleteBill(Map<String, dynamic> bill, List<Map<String, dynamic>> items) async {
    final db = await database;

    return await db.transaction((txn) async {
      final billId = await txn.insert(
        'bills',
        bill,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var item in items) {
        item['bill_id'] = billId;
        await txn.insert('bill_items', item);

        // Decrease stock
        await txn.rawUpdate(
          '''
          UPDATE products
          SET quantity = quantity - ?
          WHERE id = ?
          ''',
          [item['quantity'], item['product_id']],
        );
      }
      return billId;
    });
  }

  Future<Map<String, dynamic>?> getBillById(int id) async {
    final db = await database;

    final result = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<int> deleteBill(int id) async {
    final db = await database;

    return await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> generateBillNumber() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT MAX(id) as lastId FROM bills',
    );

    int nextId = ((result.first['lastId'] as int?) ?? 0) + 1;

    return 'INV${nextId.toString().padLeft(5, '0')}';
  }

  Future<List<Map<String, dynamic>>> searchBills(String keyword) async {
    final db = await database;

    return await db.query(
      'bills',
      where: '''
      bill_number LIKE ?
      OR customer_name LIKE ?
      OR customer_mobile LIKE ?
    ''',
      whereArgs: [
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'id DESC',
    );
  }

  // ==========================
  // 6. BILL ITEMS CRUD
  // ==========================

  Future<int> addBillItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('bill_items', item);
  }

  Future<List<Map<String, dynamic>>> getBillItems(int billId) async {
    final db = await database;

    return await db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
  }

  // ==========================
  // 7. SHOP SETTINGS
  // ==========================

  Future<int> saveShopSettings(Map<String, dynamic> data) async {
    final db = await database;

    final result = await db.query('shop_settings');

    if (result.isEmpty) {
      return await db.insert('shop_settings', data);
    } else {
      return await db.update(
        'shop_settings',
        data,
        where: 'id = ?',
        whereArgs: [result.first['id']],
      );
    }
  }

  Future<Map<String, dynamic>?> getShopSettings() async {
    final db = await database;

    final result = await db.query(
      'shop_settings',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // ==========================
  // 8. DASHBOARD & METRICS
  // ==========================

  Future<int> getLowStockProductsCount() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) AS total
    FROM products
    WHERE quantity <= low_stock_limit
  ''');

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalProducts() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) as total FROM products');

    return result.first['total'] as int;
  }

  Future<int> getTotalBills() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) as total FROM bills');

    return result.first['total'] as int;
  }

  Future<double> getTodaySales() async {
    final db = await database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery(
      '''
    SELECT SUM(grand_total) as total
    FROM bills
    WHERE bill_date LIKE ?
    ''',
      ['$today%'],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getMonthlySales() async {
    final db = await database;

    final month = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery(
      '''
    SELECT SUM(grand_total) as total
    FROM bills
    WHERE bill_date LIKE ?
    ''',
      ['$month%'],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // Recent Bills (Last 5 bills)
  Future<List<Map<String, dynamic>>> getRecentBills() async {
    final db = await database;
    return await db.query(
      'bills',
      orderBy: 'id DESC',
      limit: 5,
    );
  }

  // Low Stock List Preview (Items where quantity <= low_stock_limit)
  Future<List<Map<String, dynamic>>> getLowStockPreviewList() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM products
      WHERE quantity <= low_stock_limit
      ORDER BY quantity ASC
      LIMIT 5
    ''');
  }

  // ==========================
  // 8.1. WEEKLY SALES CHART DATA
  // ==========================
  Future<List<Map<String, dynamic>>> getWeeklySalesData() async {
    final db = await database;
    final List<Map<String, dynamic>> weeklySales = [];

    // Loop for last 7 days
    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String dateStr = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
      String dayName =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

      final result = await db.rawQuery(
        '''
      SELECT SUM(grand_total) as total
      FROM bills
      WHERE bill_date LIKE ?
      ''',
        ['$dateStr%'],
      );

      double totalSales = (result.first['total'] as num?)?.toDouble() ?? 0.0;

      weeklySales.add({
        'day': dayName,
        'date': dateStr,
        'sales': totalSales,
      });
    }

    return weeklySales;
  }
}
