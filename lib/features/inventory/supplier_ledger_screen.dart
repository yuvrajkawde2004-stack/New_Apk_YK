import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/ledger_pdf_service.dart';
import 'add_purchase_form_screen.dart';
import 'supplier_products_screen.dart';
import 'supplier_payments_screen.dart';

class SupplierLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;
  const SupplierLedgerScreen({super.key, required this.supplier});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  Map<String, dynamic> _currentSupplier = {};
  bool _loading = true;
  int _productCount = 0;
  int _paymentCount = 0;

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color badgeGreen = Color(0xFFD1FAE5);
  static const Color badgeTextGreen = Color(0xFF059669);
  static const Color redDueBg = Color(0xFFFEE2E2);
  static const Color redDueText = Color(0xFFDC2626);
  static const Color blueBg = Color(0xFFE0F2FE);
  static const Color blueText = Color(0xFF0284C7);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color buttonGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _currentSupplier = widget.supplier;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final String supName = _currentSupplier['name'];
    
    final sups = await DatabaseHelper.instance.getSuppliers();
    final updatedSup = sups.firstWhere((s) => s['name'] == supName, orElse: () => _currentSupplier);
    
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(supName);
    final pay = await DatabaseHelper.instance.getSupplierPayments(supName);
    
    setState(() {
      _currentSupplier = updatedSup;
      _productCount = pur.length;
      _paymentCount = pay.length;
      _loading = false;
    });
  }

  Future<void> _downloadPdf() async {
    final String supName = _currentSupplier['name'];
    final phone = _currentSupplier['phone']?.toString() ?? '';
    final due = (_currentSupplier['outstanding_due'] as num?)?.toDouble() ?? 0.0;
    
    // Combine purchases and payments into transactions format
    final List<Map<String, dynamic>> transactions = [];
    
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(supName);
    for (var p in pur) {
      transactions.add({
        'is_bill': true,
        'date': p['purchase_date']?.toString().substring(0, 10) ?? '',
        'description': 'Purchase (${p['product_name'] ?? 'Items'})',
        'total_amt': (p['total_amount'] as num?)?.toDouble() ?? 0.0,
        'paid_amt': (p['paid_amount'] as num?)?.toDouble() ?? 0.0,
      });
    }

    final pay = await DatabaseHelper.instance.getSupplierPayments(supName);
    for (var p in pay) {
      transactions.add({
        'is_bill': false,
        'date': p['payment_date']?.toString().substring(0, 10) ?? '',
        'description': 'Payment (${p['payment_method'] ?? 'Cash'})',
        'total_amt': 0.0,
        'paid_amt': (p['amount_paid'] as num?)?.toDouble() ?? 0.0,
      });
    }

    try {
      final pdfBytes = await LedgerPdfService.generateLedgerPdf(
        title: 'Supplier Ledger',
        partyName: supName,
        phone: phone,
        totalOutstanding: due,
        transactions: transactions,
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = supName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${tempDir.path}/Supplier_Ledger_$sanitizedName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ledger for $supName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double totalPurchased = (_currentSupplier['total_purchased'] as num?)?.toDouble() ?? 0.0;
    final double totalPaid = (_currentSupplier['total_paid'] as num?)?.toDouble() ?? 0.0;
    final double due = (_currentSupplier['outstanding_due'] as num?)?.toDouble() ?? 0.0;
    final fmt = NumberFormat('#,##,##0');

    final phone = (_currentSupplier['phone']?.toString().isNotEmpty ?? false) ? _currentSupplier['phone'].toString() : 'Not provided';
    final email = (_currentSupplier['email']?.toString().isNotEmpty ?? false) ? _currentSupplier['email'].toString() : 'Not provided';
    final address = (_currentSupplier['address']?.toString().isNotEmpty ?? false) ? _currentSupplier['address'].toString() : 'Not provided';

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(_currentSupplier['name'] ?? 'Supplier Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'pdf') {
                _downloadPdf();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text('Download PDF', style: GoogleFonts.inter()),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: buttonGreen,
                              child: Text(_getInitials(_currentSupplier['name']), style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(_currentSupplier['name'], style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: badgeGreen, borderRadius: BorderRadius.circular(6)),
                                        child: Text('Active', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextGreen)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.location_on_outlined, address),
                                  const SizedBox(height: 6),
                                  _buildInfoRow(Icons.phone_outlined, phone),
                                  const SizedBox(height: 6),
                                  _buildInfoRow(Icons.email_outlined, email),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Row(
                          children: [
                            _buildAmountBlock('Total Purchase', totalPurchased, blueBg, blueText),
                            const SizedBox(width: 12),
                            _buildAmountBlock('Paid', totalPaid, badgeGreen, badgeTextGreen),
                            const SizedBox(width: 12),
                            _buildAmountBlock('Due', due, redDueBg, redDueText),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Tiles
                  _buildMenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Products from this Supplier',
                    subtitle: '$_productCount Products',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SupplierProductsScreen(supplierName: _currentSupplier['name'])),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.history_outlined,
                    title: 'Payment History',
                    subtitle: '$_paymentCount Payments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SupplierPaymentsScreen(supplierName: _currentSupplier['name'])),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add),
            label: Text('Add Product', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPurchaseFormScreen(initialSupplierName: _currentSupplier['name']),
                ),
              );
              _loadData(); // Refresh when back from purchase screen
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountBlock(String label, double amount, Color bgColor, Color textColor) {
    final fmt = NumberFormat('#,##,##0');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('₹ ${fmt.format(amount)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}
