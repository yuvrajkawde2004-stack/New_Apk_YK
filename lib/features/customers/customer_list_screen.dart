import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/customer.dart';
import 'customer_profile_screen.dart';

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

  final List<Customer> _demoCustomers = const [
    Customer(id: 1, name: 'Priya Sharma', phone: '9876543210', outstandingBalance: 2500,
        notes: 'Prefers silk sarees'),
    Customer(id: 2, name: 'Rahul Mehta', phone: '9123456789', outstandingBalance: 0,
        notes: 'Regular customer'),
    Customer(id: 3, name: 'Sunita Devi', phone: '9345678901', outstandingBalance: 8750,
        notes: 'Wedding shopping'),
    Customer(id: 4, name: 'Anjali Gupta', phone: '9456789012', outstandingBalance: 0,
        notes: ''),
    Customer(id: 5, name: 'Meera Joshi', phone: '9567890123', outstandingBalance: 1200,
        notes: 'Bulk buyer'),
  ];

  List<Customer> get _filtered {
    if (_searchQuery.isEmpty) return _demoCustomers;
    return _demoCustomers.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (c.phone?.contains(_searchQuery) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('All Customers'),
        automaticallyImplyLeading: !widget.isEmbedded,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: widget.onAddCustomer ?? () => _showAddCustomerDialog(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.royalBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _summaryChip('${_demoCustomers.length} Total', AppColors.royalBlue),
                const SizedBox(width: 10),
                _summaryChip(
                    '${_demoCustomers.where((c) => c.outstandingBalance > 0).length} Due',
                    AppColors.softOrange),
              ],
            ).animate().fadeIn(),
          ),
          const SizedBox(height: 14),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),
          const SizedBox(height: 14),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _CustomerCard(customer: _filtered[i], index: i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final int index;
  const _CustomerCard({required this.customer, required this.index});

  @override
  Widget build(BuildContext context) {
    final hasDue = customer.outstandingBalance > 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerProfileScreen(customer: customer),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Hero(
              tag: 'customer_avatar_${customer.id}',
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.royalBlue, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'customer_name_${customer.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(customer.phone ?? '',
                    style: TextStyle(
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.8), fontSize: 13)),
                if (customer.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(customer.notes!,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Due: ₹${customer.outstandingBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.softOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Clear',
                      style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(Icons.call_rounded, AppColors.emeraldGreen),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.chat_rounded, AppColors.royalBlue),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    ).animate().slideX(delay: (index * 60).ms, begin: 0.1, end: 0).fadeIn();
  }

  Widget _iconBtn(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _AddCustomerSheet extends StatelessWidget {
  const _AddCustomerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Customer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _inputField('Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _inputField('Phone Number', Icons.phone_outlined, TextInputType.phone),
          const SizedBox(height: 14),
          _inputField('Notes (optional)', Icons.note_outlined),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save Customer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, [TextInputType? type]) {
    return TextField(
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.royalBlue),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
      ),
    );
  }
}
