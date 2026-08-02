import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/cloudflare_api_service.dart';

class DashboardProvider extends ChangeNotifier {
  String _shopName = 'RetailFlow';
  double _todaySales = 0.0;
  double _monthlySales = 0.0;
  double _pendingPayments = 0.0;
  int _lowStockItems = 0;
  int _totalCustomers = 0;
  int _totalProducts = 0;
  int _totalBills = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentBills = [];

  String get shopName => _shopName;

  double get todaySales => _todaySales;
  double get monthlySales => _monthlySales;
  double get pendingPayments => _pendingPayments;
  int get lowStockItems => _lowStockItems;
  int get totalCustomers => _totalCustomers;
  int get totalProducts => _totalProducts;
  int get totalBills => _totalBills;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get recentBills => _recentBills;

  Future<void> updateShopName(String name) async {
    _shopName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', name);
    notifyListeners();
  }

  DashboardProvider() {
    loadDataFromDatabase();
  }

  Future<void> loadDataFromDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _shopName = prefs.getString('shop_name') ?? 'RetailFlow';

      if (!kIsWeb) {
        final db = DatabaseHelper.instance;
        _todaySales = await db.getTodaySales();
        _monthlySales = await db.getMonthlySales();
        _lowStockItems = await db.getLowStockProductsCount();
        _totalCustomers = await db.getTotalCustomersCount();
        _totalProducts = await db.getTotalProductsCount();
        _totalBills = await db.getTotalBills();
        _pendingPayments = await db.getTotalOutstandingAmount();
        _recentBills = await db.getRecentBills();
      }

      // Sync with Cloudflare D1 Remote Database if available
      try {
        final cfCustomers = await CloudflareApiService.fetchCustomersFromCloudflare();
        if (cfCustomers.isNotEmpty) {
          _pendingPayments = cfCustomers.fold<double>(0.0, (sum, c) => sum + ((c['outstanding_balance'] ?? 0) as num).toDouble());
        }
      } catch (_) {}
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
    double? pendingPayments,
    int? lowStockItems,
  }) {
    if (todaySales != null) _todaySales = todaySales;
    if (monthlySales != null) _monthlySales = monthlySales;
    if (pendingPayments != null) _pendingPayments = pendingPayments;
    if (lowStockItems != null) _lowStockItems = lowStockItems;
    notifyListeners();
  }
}
