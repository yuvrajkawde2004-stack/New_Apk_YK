import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import 'supplier_ledger_screen.dart';
import 'add_supplier_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddPurchaseScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? initialSupplierName;
  const AddPurchaseScreen({super.key, this.onSaved, this.initialSupplierName});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  List<Map<String, dynamic>> _allSuppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Due, Paid

  // Premium colors
  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color badgeGreen = Color(0xFFD1FAE5);
  static const Color badgeTextGreen = Color(0xFF059669);
  static const Color redDue = Color(0xFFDC2626);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color buttonGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final sups = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      _allSuppliers = sups;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    _filteredSuppliers = _allSuppliers.where((sup) {
      // Search filter
      final nameMatches = sup['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      if (!nameMatches) return false;

      // Status filter
      final due = (sup['outstanding_due'] as num?)?.toDouble() ?? 0.0;
      if (_selectedFilter == 'Due' && due <= 0) return false;
      if (_selectedFilter == 'Paid' && due > 0) return false;
      
      return true;
    }).toList();
  }

  void _showAddSupplierDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
    );
    if (result == true) {
      _loadSuppliers();
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Suppliers', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0),
            child: InkWell(
              onTap: _showAddSupplierDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: buttonGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('Add Supplier', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            color: primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFilters();
                  });
                },
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search supplier...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Active'),
                const SizedBox(width: 8),
                _buildFilterChip('Due'),
                const SizedBox(width: 8),
                _buildFilterChip('Paid'),
              ],
            ),
          ),
          
          // List Section
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : _filteredSuppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No suppliers found.', style: GoogleFonts.inter(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final sup = _filteredSuppliers[index];
                          final fmt = NumberFormat('#,##,##0');
                          final totalPurchased = (sup['total_purchased'] as num?)?.toDouble() ?? 0.0;
                          final totalPaid = (sup['total_paid'] as num?)?.toDouble() ?? 0.0;
                          final due = (sup['outstanding_due'] as num?)?.toDouble() ?? 0.0;
                          final address = (sup['address']?.toString().isNotEmpty ?? false) ? sup['address'].toString() : 'No address';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.05),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SupplierLedgerScreen(
                                      supplier: sup,
                                    ),
                                  ),
                                ).then((_) => _loadSuppliers());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    // Top Row
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFF3B82F6), // Blue background
                                          child: Text(_getInitials(sup['name']), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(sup['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                              const SizedBox(height: 2),
                                              Text(address, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: badgeGreen, borderRadius: BorderRadius.circular(6)),
                                          child: Text('Active', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextGreen)),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                    ),
                                    // Bottom Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Total Purchase', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                              const SizedBox(height: 4),
                                              Text('₹ ${fmt.format(totalPurchased)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Paid', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                              const SizedBox(height: 4),
                                              Text('₹ ${fmt.format(totalPaid)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Due', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                              const SizedBox(height: 4),
                                              Text('₹ ${fmt.format(due)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: due > 0 ? redDue : badgeTextGreen)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
