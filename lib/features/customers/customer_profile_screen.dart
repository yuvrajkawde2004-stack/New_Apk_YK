import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/customer.dart';
import '../../core/theme/app_colors.dart';
import '../billing/billing_screen.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/ledger_pdf_service.dart';
import '../billing/templates/invoice_template_classic_white.dart';
import '../billing/templates/invoice_template_minimal_corporate.dart';
import '../billing/templates/invoice_template_modern_indigo.dart';
import '../billing/templates/invoice_template_elegant_emerald.dart';
import '../billing/templates/invoice_template_premium_white.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  List<Map<String, dynamic>> _customerBills = [];
  List<Map<String, dynamic>> _customerPayments = [];
  bool _isLoading = true;
  double _currentOutstanding = 0.0;

  @override
  void initState() {
    super.initState();
    _currentOutstanding = widget.customer.outstandingBalance;
    _loadCustomerBills();
  }

  Future<void> _loadCustomerBills() async {
    try {
      final bills = await DatabaseHelper.instance.getCustomerBills(
        widget.customer.id ?? 0, 
        customerName: widget.customer.name, 
        customerPhone: widget.customer.phone,
      );
      
      double updatedOutstanding = _currentOutstanding;
      if (widget.customer.id != null) {
        final custMap = await DatabaseHelper.instance.getCustomerById(widget.customer.id!);
        if (custMap != null) {
          updatedOutstanding = (custMap['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final payments = await DatabaseHelper.instance.getCustomerPayments(
        widget.customer.id ?? 0,
      );

      if (mounted) {
        setState(() {
          _customerBills = bills;
          _customerPayments = payments;
          _currentOutstanding = updatedOutstanding;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openWhatsAppChat(Map<String, dynamic> bill) async {
    await _showColorInvoicePreview(bill);
  }

  Future<void> _showColorInvoicePreview(Map<String, dynamic> bill) async {
    final billId = bill['id'] is int ? bill['id'] as int : int.tryParse(bill['id'].toString()) ?? 0;
    final itemsData = await DatabaseHelper.instance.getBillItems(billId);
    
    if (!mounted) return;

    final screenshotController = ScreenshotController();

    final billData = {
      'bill_number': bill['bill_number'] ?? 'INV_$billId',
      'customer_name': widget.customer.name,
      'customer_mobile': widget.customer.phone ?? '',
      'subtotal': (bill['subtotal'] as num?)?.toDouble() ?? (bill['grand_total'] as num?)?.toDouble() ?? 0.0,
      'discount': (bill['discount'] as num?)?.toDouble() ?? 0.0,
      'gst': (bill['gst'] as num?)?.toDouble() ?? 0.0,
      'grand_total': (bill['grand_total'] as num?)?.toDouble() ?? 0.0,
      'paid_amount': (bill['paid_amount'] as num?)?.toDouble() ?? 0.0,
      'due_amount': (bill['due_amount'] as num?)?.toDouble() ?? 0.0,
      'payment_method': bill['payment_method'] ?? 'Cash',
      'bill_date': bill['bill_date'] ?? DateTime.now().toIso8601String(),
    };

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
            
            final p = snapshot.data!;
            final tmpl = p.getString('invoice_template') ?? 'Classic White';
            
            final updatedBillData = Map<String, dynamic>.from(billData);
            if (p.getString('shop_name') != null) updatedBillData['shop_name'] = p.getString('shop_name');
            if (p.getString('shop_address') != null) updatedBillData['shop_address'] = p.getString('shop_address');
            if (p.getString('shop_phone') != null) updatedBillData['shop_phone'] = p.getString('shop_phone');
            if (p.getString('shop_gstin') != null) updatedBillData['shop_gstin'] = p.getString('shop_gstin');

            Widget invoiceWidget;
            if (tmpl == 'Minimal Corporate') {
              invoiceWidget = InvoiceTemplateMinimalCorporate(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Modern Indigo') {
              invoiceWidget = InvoiceTemplateModernIndigo(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Elegant Emerald') {
              invoiceWidget = InvoiceTemplateElegantEmerald(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Premium White') {
              invoiceWidget = InvoiceTemplatePremiumWhite(billData: updatedBillData, itemsData: itemsData);
            } else {
              invoiceWidget = InvoiceTemplateClassicWhite(billData: updatedBillData, itemsData: itemsData);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Color Invoice', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 380,
                    child: SingleChildScrollView(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Screenshot(
                            controller: screenshotController,
                            child: invoiceWidget,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final image = await screenshotController.capture(pixelRatio: 4.0);
                          if (image == null) return;
                          
                          final directory = await getTemporaryDirectory();
                          final custName = (billData['customer_name'] ?? 'Customer').toString().replaceAll(' ', '_');
                          final imagePath = await File('${directory.path}/${custName}_Bill.png').create();
                          await imagePath.writeAsBytes(image);
                          
                          await Share.shareXFiles([XFile(imagePath.path)]);
                        } catch (e) {
                          debugPrint('Error sharing color invoice image: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: Text('Share Color Bill on WhatsApp', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSelectBillWhatsAppSheet(BuildContext context) {
    int selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Done Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Select Invoice for WhatsApp',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (_customerBills.isNotEmpty) {
                          _openWhatsAppChat(_customerBills[selectedIndex]);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        'Done',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Customer: ${widget.customer.name} (${widget.customer.phone ?? ""})',
                  style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Bill List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customerBills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final bill = _customerBills[i];
                    final isSelected = selectedIndex == i;

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedIndex = i;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF25D366).withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF25D366) : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: selectedIndex,
                              activeColor: const Color(0xFF25D366),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedIndex = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill['bill_number'] ?? '',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    bill['bill_date'] ?? '',
                                    style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹ ${bill['grand_total']}',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bill['paid'] ? AppColors.emeraldGreen.withValues(alpha: 0.1) : AppColors.softOrange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bill['paid'] ? 'Paid' : 'Pending',
                                    style: GoogleFonts.outfit(
                                      color: bill['paid'] ? AppColors.emeraldGreen : AppColors.softOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_customerBills.isNotEmpty) {
                        _openWhatsAppChat(_customerBills[selectedIndex]);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 20),
                    label: Text(
                      'Send Bill on WhatsApp',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadLedgerPdf() async {
    try {
      final List<Map<String, dynamic>> allTrans = [];

      // Add bills
      for (var b in _customerBills) {
        final billNo = b['bill_number']?.toString() ?? b['id']?.toString() ?? 'Unknown';
        allTrans.add({
          'date': b['bill_date']?.toString().substring(0, 10) ?? '',
          'description': 'Bill #$billNo',
          'total_amt': (b['grand_total'] as num?)?.toDouble() ?? 0.0,
          'paid_amt': (b['paid_amount'] as num?)?.toDouble() ?? 0.0,
          'pending_amt': (b['due_amount'] as num?)?.toDouble() ?? 0.0,
          'is_bill': true,
        });
      }

      // Add payments
      for (var p in _customerPayments) {
        allTrans.add({
          'date': p['payment_date']?.toString().substring(0, 10) ?? '',
          'description': 'Payment Received (${p['payment_method'] ?? 'Cash'})',
          'total_amt': 0.0,
          'paid_amt': (p['amount_paid'] as num?)?.toDouble() ?? 0.0,
          'pending_amt': 0.0,
          'is_bill': false,
        });
      }

      // Sort by date descending
      allTrans.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('shop_name') ?? 'Our Shop';

      final pdfBytes = await LedgerPdfService.generateLedgerPdf(
        title: '$shopName - Customer Ledger',
        partyName: widget.customer.name,
        phone: widget.customer.phone ?? '',
        totalOutstanding: _currentOutstanding,
        transactions: allTrans,
      );

      final tempDir = await getTemporaryDirectory();
      final safeShopName = shopName.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final file = File('${tempDir.path}/${safeShopName}_${widget.customer.name.replaceAll(' ', '_')}_Ledger.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: '$shopName - Ledger Statement for ${widget.customer.name}');
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return "$name".substring(0, 1).toUpperCase(); // mock logic for demo
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF8FAFC), body: Center(child: CircularProgressIndicator(color: Color(0xFF064E3B))));
    }

    // calculate total purchase, paid, due
    double totalPurchase = 0;
    double totalPaid = 0;
    for (var bill in _customerBills) {
       totalPurchase += (bill['grand_total'] as num?)?.toDouble() ?? 0.0;
       totalPaid += (bill['paid_amount'] as num?)?.toDouble() ?? 0.0;
    }
    final totalDue = _currentOutstanding;

    // Use string formatting instead of NumberFormat directly to avoid import issues if intl is not imported properly
    String formatAmt(num amt) {
      return amt.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Customer Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () { /* Edit Customer Logic */ },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(_getInitials(widget.customer.name), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.customer.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                            const SizedBox(height: 4),
                            if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(widget.customer.phone!, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            const SizedBox(height: 4),
                            if (widget.customer.notes != null && widget.customer.notes!.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(widget.customer.notes!, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
                                ],
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildFinancialBlock('Total Purchase', totalPurchase, Colors.blue, formatAmt)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFinancialBlock('Paid', totalPaid, Colors.green, formatAmt)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFinancialBlock('Due', totalDue, Colors.red, formatAmt)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(Icons.receipt_long_outlined, 'Create Bill', const Color(0xFF064E3B), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillingScreen(customer: widget.customer),
                    ),
                  ).then((_) => _loadCustomerBills());
                }),
                _buildQuickAction(Icons.currency_rupee_outlined, 'Add Payment', const Color(0xFF10B981), _showSettleDuesSheet),
                _buildQuickAction(Icons.picture_as_pdf_outlined, 'Share Ledger', Colors.orange, () {
                  if (_customerBills.isNotEmpty) _openWhatsAppChat(_customerBills.first);
                }),
                _buildQuickAction(Icons.more_horiz_outlined, 'More', Colors.grey.shade600, () {}),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Summary
            Text('Customer Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text('Total Bills', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${_customerBills.length}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Last Bill', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_customerBills.isNotEmpty ? (_customerBills.first['bill_date'] ?? 'N/A') : 'N/A', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bill History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
                if (_customerBills.length > 3)
                  Text('See All', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF064E3B))),
              ],
            ),
            const SizedBox(height: 12),
            if (_customerBills.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No bills yet', style: GoogleFonts.inter(color: Colors.grey)),
                ),
              )
            else
              ..._customerBills.map((bill) {
                final isPaid = bill['paid'] == true || ((bill['due_amount'] as num?)?.toDouble() ?? 0) <= 0;
                final isPartial = !isPaid && ((bill['paid_amount'] as num?)?.toDouble() ?? 0) > 0;
                
                String status = isPaid ? 'Paid' : (isPartial ? 'Partial' : 'Due');
                Color statusColor = isPaid ? const Color(0xFF10B981) : (isPartial ? Colors.orange : Colors.red);
                
                return GestureDetector(
                  onTap: () => _showBillOptionsBottomSheet(bill),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF064E3B)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bill['bill_number'] ?? 'Bill', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                              const SizedBox(height: 4),
                              Text(bill['bill_date'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('â‚¹ ${formatAmt(bill['grand_total'] ?? 0))', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                            const SizedBox(height: 4),
                            Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBlock(String label, double amount, MaterialColor color, String Function(num) formatAmt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color.shade700, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('â‚¹ ${formatAmt(amount))', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color.shade900), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  void _showBillOptionsBottomSheet(Map<String, dynamic> bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final billNo = bill['bill_number'] ?? 'INV_${bill['id']}';
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                'Bill: $billNo',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Total: ₹${bill['grand_total']}  |  Paid: ₹${bill['paid_amount']}  |  Due: ₹${bill['due_amount']}',
                style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              if (((bill['due_amount'] as num?)?.toDouble() ?? 0.0) > 0)
                ListTile(
                  leading: const Icon(Icons.payments_rounded, color: Color(0xFF10B981)),
                  title: const Text('Receive Payment', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReceivePaymentSheet(bill);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                title: const Text('View & Share Color Bill', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showColorInvoicePreview(bill);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.royalBlue),
                title: const Text('Edit Bill', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Edit Bill', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to edit this bill?', style: GoogleFonts.outfit()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('OK', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BillingScreen(billToEdit: bill)),
                      );
                      _loadCustomerBills();
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text('Delete Bill', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteBill(bill);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteBill(Map<String, dynamic> bill) {
    final billId = bill['id'] is int ? bill['id'] as int : int.tryParse(bill['id'].toString()) ?? 0;
    final billNo = bill['bill_number'] ?? 'INV_$billId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Bill?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete bill "$billNo"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DatabaseHelper.instance.deleteBill(billId);
              if (mounted) {
                Navigator.pop(ctx);
                _loadCustomerBills();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bill "$billNo" deleted!'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReceivePaymentSheet(Map<String, dynamic> bill) {
    final billId = bill['id'] is int ? bill['id'] as int : int.tryParse(bill['id'].toString()) ?? 0;
    final billNo = bill['bill_number'] ?? 'INV_$billId';
    final dueAmount = (bill['due_amount'] as num?)?.toDouble() ?? 0.0;
    
    double amountToPay = dueAmount;
    String paymentMethod = 'Cash';
    DateTime paymentDate = DateTime.now();
    final amountController = TextEditingController(text: dueAmount.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48, height: 6,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Receive Payment', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                            Text('Invoice: $billNo', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Due Amount Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pending Due', style: GoogleFonts.outfit(color: const Color(0xFFB45309), fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('₹${dueAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF92400E), fontWeight: FontWeight.w900, fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Input
                  Text('Amount Received (₹)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.royalBlue),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.royalBlue, width: 2)),
                    ),
                    onChanged: (val) {
                      amountToPay = double.tryParse(val) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Picker & Payment Mode
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setModalState(() => paymentDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.royalBlue),
                                    const SizedBox(width: 8),
                                    Text('${paymentDate.day}/${paymentDate.month}/${paymentDate.year}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: paymentMethod,
                                  isExpanded: true,
                                  items: ['Cash', 'UPI'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => paymentMethod = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amountToPay <= 0) return;
                        if (amountToPay > dueAmount) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot pay more than due amount!'), backgroundColor: Colors.redAccent));
                          return;
                        }

                        if (paymentMethod == 'UPI') {
                          final prefs = await SharedPreferences.getInstance();
                          final upiId = prefs.getString('upi_id') ?? '';
                          final upiName = prefs.getString('upi_name') ?? '';
                          
                          if (upiId.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please setup UPI in Settings first.')));
                            }
                            return;
                          }
                          
                          Navigator.pop(ctx);
                          _showUpiDialogForOutstanding(amountToPay, billId, upiId, upiName, paymentDate);
                          return;
                        }

                        Navigator.pop(ctx);
                        
                        // Save payment
                        await DatabaseHelper.instance.recordCustomerPayment(
                          widget.customer.id ?? 0,
                          billId,
                          amountToPay,
                          paymentMethod,
                          paymentDate.toIso8601String(),
                        );

                        // Refresh UI
                        _loadCustomerBills();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text('₹${amountToPay.toStringAsFixed(0)} payment received!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 4,
                        shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('CONFIRM PAYMENT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUpiDialogForOutstanding(double amount, int billId, String upiId, String upiName, DateTime paymentDate) {
    final qrData = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(upiName)}&am=$amount&cu=INR';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: AppColors.royalBlue.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, -10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.royalBlue.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.royalBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Scan to Pay', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.royalBlue, Color(0xFF6366F1)]).createShader(bounds),
                    child: Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240, height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(color: AppColors.royalBlue.withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                            BoxShadow(color: AppColors.emeraldGreen.withOpacity(0.1), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10)),
                          ],
                          border: Border.all(color: AppColors.royalBlue.withOpacity(0.1), width: 2),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 200, height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.transparent, AppColors.emeraldGreen, Colors.transparent]),
                            boxShadow: [BoxShadow(color: AppColors.emeraldGreen.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).slideY(begin: 0, end: 60, duration: 2.seconds, curve: Curves.easeInOut),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        
                        await DatabaseHelper.instance.recordCustomerPayment(
                          widget.customer.id ?? 0,
                          billId,
                          amount,
                          'UPI',
                          paymentDate.toIso8601String(),
                        );
                        _loadCustomerBills();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text('₹${amount.toStringAsFixed(0)} payment received!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                      label: Text('MARK AS PAID', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        elevation: 4,
                        shadowColor: AppColors.emeraldGreen.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettleDuesSheet() {
    final allBills = _customerBills;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text('Ledger & Dues (KhataBook)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: allBills.isEmpty
                  ? Center(child: Text('No bills found.', style: GoogleFonts.outfit()))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: allBills.length,
                      itemBuilder: (context, index) {
                        final bill = allBills[index];
                        final dueAmt = (bill['due_amount'] as num?)?.toDouble() ?? 0.0;
                        final paidAmt = (bill['paid_amount'] as num?)?.toDouble() ?? 0.0;
                        final totalAmt = (bill['grand_total'] as num?)?.toDouble() ?? 0.0;
                        final billNo = bill['bill_number'];
                        final isPaid = dueAmt <= 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: ListTile(
                            onTap: () {
                              _showBillOptionsBottomSheet(bill);
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isPaid ? AppColors.emeraldGreen.withOpacity(0.2) : AppColors.softOrange.withOpacity(0.2),
                              child: Icon(Icons.receipt_long, color: isPaid ? AppColors.emeraldGreen : AppColors.softOrange),
                            ),
                            title: Text('Invoice #$billNo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Total: ₹${totalAmt.toStringAsFixed(0)} | Paid: ₹${paidAmt.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700)),
                                if (!isPaid)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('Due: ₹${dueAmt.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                              ]
                            ),
                            trailing: isPaid 
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.emeraldGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Text('PAID', style: GoogleFonts.outfit(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showReceivePaymentSheet(bill); 
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.royalBlue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Pay', style: GoogleFonts.outfit(color: Colors.white)),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
