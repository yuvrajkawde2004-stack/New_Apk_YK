import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/cloudflare_api_service.dart';

class DashboardProvider extends ChangeNotifier {
  double _todaySales = 12557.0;
  double _monthlySales = 1250000.0;
  int _pendingPayments = 12;
  int _lowStockItems = 5;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentBills = [];

  double get todaySales => _todaySales;
  double get monthlySales => _monthlySales;
  int get pendingPayments => _pendingPayments;
  int get lowStockItems => _lowStockItems;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get recentBills => _recentBills;

  DashboardProvider() {
    loadDataFromDatabase();
  }

  Future<void> loadDataFromDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!kIsWeb) {
        final db = DatabaseHelper.instance;
        final today = await db.getTodaySales();
        final monthly = await db.getMonthlySales();
        final lowStock = await db.getLowStockProductsCount();
        final bills = await db.getRecentBills();

        if (today > 0) _todaySales = today;
        if (monthly > 0) _monthlySales = monthly;
        if (lowStock > 0) _lowStockItems = lowStock;
        if (bills.isNotEmpty) _recentBills = bills;
      }

      // Sync with Cloudflare D1 Remote Database
      final cfCustomers = await CloudflareApiService.fetchCustomersFromCloudflare();
      if (cfCustomers.isNotEmpty) {
        _pendingPayments = cfCustomers.where((c) => ((c['outstanding_balance'] ?? 0) as num) > 0).length;
      }
    } catch (e) {
      debugPrint('DashboardProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshDashboard() {
    loadDataFromDatabase();
  }

  void updateStats({
    double? todaySales,
    double? monthlySales,
    int? pendingPayments,
    int? lowStockItems,
  }) {
    if (todaySales != null) _todaySales = todaySales;
    if (monthlySales != null) _monthlySales = monthlySales;
    if (pendingPayments != null) _pendingPayments = pendingPayments;
    if (lowStockItems != null) _lowStockItems = lowStockItems;
    notifyListeners();
  }
}
