import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import 'billing_screen.dart';
import 'templates/invoice_template_classic_gst.dart';
import 'templates/invoice_template_premium_gold.dart';
import 'templates/invoice_template_modern_emerald.dart';
import 'templates/invoice_template_royal_violet.dart';
import 'templates/invoice_template_minimal_slate.dart';

class AllBillsScreen extends StatefulWidget {
  const AllBillsScreen({super.key});

  @override
  State<AllBillsScreen> createState() => _AllBillsScreenState();
}

class _AllBillsScreenState extends State<AllBillsScreen> {
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _filteredBills = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllBills();
  }

  Future<void> _loadAllBills() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final bills = await db.query('bills', orderBy: 'id DESC'); // Get all bills, newest first
    
    if (mounted) {
      setState(() {
        _bills = bills;
        _filteredBills = bills;
        _isLoading = false;
      });
    }
  }

  void _filterBills(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredBills = _bills.where((b) {
        final name = (b['customer_name']?.toString() ?? 'Walk-in Customer').toLowerCase();
        final billNo = (b['bill_number']?.toString() ?? '').toLowerCase();
        final phone = (b['customer_mobile']?.toString() ?? '').toLowerCase();
        return name.contains(lowerQuery) || billNo.contains(lowerQuery) || phone.contains(lowerQuery);
      }).toList();
    });
  }

  void _showBillDetailsModal(BuildContext context, Map<String, dynamic> billData) {
    final screenshotController = ScreenshotController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getBillItems(
              billData['id'] is int ? billData['id'] as int : int.tryParse(billData['id'].toString()) ?? 0),
          builder: (context, itemsSnapshot) {
            if (!itemsSnapshot.hasData) {
              return Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
              );
            }
            final itemsData = itemsSnapshot.data!;

            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, prefSnapshot) {
                if (!prefSnapshot.hasData) {
                  return Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
                  );
                }

                final tmpl = prefSnapshot.data!.getString('invoice_template') ?? 'Premium Gold';
                Widget invoiceWidget;
                if (tmpl == 'Classic GST') {
                  invoiceWidget = InvoiceTemplateClassicGst(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Modern Emerald') {
                  invoiceWidget = InvoiceTemplateModernEmerald(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Royal Violet') {
                  invoiceWidget = InvoiceTemplateRoyalViolet(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Minimal Slate') {
                  invoiceWidget = InvoiceTemplateMinimalSlate(billData: billData, itemsData: itemsData);
                } else {
                  invoiceWidget = InvoiceTemplatePremiumGold(billData: billData, itemsData: itemsData);
                }

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice #${billData['bill_number']}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Screenshot(
                          controller: screenshotController,
                          child: invoiceWidget,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context); // Close the bill preview dialog
                                  
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Edit Bill', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      content: Text('Are you sure you want to edit this bill?', style: GoogleFonts.outfit()),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
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
                                        MaterialPageRoute(builder: (_) => BillingScreen(billToEdit: billData)),
                                      );
                                      _loadAllBills();
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  side: const BorderSide(color: AppColors.royalBlue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.edit_rounded, color: AppColors.royalBlue, size: 20),
                                label: Text('Edit Bill', style: GoogleFonts.outfit(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // close preview
                                  _confirmDeleteBill(context, billData);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  side: BorderSide(color: Colors.red.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                label: Text('Delete Bill', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final image = await screenshotController.capture(pixelRatio: 4.0);
                                if (image == null) return;

                                final directory = await getTemporaryDirectory();
                                final imagePath = await File('${directory.path}/invoice_${billData['bill_number']}.png').create();
                                await imagePath.writeAsBytes(image);

                                await Share.shareXFiles(
                                  [XFile(imagePath.path)],
                                  text: 'Hello ${billData['customer_name']},\n\nHere is your invoice for ₹${billData['grand_total']}.\nThank you for your business!',
                                );
                              } catch (e) {
                                debugPrint('Error sharing bill: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                            label: Text(
                              'Share WhatsApp',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  void _confirmDeleteBill(BuildContext context, Map<String, dynamic> billData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Invoice #${billData['bill_number']}?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this invoice? Deleting will deduct the amount from Today\'s Sales and restore stock items.',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final bId = billData['id'] as int?;
              if (bId != null) {
                await DatabaseHelper.instance.deleteBill(bId);
                _loadAllBills();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice #${billData['bill_number']} deleted successfully!'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('All Bills', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filterBills,
                    decoration: InputDecoration(
                      hintText: 'Search by Customer Name, Phone, or Bill #',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bill List
                Expanded(
                  child: _filteredBills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No bills found', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBills.length,
                          itemBuilder: (context, index) {
                            final d = _filteredBills[index];
                            final name = d['customer_name']?.toString() ?? 'Walk-in Customer';
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
                            final billNumber = d['bill_number']?.toString() ?? '';
                            final amount = d['grand_total']?.toString() ?? '0';
                            final date = d['bill_date']?.toString() ?? '';
                            String formattedDate = date;
                            try {
                              final dt = DateTime.parse(date);
                              formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(dt);
                            } catch (_) {}

                            final dueAmount = (d['due_amount'] as num?)?.toDouble() ?? 0.0;
                            final isPending = dueAmount > 0;
                            final statusColor = isPending ? const Color(0xFFEF4444) : const Color(0xFF10B981);

                            return GestureDetector(
                              onTap: () => _showBillDetailsModal(context, d),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$billNumber • $formattedDate',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppColors.textSecondaryLight,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '₹ $amount',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().slideY(delay: (index * 50).ms, begin: 0.2, end: 0).fadeIn();
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
