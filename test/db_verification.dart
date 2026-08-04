import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:professional_cloth_shop/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database Full Verification Test', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    expect(db.isOpen, true);

    // 1. Verify Tables
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((t) => t['name'] as String).toList();
    print('Tables created in SQLite: $tableNames');

    expect(tableNames.contains('products'), true);
    expect(tableNames.contains('customers'), true);
    expect(tableNames.contains('bills'), true);
    expect(tableNames.contains('bill_items'), true);
    expect(tableNames.contains('purchases'), true);
    expect(tableNames.contains('suppliers'), true);
    expect(tableNames.contains('supplier_payments'), true);
    expect(tableNames.contains('sync_logs'), true);

    // 2. Product Insertion Test
    final prodId = await dbHelper.addProduct({
      'product_name': 'Designer Cotton Saree Test',
      'category': 'Sarees',
      'purchase_rate': 850.0,
      'quantity': 15,
      'supplier_name': 'Surat Textile Hub',
      'low_stock_limit': 5,
      'created_at': DateTime.now().toIso8601String(),
    });
    expect(prodId > 0, true);

    // 3. Purchase Recording & Auto Supplier Ledger Test
    final purchaseId = await dbHelper.recordPurchase(
      productName: 'Silk Dupatta Test',
      supplierName: 'Bombay Fabrics Test',
      purchaseRate: 250.0,
      quantity: 20,
      paidAmount: 3000.0,
      supplierPhone: '9822012345',
      notes: 'New stock',
    );
    expect(purchaseId > 0, true);

    final suppliers = await dbHelper.getSuppliers();
    expect(suppliers.isNotEmpty, true);
    final sup = suppliers.firstWhere((s) => s['name'] == 'Bombay Fabrics Test');
    expect(sup['total_purchased'], 5000.0);
    expect(sup['total_paid'], 3000.0);
    expect(sup['outstanding_due'], 2000.0);

    // 4. Bill Generation & Customer Dues Test
    final billNo = await dbHelper.generateBillNumber();
    final billId = await dbHelper.createCompleteBill(
      {
        'bill_number': billNo,
        'customer_name': 'Anita Patil Test',
        'customer_mobile': '9890129999',
        'subtotal': 2500.0,
        'discount': 0.0,
        'gst': 0.0,
        'grand_total': 2500.0,
        'paid_amount': 1500.0,
        'due_amount': 1000.0,
        'payment_method': 'Cash',
        'bill_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
      [
        {
          'product_id': prodId,
          'product_name': 'Designer Cotton Saree Test',
          'quantity': 1,
          'selling_price': 2500.0,
          'total': 2500.0,
        }
      ],
    );
    expect(billId > 0, true);

    final customers = await dbHelper.getCustomers();
    final cust = customers.firstWhere((c) => c['phone'] == '9890129999');
    expect(cust['name'], 'Anita Patil Test');
    expect(cust['total_spent'], 2500.0);
    expect(cust['outstanding_balance'], 1000.0);

    // 5. Bill Deletion & Automatic Sales/Stock Deduction Test
    final deleteResult = await dbHelper.deleteBill(billId);
    expect(deleteResult, 1);

    final custAfterDelete = (await dbHelper.getCustomers()).firstWhere((c) => c['phone'] == '9890129999');
    expect(custAfterDelete['total_spent'], 0.0);
    expect(custAfterDelete['outstanding_balance'], 0.0);
    print('✅ Bill Deletion Test Passed! Sales & Dues successfully deducted!');

    // 6. Sync Logs Verification
    final pendingSyncs = await db.query('sync_logs', where: 'status = ?', whereArgs: ['pending']);
    expect(pendingSyncs.isNotEmpty, true);

    print('\n======================================================');
    print('🎉 ALL 6 DATABASE VERIFICATION TESTS PASSED 100% CLEANLY!');
    print('======================================================');
  });
}
