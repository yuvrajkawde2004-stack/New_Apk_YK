import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> wipeEntireDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shop_database.db');
    await closeAndReset();
    await deleteDatabase(path);
  }

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
      version: 14,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
    
    if (oldVersion < 3) {
      // Clear old data as requested by user
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS bills');
      await db.execute('DROP TABLE IF EXISTS bill_items');
      await db.execute('DROP TABLE IF EXISTS purchases');
      await db.execute('DROP TABLE IF EXISTS shop_settings');
      
      // Recreate all tables with the new schema including sync_logs
      await _createDatabase(db, newVersion);
    }
    
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          action TEXT NOT NULL,
          record_id TEXT NOT NULL,
          data_json TEXT NOT NULL,
          status TEXT DEFAULT 'pending',
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE bills ADD COLUMN paid_amount REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills ADD COLUMN due_amount REAL DEFAULT 0'); } catch (_) {}
    }

    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE bills ADD COLUMN customer_id INTEGER'); } catch (_) {}
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          phone TEXT,
          address TEXT,
          total_purchased REAL DEFAULT 0,
          total_paid REAL DEFAULT 0,
          outstanding_due REAL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_name TEXT NOT NULL,
          amount_paid REAL NOT NULL,
          payment_method TEXT NOT NULL,
          payment_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      try { await db.execute('ALTER TABLE purchases ADD COLUMN total_amount REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE purchases ADD COLUMN paid_amount REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE purchases ADD COLUMN due_amount REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE purchases ADD COLUMN product_name TEXT'); } catch (_) {}
    }

    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE bills ADD COLUMN shop_name TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills ADD COLUMN shop_gstin TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills ADD COLUMN shop_address TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills ADD COLUMN shop_phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills ADD COLUMN gst REAL DEFAULT 0'); } catch (_) {}
    }

    if (oldVersion < 10) {
      try {
        await db.insert('products', {
          'id': 0,
          'product_name': 'Custom Item / Service',
          'category': 'System',
          'purchase_rate': 0.0,
          'quantity': 0,
          'low_stock_limit': 0,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        // Ignore if exists
      }
    }

    if (oldVersion < 11) {
      try {
        await db.delete('products');
        await db.delete('purchases');
        await db.delete('bills');
        await db.delete('bill_items');
        await db.delete('sync_logs');
      } catch (_) {}
    }

    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          bill_id INTEGER NOT NULL,
          amount_paid REAL NOT NULL,
          payment_method TEXT NOT NULL,
          payment_date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 14) {
      // 1. Add unit column to products
      try { await db.execute("ALTER TABLE products ADD COLUMN unit TEXT DEFAULT 'PCS'"); } catch (_) {}
      
      // 2. Create units table for suggestions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS units(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      
      // Insert default units
      final defaultUnits = [
        'PCS', 'PAIR', 'KG', 'G', 'MTR', 'ROLL', 'BOX', 
        'PACK', 'SET', 'DOZ', 'LTR', 'ML'
      ];
      for (String unit in defaultUnits) {
        try {
          await db.insert('units', {'name': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (_) {}
      }
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
        updated_at TEXT,
        unit TEXT DEFAULT 'PCS'
      )
    ''');

    // UNITS TABLE
    await db.execute('''
      CREATE TABLE units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    
    final defaultUnits = [
      'PCS', 'PAIR', 'KG', 'G', 'MTR', 'ROLL', 'BOX', 
      'PACK', 'SET', 'DOZ', 'LTR', 'ML'
    ];
    for (String unit in defaultUnits) {
      await db.insert('units', {'name': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

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
        customer_id INTEGER,
        customer_name TEXT,
        customer_mobile TEXT,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        gst REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
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
        product_id INTEGER,
        product_name TEXT,
        supplier_name TEXT,
        purchase_rate REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
        purchase_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
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

    // SUPPLIERS TABLE
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        address TEXT,
        total_purchased REAL DEFAULT 0,
        total_paid REAL DEFAULT 0,
        outstanding_due REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // SUPPLIER PAYMENTS TABLE
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_name TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // SYNC LOGS TABLE
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // CUSTOMER PAYMENTS TABLE
    await db.execute('''
      CREATE TABLE customer_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        bill_id INTEGER NOT NULL,
        amount_paid REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Insert Dummy Product for Custom Items (id = 0)
    try {
      await db.insert('products', {
        'id': 0,
        'product_name': 'Custom Item / Service',
        'category': 'System',
        'purchase_rate': 0.0,
        'quantity': 0,
        'low_stock_limit': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ==========================
  // SYNC LOGGING HELPER
  // ==========================
  Future<void> _logSyncAction(DatabaseExecutor db, String tableName, String action, String recordId, Map<String, dynamic> data) async {
    try {
      await db.insert('sync_logs', {
        'table_name': tableName,
        'action': action,
        'record_id': recordId,
        'data_json': jsonEncode(data),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Sync Log Error: $e');
    }
  }

  // ==========================
  // 1.5 CUSTOMERS CRUD
  // ==========================
  
  Future<int> addCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    customer['created_at'] = DateTime.now().toIso8601String();
    int id = await db.insert(
      'customers',
      customer,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logSyncAction(db, 'customers', 'INSERT', id.toString(), customer);
    return id;
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
    int count = await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logSyncAction(db, 'customers', 'UPDATE', id.toString(), customer);
    return count;
  }

  Future<int> updateCustomerDues(int id, double addedDues) async {
    final db = await database;
    int count = await db.rawUpdate('''
      UPDATE customers
      SET outstanding_balance = outstanding_balance + ?
      WHERE id = ?
    ''', [addedDues, id]);
    await _logSyncAction(db, 'customers', 'UPDATE', id.toString(), {'added_dues': addedDues});
    return count;
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    int count = await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logSyncAction(db, 'customers', 'DELETE', id.toString(), {'id': id});
    return count;
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

    int id = await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logSyncAction(db, 'products', 'INSERT', id.toString(), product);
    return id;
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

    int count = await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logSyncAction(db, 'products', 'UPDATE', id.toString(), product);
    return count;
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;

    int count = await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logSyncAction(db, 'products', 'DELETE', id.toString(), {'id': id});
    return count;
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
      try { await txn.execute('ALTER TABLE bills ADD COLUMN customer_id INTEGER'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN paid_amount REAL DEFAULT 0'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN due_amount REAL DEFAULT 0'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN shop_name TEXT'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN shop_gstin TEXT'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN shop_address TEXT'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN shop_phone TEXT'); } catch (_) {}
      try { await txn.execute('ALTER TABLE bills ADD COLUMN gst REAL DEFAULT 0'); } catch (_) {}

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

      // Auto Upsert Customer Profile in Customers List & update dues/spending
      final custMobile = (bill['customer_mobile'] ?? '').toString().trim();
      final custName = (bill['customer_name'] ?? '').toString().trim();
      final dueAmount = (bill['due_amount'] as num?)?.toDouble() ?? 0.0;
      final grandTotal = (bill['grand_total'] as num?)?.toDouble() ?? 0.0;

      if (custName.isNotEmpty && custMobile.isNotEmpty && custMobile != 'N/A') {
        final existingCust = await txn.query('customers', where: 'phone = ?', whereArgs: [custMobile], limit: 1);
        if (existingCust.isNotEmpty) {
          final cId = existingCust.first['id'] as int;
          await txn.rawUpdate(
            'UPDATE customers SET total_spent = total_spent + ?, outstanding_balance = outstanding_balance + ?, name = ? WHERE id = ?',
            [grandTotal, dueAmount, custName, cId],
          );
        } else {
          await txn.insert('customers', {
            'name': custName,
            'phone': custMobile,
            'address': '',
            'total_spent': grandTotal,
            'outstanding_balance': dueAmount,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
      
      // Log bill creation for sync
      await _logSyncAction(txn, 'bills', 'INSERT', billId.toString(), {
        'bill': bill,
        'items': items,
      });
      
      return billId;
    });
  }

  Future<int> updateCompleteBill(int billId, Map<String, dynamic> bill, List<Map<String, dynamic>> items) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Revert Old Bill Effects
      final oldBills = await txn.query('bills', where: 'id = ?', whereArgs: [billId], limit: 1);
      if (oldBills.isNotEmpty) {
        final oldBill = oldBills.first;
        final oldItems = await txn.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);

        // Restore old product stock
        for (var item in oldItems) {
          final pId = (item['product_id'] as int?) ?? 0;
          final qty = (item['quantity'] as int?) ?? 0;
          if (pId > 0 && qty > 0) {
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [qty, pId],
            );
          }
        }

        // Revert old Customer Total Spent & Outstanding Balance
        final oldCustMobile = (oldBill['customer_mobile'] ?? '').toString().trim();
        final oldGrandTotal = (oldBill['grand_total'] as num?)?.toDouble() ?? 0.0;
        final oldDueAmount = (oldBill['due_amount'] as num?)?.toDouble() ?? 0.0;

        if (oldCustMobile.isNotEmpty && oldCustMobile != 'N/A') {
          final existingCust = await txn.query('customers', where: 'phone = ?', whereArgs: [oldCustMobile], limit: 1);
          if (existingCust.isNotEmpty) {
            final cId = existingCust.first['id'] as int;
            final curSpent = (existingCust.first['total_spent'] as num?)?.toDouble() ?? 0.0;
            final curDues = (existingCust.first['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
            final newSpent = (curSpent - oldGrandTotal) > 0 ? (curSpent - oldGrandTotal) : 0.0;
            final newDues = (curDues - oldDueAmount) > 0 ? (curDues - oldDueAmount) : 0.0;

            await txn.update(
              'customers',
              {
                'total_spent': newSpent,
                'outstanding_balance': newDues,
              },
              where: 'id = ?',
              whereArgs: [cId],
            );
          }
        }

        // Delete old bill items
        await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
      }

      // 2. Update Bill Record
      await txn.update(
        'bills',
        bill,
        where: 'id = ?',
        whereArgs: [billId],
      );

      // 3. Apply New Bill Effects
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

      // Apply New Customer Balances
      final custMobile = (bill['customer_mobile'] ?? '').toString().trim();
      final custName = (bill['customer_name'] ?? '').toString().trim();
      final dueAmount = (bill['due_amount'] as num?)?.toDouble() ?? 0.0;
      final grandTotal = (bill['grand_total'] as num?)?.toDouble() ?? 0.0;

      if (custName.isNotEmpty && custMobile.isNotEmpty && custMobile != 'N/A') {
        final existingCust = await txn.query('customers', where: 'phone = ?', whereArgs: [custMobile], limit: 1);
        if (existingCust.isNotEmpty) {
          final cId = existingCust.first['id'] as int;
          await txn.rawUpdate(
            'UPDATE customers SET total_spent = total_spent + ?, outstanding_balance = outstanding_balance + ?, name = ? WHERE id = ?',
            [grandTotal, dueAmount, custName, cId],
          );
        } else {
          await txn.insert('customers', {
            'name': custName,
            'phone': custMobile,
            'address': '',
            'total_spent': grandTotal,
            'outstanding_balance': dueAmount,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
      
      // Log bill update for sync
      await _logSyncAction(txn, 'bills', 'UPDATE', billId.toString(), {
        'bill': bill,
        'items': items,
      });
      
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

    return await db.transaction((txn) async {
      final bills = await txn.query('bills', where: 'id = ?', whereArgs: [id], limit: 1);
      if (bills.isEmpty) return 0;
      final bill = bills.first;

      final items = await txn.query('bill_items', where: 'bill_id = ?', whereArgs: [id]);

      // 1. Restore product stock
      for (var item in items) {
        final pId = (item['product_id'] as int?) ?? 0;
        final qty = (item['quantity'] as int?) ?? 0;
        if (pId > 0 && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [qty, pId],
          );
        }
      }

      // 2. Adjust Customer Total Spent & Outstanding Balance
      final custMobile = (bill['customer_mobile'] ?? '').toString().trim();
      final grandTotal = (bill['grand_total'] as num?)?.toDouble() ?? 0.0;
      final dueAmount = (bill['due_amount'] as num?)?.toDouble() ?? 0.0;

      if (custMobile.isNotEmpty && custMobile != 'N/A') {
        final existingCust = await txn.query('customers', where: 'phone = ?', whereArgs: [custMobile], limit: 1);
        if (existingCust.isNotEmpty) {
          final cId = existingCust.first['id'] as int;
          final curSpent = (existingCust.first['total_spent'] as num?)?.toDouble() ?? 0.0;
          final curDues = (existingCust.first['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
          final newSpent = (curSpent - grandTotal) > 0 ? (curSpent - grandTotal) : 0.0;
          final newDues = (curDues - dueAmount) > 0 ? (curDues - dueAmount) : 0.0;

          await txn.update(
            'customers',
            {
              'total_spent': newSpent,
              'outstanding_balance': newDues,
            },
            where: 'id = ?',
            whereArgs: [cId],
          );
        }
      }

      // 3. Delete bill items and bill
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [id]);
      final count = await txn.delete('bills', where: 'id = ?', whereArgs: [id]);

      // 4. Log Sync action
      await _logSyncAction(txn, 'bills', 'DELETE', id.toString(), {'id': id, 'bill_number': bill['bill_number']});

      return count;
    });
  }

  Future<int> updateBill(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'bills',
      data,
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

  Future<List<Map<String, dynamic>>> getCustomerBills(int customerId, {String? customerName, String? customerPhone}) async {
    final db = await database;
    if ((customerPhone != null && customerPhone.isNotEmpty) || (customerName != null && customerName.isNotEmpty)) {
      return await db.query(
        'bills',
        where: 'customer_id = ? OR (customer_mobile != "" AND customer_mobile = ?) OR (customer_name != "" AND customer_name = ?)',
        whereArgs: [customerId, customerPhone ?? '', customerName ?? ''],
        orderBy: 'id DESC',
      );
    }
    return await db.query(
      'bills',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
  }

  Future<int> getTotalCustomersCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getTotalProductsCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getPendingCustomersCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM customers WHERE outstanding_balance > 0');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<double> getTotalOutstandingAmount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(outstanding_balance) as total FROM customers');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
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
  // CUSTOMER PAYMENTS
  // ==========================
  Future<void> recordCustomerPayment(int customerId, int billId, double amount, String method, String paymentDate) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Insert into customer_payments
      await txn.insert('customer_payments', {
        'customer_id': customerId,
        'bill_id': billId,
        'amount_paid': amount,
        'payment_method': method,
        'payment_date': paymentDate,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Update bills table
      await txn.rawUpdate('''
        UPDATE bills
        SET paid_amount = paid_amount + ?,
            due_amount = MAX(0, due_amount - ?)
        WHERE id = ?
      ''', [amount, amount, billId]);

      // 3. Update customers table
      await txn.rawUpdate('''
        UPDATE customers
        SET outstanding_balance = MAX(0, outstanding_balance - ?)
        WHERE id = ?
      ''', [amount, customerId]);
    });
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
    WHERE quantity <= low_stock_limit AND id != 0
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

  Future<double> getProfitForPeriod(String period) async {
    final db = await database;
    String dateCondition = '';
    List<dynamic> args = [];

    final today = DateTime.now();

    if (period == 'Daily') {
      dateCondition = 'WHERE b.bill_date LIKE ?';
      args.add('${today.toIso8601String().substring(0, 10)}%');
    } else if (period == 'Monthly') {
      dateCondition = 'WHERE b.bill_date LIKE ?';
      args.add('${today.toIso8601String().substring(0, 7)}%');
    } else if (period == 'Weekly') {
      final weekAgoStr = today.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
      dateCondition = 'WHERE SUBSTR(b.bill_date, 1, 10) >= ?';
      args.add(weekAgoStr);
    }

    final result = await db.rawQuery('''
      SELECT SUM((bi.selling_price - COALESCE(p.purchase_rate, 0)) * bi.quantity) as profit
      FROM bill_items bi
      JOIN bills b ON bi.bill_id = b.id
      LEFT JOIN products p ON bi.product_id = p.id
      $dateCondition
    ''', args);

    return (result.first['profit'] as num?)?.toDouble() ?? 0.0;
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
      WHERE quantity <= low_stock_limit AND id != 0
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

  // ==========================
  // 9. SUPPLIER & PURCHASE LEDGER CRUD
  // ==========================

  Future<int> addSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    supplier['created_at'] = DateTime.now().toIso8601String();
    supplier['is_deleted'] = 0;
    return await db.insert('suppliers', supplier, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    try {
      await db.execute('ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER DEFAULT 0');
    } catch (_) {}
    return await db.query('suppliers', where: 'is_deleted IS NULL OR is_deleted = 0', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getDeletedSuppliers() async {
    final db = await database;
    try {
      await db.execute('ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER DEFAULT 0');
    } catch (_) {}
    return await db.query('suppliers', where: 'is_deleted = 1', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getSupplierByName(String name) async {
    final db = await database;
    final res = await db.query('suppliers', where: 'name = ?', whereArgs: [name], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> supplier) async {
    final db = await database;
    return await db.update('suppliers', supplier, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    try {
      await db.execute('ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER DEFAULT 0');
    } catch (_) {}
    return await db.update('suppliers', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> restoreSupplier(int id) async {
    final db = await database;
    try {
      await db.execute('ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER DEFAULT 0');
    } catch (_) {}
    return await db.update('suppliers', {'is_deleted': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getAverageProfitStats() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        SUM((bi.selling_price - COALESCE(p.purchase_rate, 0)) * bi.quantity) as total_profit,
        SUM(bi.quantity) as total_qty,
        COUNT(DISTINCT bi.bill_id) as total_bills
      FROM bill_items bi
      LEFT JOIN products p ON bi.product_id = p.id
    ''');
    
    double totalProfit = 0.0;
    double totalQty = 0.0;
    double totalBills = 0.0;
    
    if (res.isNotEmpty) {
      totalProfit = (res.first['total_profit'] as num?)?.toDouble() ?? 0.0;
      totalQty = (res.first['total_qty'] as num?)?.toDouble() ?? 0.0;
      totalBills = (res.first['total_bills'] as num?)?.toDouble() ?? 0.0;
    }
    
    double avgProfitPerItem = totalQty > 0 ? (totalProfit / totalQty) : 0.0;
    double avgProfitPerBill = totalBills > 0 ? (totalProfit / totalBills) : 0.0;
    
    return {
      'total_profit': totalProfit,
      'total_qty': totalQty,
      'total_bills': totalBills,
      'avg_profit_per_item': avgProfitPerItem,
      'avg_profit_per_bill': avgProfitPerBill,
    };
  }

  Future<int> recordPurchase({
    required String productName,
    required String supplierName,
    required double purchaseRate,
    required int quantity,
    required double paidAmount,
    String? supplierPhone,
    String? notes,
    double? sellingPrice,
    String? unit,
    int? lowStockLimit,
  }) async {
    final db = await database;
    final totalAmount = purchaseRate * quantity;
    final dueAmount = (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0.0;
    final nowStr = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // 1. Insert Purchase
      final purchaseId = await txn.insert('purchases', {
        'product_id': 0,
        'product_name': productName,
        'supplier_name': supplierName,
        'purchase_rate': purchaseRate,
        'quantity': quantity,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'purchase_date': nowStr,
        'notes': notes ?? '',
        'created_at': nowStr,
      });

      // 2. Update Stock if product exists or create product
      final existingProds = await txn.query('products', where: 'product_name = ?', whereArgs: [productName], limit: 1);
      if (existingProds.isNotEmpty) {
        final pId = existingProds.first['id'] as int;
        
        // Build dynamic update query to include unit and lowStockLimit if provided
        final updates = <String, dynamic>{
          'quantity': (existingProds.first['quantity'] as int? ?? 0) + quantity,
          'purchase_rate': purchaseRate,
        };
        if (unit != null && unit.isNotEmpty) updates['unit'] = unit;
        if (lowStockLimit != null) updates['low_stock_limit'] = lowStockLimit;
        
        await txn.update('products', updates, where: 'id = ?', whereArgs: [pId]);
      } else {
        await txn.insert('products', {
          'product_name': productName,
          'category': 'General',
          'purchase_rate': purchaseRate,
          'quantity': quantity,
          'supplier_name': supplierName,
          'purchase_date': nowStr,
          'notes': notes ?? '',
          'low_stock_limit': lowStockLimit ?? 5,
          'unit': unit ?? 'PCS',
          'created_at': nowStr,
        });
      }

      // 3. Upsert Supplier ledger
      final existingSup = await txn.query('suppliers', where: 'name = ?', whereArgs: [supplierName], limit: 1);
      if (existingSup.isNotEmpty) {
        final supId = existingSup.first['id'] as int;
        final curPurchased = (existingSup.first['total_purchased'] as num?)?.toDouble() ?? 0.0;
        final curPaid = (existingSup.first['total_paid'] as num?)?.toDouble() ?? 0.0;
        final newPurchased = curPurchased + totalAmount;
        final newPaid = curPaid + paidAmount;
        final newDue = (newPurchased - newPaid) > 0 ? (newPurchased - newPaid) : 0.0;

        await txn.update(
          'suppliers',
          {
            'total_purchased': newPurchased,
            'total_paid': newPaid,
            'outstanding_due': newDue,
            if (supplierPhone != null && supplierPhone.isNotEmpty) 'phone': supplierPhone,
          },
          where: 'id = ?',
          whereArgs: [supId],
        );
      } else {
        await txn.insert('suppliers', {
          'name': supplierName,
          'phone': supplierPhone ?? '',
          'address': '',
          'total_purchased': totalAmount,
          'total_paid': paidAmount,
          'outstanding_due': dueAmount,
          'created_at': nowStr,
        });
      }

      await _logSyncAction(txn, 'purchases', 'INSERT', purchaseId.toString(), {
        'product_name': productName,
        'supplier_name': supplierName,
        'purchase_rate': purchaseRate,
        'quantity': quantity,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
      });

      return purchaseId;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchasesBySupplier(String supplierName) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, pr.unit 
      FROM purchases p 
      LEFT JOIN products pr ON p.product_name = pr.product_name 
      WHERE p.supplier_name = ? 
      ORDER BY p.id DESC
    ''', [supplierName]);
  }

  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, pr.unit 
      FROM purchases p 
      LEFT JOIN products pr ON p.product_name = pr.product_name 
      ORDER BY p.id DESC
    ''');
  }

  Future<int> recordSupplierPayment({
    required String supplierName,
    required double amountPaid,
    required String paymentMethod,
    String? notes,
  }) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final payId = await txn.insert('supplier_payments', {
        'supplier_name': supplierName,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        'payment_date': nowStr,
        'notes': notes ?? '',
        'created_at': nowStr,
      });

      final existingSup = await txn.query('suppliers', where: 'name = ?', whereArgs: [supplierName], limit: 1);
      if (existingSup.isNotEmpty) {
        final supId = existingSup.first['id'] as int;
        final curPaid = (existingSup.first['total_paid'] as num?)?.toDouble() ?? 0.0;
        final curPurchased = (existingSup.first['total_purchased'] as num?)?.toDouble() ?? 0.0;
        final newPaid = curPaid + amountPaid;
        final newDue = (curPurchased - newPaid) > 0 ? (curPurchased - newPaid) : 0.0;

        await txn.update(
          'suppliers',
          {
            'total_paid': newPaid,
            'outstanding_due': newDue,
          },
          where: 'id = ?',
          whereArgs: [supId],
        );
      }

      await _logSyncAction(txn, 'supplier_payments', 'INSERT', payId.toString(), {
        'supplier_name': supplierName,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        'payment_date': nowStr,
      });

      return payId;
    });
  }

  Future<List<Map<String, dynamic>>> getSupplierPayments(String supplierName) async {
    final db = await database;
    return await db.query('supplier_payments', where: 'supplier_name = ?', whereArgs: [supplierName], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getProductProfitBreakdown() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.product_name,
        COALESCE(SUM(bi.quantity), 0) as total_qty_sold,
        COALESCE(SUM((bi.selling_price - p.purchase_rate) * bi.quantity), 0.0) as total_product_profit
      FROM products p
      LEFT JOIN bill_items bi ON (p.id = bi.product_id OR LOWER(p.product_name) = LOWER(bi.product_name))
      GROUP BY p.id, p.product_name
      ORDER BY total_product_profit DESC, p.product_name ASC
    ''');
  }

  Future<void> clearAllProductsAndDatabaseData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      await txn.delete('purchases');
      await txn.delete('bills');
      await txn.delete('bill_items');
      await txn.delete('sync_logs');
    });
  }
  // ==========================
  // 10. UNITS CRUD
  // ==========================

  Future<List<String>> getUnits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('units', orderBy: 'name ASC');
    return maps.map((e) => e['name'] as String).toList();
  }

  Future<void> addUnit(String name) async {
    final db = await database;
    try {
      await db.insert('units', {'name': name.toUpperCase()}, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (_) {}
  }
}
