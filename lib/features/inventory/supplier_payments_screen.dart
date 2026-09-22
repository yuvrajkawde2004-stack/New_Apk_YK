import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  final String supplierName;
  const SupplierPaymentsScreen({super.key, required this.supplierName});

  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  Map<String, dynamic> _currentSupplier = {};
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final sups = await DatabaseHelper.instance.getSuppliers();
    final updatedSup = sups.firstWhere((s) => s['name'] == widget.supplierName, orElse: () => {'name': widget.supplierName});
    
    final pay = await DatabaseHelper.instance.getSupplierPayments(widget.supplierName);
    
    setState(() {
      _currentSupplier = updatedSup;
      _payments = pay;
      _loading = false;
    });
  }

  void _showAddPaymentDialog() {
    final amtCtrl = TextEditingController();
    String method = 'Cash';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Make Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amtCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount Paid (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Cash', 'UPI', 'Bank Transfer', 'Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => method = v ?? 'Cash',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await DatabaseHelper.instance.recordSupplierPayment(
                  supplierName: _currentSupplier['name'],
                  amountPaid: double.parse(amtCtrl.text),
                  paymentMethod: method,
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: Text('Pay', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final fmt = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Payment Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // Top Summary Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: buttonGreen,
                            child: Text(_getInitials(widget.supplierName), style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.supplierName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('Supplier', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                
                // History Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text('Payment History', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _payments.isEmpty
                    ? Center(child: Text('No payments found.', style: GoogleFonts.inter(color: Colors.grey.shade500)))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final p = _payments[index];
                        final date = DateTime.tryParse(p['payment_date'] ?? '') ?? DateTime.now();
                        final dateStr = DateFormat('dd MMM yyyy').format(date);
                        final method = p['payment_method'] ?? 'CASH';
                        final amt = (p['amount_paid'] as num?)?.toDouble() ?? 0.0;
                        
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: badgeGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: badgeTextGreen, size: 20),
                            ),
                            title: Text('Payment Received', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹ ${fmt.format(amt)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(method, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ],
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
              backgroundColor: buttonGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
              elevation: 0,
            ),
            icon: const Icon(Icons.payment),
            label: Text('Make Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
            onPressed: _showAddPaymentDialog,
          ),
        ),
      ),
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
}
