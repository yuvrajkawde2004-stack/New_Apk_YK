import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:professional_cloth_shop/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.instance.closeAndReset();
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/shop_database.db';
    await deleteDatabase(path);
  });

  group('DatabaseHelper Comprehensive Test Suite', () {
    final dbHelper = DatabaseHelper.instance;

    test('1. Database Initialization & Schema Verification', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, true);

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames.contains('products'), true);
      expect(tableNames.contains('customers'), true);
      expect(tableNames.contains('bills'), true);
      expect(tableNames.contains('bill_items'), true);
      expect(tableNames.contains('purchases'), true);
      expect(tableNames.contains('suppliers'), true);
      expect(tableNames.contains('supplier_payments'), true);
      expect(tableNames.contains('sync_logs'), true);
      print('✅ All 8 Database Tables Verified Successfully!');
    });

    test('2. Product Addition & Stock Query Test', () async {
      final productId = await dbHelper.addProduct({
        'product_name': 'Test Cotton Shirt',
        'category': 'Shirts',
        'purchase_rate': 400.0,
        'quantity': 20,
        'supplier_name': 'Test Supplier Co',
        'low_stock_limit': 5,
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(productId > 0, true);

      final products = await dbHelper.getProducts(limit: 100);
      expect(products.isNotEmpty, true);
      final found = products.firstWhere((p) => p['id'] == productId);
      expect(found['product_name'], 'Test Cotton Shirt');
      expect(found['quantity'], 20);
      print('✅ Product CRUD & Stock Storage Verified!');
    });

    test('3. Purchase Record & Auto Supplier Ledger Upsert Test', () async {
      final purchaseId = await dbHelper.recordPurchase(
        productName: 'Silk Saree Premium',
        supplierName: 'Rajlaxmi Textiles',
        purchaseRate: 1500.0,
        quantity: 10, // Total = ₹15,000
        paidAmount: 10000.0, // Due = ₹5,000
        supplierPhone: '9876543210',
        notes: 'Bulk purchase',
      );

      expect(purchaseId > 0, true);

      // Check Suppliers Ledger table
      final suppliers = await dbHelper.getSuppliers();
      final supplier = suppliers.firstWhere((s) => s['name'] == 'Rajlaxmi Textiles');
      expect(supplier['total_purchased'], 15000.0);
      expect(supplier['total_paid'], 10000.0);
      expect(supplier['outstanding_due'], 5000.0);
      print('✅ Purchase Recording & Auto Supplier Ledger Upsert Verified! (Due: ₹5,000)');
    });

    test('4. Bill Creation & Auto Customer Upsert & Dues Tracking Test', () async {
      final billNo = await dbHelper.generateBillNumber();
      final billId = await dbHelper.createCompleteBill(
        {
          'bill_number': billNo,
          'customer_name': 'Rahul Sharma',
          'customer_mobile': '9988776655',
          'subtotal': 3000.0,
          'discount': 0.0,
          'gst': 0.0,
          'grand_total': 3000.0,
          'paid_amount': 2000.0,
          'due_amount': 1000.0, // Remaining due
          'payment_method': 'UPI',
          'bill_date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
        [
          {
            'product_id': 1,
            'product_name': 'Test Cotton Shirt',
            'quantity': 2,
            'selling_price': 1500.0,
            'total': 3000.0,
          }
        ],
      );

      expect(billId > 0, true);

      // Verify Customer Auto-Registration & Dues Update
      final customers = await dbHelper.getCustomers();
      final customer = customers.firstWhere((c) => c['phone'] == '9988776655');
      expect(customer['name'], 'Rahul Sharma');
      expect(customer['total_spent'], 3000.0);
      expect(customer['outstanding_balance'], 1000.0);
      print('✅ Bill Creation & Auto Customer Dues Tracking Verified! (Customer Due: ₹1,000)');
    });

    test('5. Sync Logs Generation for Cloudflare Sync', () async {
      final db = await dbHelper.database;
      final pendingSyncs = await db.query('sync_logs', where: 'status = ?', whereArgs: ['pending']);
      expect(pendingSyncs.isNotEmpty, true);
      print('✅ Sync Logs Verified! (${pendingSyncs.length} pending logs queued for Cloudflare Sync)');
    });
  });
}
