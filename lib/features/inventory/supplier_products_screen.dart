import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';

class SupplierProductsScreen extends StatefulWidget {
  final String supplierName;
  const SupplierProductsScreen({super.key, required this.supplierName});

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color badgeGreen = Color(0xFFD1FAE5);
  static const Color badgeTextGreen = Color(0xFF059669);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color buttonGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Note: getPurchasesBySupplier gives purchases, but we might want products that have this supplier.
    // Or we show purchases. The mockup shows "Products from Supplier" with Qty and Rate.
    // We'll show purchases by this supplier.
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(widget.supplierName);
    
    // Deduplicate by product name if needed, but showing purchase history as products is fine.
    setState(() {
      _products = pur;
      _loading = false;
    });
  }
  
  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Products from Supplier', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // Top supplier header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: buttonGreen,
                        child: Text(_getInitials(widget.supplierName), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.supplierName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                            Text('Supplier', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: _products.isEmpty
                    ? Center(child: Text('No products found.', style: GoogleFonts.inter(color: Colors.grey.shade500)))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final p = _products[index];
                        final qty = p['quantity'] ?? 0;
                        final rate = (p['purchase_rate'] as num?)?.toDouble() ?? 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                            ),
                            title: Text(p['product_name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: Padding(
                              padding: const EdgeInsets.topOnly(top: 4.0),
                              child: Text('Qty: $qty  |  Rate: ₹${fmt.format(rate)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: badgeGreen, borderRadius: BorderRadius.circular(4)),
                                  child: Text('From Supplier', style: GoogleFonts.inter(fontSize: 9, color: badgeTextGreen, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ],
            ),
    );
  }
}
