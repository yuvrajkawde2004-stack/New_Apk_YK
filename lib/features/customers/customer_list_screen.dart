import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/models/customer.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/ledger_pdf_service.dart';
import 'customer_profile_screen.dart';
import 'contact_selection_sheet.dart';
import 'add_customer_screen.dart';

List<Customer> _parseCustomers(List<Map<String, dynamic>> data) {
  return data.map<Customer>((json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      notes: json['address'],
      outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();
}

class CustomerListScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onAddCustomer;

  const CustomerListScreen({
    super.key,
    this.isEmbedded = false,
    this.onAddCustomer,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';
  List<Customer> _dbCustomers = [];
  bool _isLoading = true;
  final NumberFormat _fmt = NumberFormat('#,##,##0');

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color buttonGreen = Color(0xFF10B981);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await DatabaseHelper.instance.getCustomers();
    final customers = await compute(_parseCustomers, data);
    
    if (mounted) {
      setState(() {
        _dbCustomers = customers;
        _isLoading = false;
      });
    }
  }

  List<Customer> get _filtered {
    if (_searchQuery.isEmpty) return _dbCustomers;
    return _dbCustomers.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (c.phone?.contains(_searchQuery) ?? false)).toList();
  }

  Future<void> _generateAllPendingCustomersPdf() async {
    final pendingCustomers = _dbCustomers.where((c) => c.outstandingBalance > 0).toList();
    if (pendingCustomers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending customers found.')));
      }
      return;
    }

    try {
      double totalPending = 0.0;
      final List<Map<String, dynamic>> customersMap = [];
      for (var c in pendingCustomers) {
        totalPending += c.outstandingBalance;
        customersMap.add({
          'name': c.name,
          'phone': c.phone,
          'notes': c.notes,
          'due': c.outstandingBalance,
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('shop_name') ?? 'Our Shop';

      final pdfBytes = await LedgerPdfService.generatePendingCustomersReportPdf(
        shopName: shopName,
        totalPending: totalPending,
        pendingCustomers: customersMap,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/All_Pending_Customers_Report.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: '$shopName - All Pending Customers Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    double totalDue = _dbCustomers.fold(0.0, (sum, item) => sum + item.outstandingBalance);
    int totalCustomers = _dbCustomers.length;

    return Scaffold(
      backgroundColor: backgroundLight,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCustomerScreen(onCustomerAdded: _loadCustomers),
            ),
          );
          _loadCustomers();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Customer',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 1500.ms),
      ),
      appBar: AppBar(
        title: Text('Customers', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            onPressed: _generateAllPendingCustomersPdf,
            tooltip: 'Download Pending Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search customer by name or mobile...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, color: primaryGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Total Customers', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('$totalCustomers', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Total Due', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('₹ ${_fmt.format(totalDue)}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final customer = _filtered[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerProfileScreen(
                                customer: customer,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getInitials(customer.name),
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Name & Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customer.phone != null && customer.phone!.isNotEmpty ? customer.phone! : 'No phone',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Due Amount
                              if (customer.outstandingBalance > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Due', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹ ${_fmt.format(customer.outstandingBalance)}',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red.shade600),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                  child: Text('Settled', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                                ),
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
