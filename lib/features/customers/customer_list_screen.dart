import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/customer.dart';
import '../../core/database/database_helper.dart';
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

  List<Customer> _dbCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await DatabaseHelper.instance.getCustomers();
    final customers = data.map<Customer>((json) {
      return Customer(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        notes: json['address'],
        outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
    
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer'),
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
                _summaryChip('${_dbCustomers.length} Total', AppColors.royalBlue),
                const SizedBox(width: 10),
                _summaryChip(
                    '${_dbCustomers.where((c) => c.outstandingBalance > 0).length} Due',
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
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                : _filtered.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async => _loadCustomers(),
                        color: AppColors.royalBlue,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(child: Text('No customers found', style: GoogleFonts.outfit(color: Colors.grey))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadCustomers(),
                        color: AppColors.royalBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _CustomerCard(
                            customer: _filtered[i], 
                            index: i,
                            onLongPress: () => _showCustomerOptionsBottomSheet(_filtered[i]),
                          ),
                        ),
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
      builder: (_) => _AddCustomerSheet(
        onSaved: () {
          _loadCustomers();
        },
      ),
    );
  }

  void _showCustomerOptionsBottomSheet(Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                customer.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                customer.phone ?? 'No Phone',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.royalBlue),
                title: const Text('Edit Customer', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCustomerDialog(customer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCustomer(customer);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final cleanPhone = (customer.phone ?? '').replaceAll(RegExp(r'^\+91\s*'), '').replaceAll(RegExp(r'\D'), '');
    final phoneCtrl = TextEditingController(text: cleanPhone);
    final notesCtrl = TextEditingController(text: customer.notes ?? '');
    final duesCtrl = TextEditingController(text: customer.outstandingBalance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number (10 digits)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+91 ',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Address / Notes', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Outstanding Dues (₹)', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final rawPhone = phoneCtrl.text.trim();
              if (rawPhone.isNotEmpty && rawPhone.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mobile number must be 10 digits (+91 followed by 10 digits)')),
                );
                return;
              }
              final phoneVal = rawPhone.isEmpty 
                  ? 'N/A_${DateTime.now().millisecondsSinceEpoch}' 
                  : (rawPhone.startsWith('+91') ? rawPhone : '+91 $rawPhone');

              await DatabaseHelper.instance.updateCustomer(customer.id!, {
                'name': nameCtrl.text.trim(),
                'phone': phoneVal,
                'address': notesCtrl.text.trim(),
                'outstanding_balance': double.tryParse(duesCtrl.text.trim()) ?? 0.0,
              });
              if (mounted) {
                Navigator.pop(ctx);
                _loadCustomers();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('Customer updated successfully!'), backgroundColor: AppColors.emeraldGreen),
                // );
              }
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Customer?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${customer.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DatabaseHelper.instance.deleteCustomer(customer.id!);
              if (mounted) {
                Navigator.pop(ctx);
                _loadCustomers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer "${customer.name}" deleted!'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final int index;
  final VoidCallback? onLongPress;
  const _CustomerCard({required this.customer, required this.index, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final hasDue = customer.outstandingBalance > 0;
    return GestureDetector(
      onLongPress: onLongPress,
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
                  _iconBtn(Icons.chat_bubble_rounded, const Color(0xFF25D366)),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.message_rounded, AppColors.royalBlue),
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

class _AddCustomerSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddCustomerSheet({required this.onSaved});

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveCustomer() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isNotEmpty && rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number must be 10 digits (+91 followed by 10 digits)')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final phoneVal = rawPhone.isEmpty 
          ? 'N/A_${DateTime.now().millisecondsSinceEpoch}' 
          : (rawPhone.startsWith('+91') ? rawPhone : '+91 $rawPhone');
      
      await DatabaseHelper.instance.addCustomer({
        'name': _nameCtrl.text.trim(),
        'phone': phoneVal,
        'address': _notesCtrl.text.trim(), 
        'outstanding_balance': 0.0,
        'total_spent': 0.0,
      });
      
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Customer added successfully!'), backgroundColor: AppColors.emeraldGreen),
        // );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add customer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
          _inputField('Full Name', Icons.person_outline_rounded, _nameCtrl),
          const SizedBox(height: 14),
          _inputField('Phone Number (10 digits)', Icons.phone_outlined, _phoneCtrl, type: TextInputType.phone, isPhone: true),
          const SizedBox(height: 14),
          _inputField('Notes (optional)', Icons.note_outlined, _notesCtrl),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveCustomer,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Customer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController controller, {TextInputType? type, bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textCapitalization: TextCapitalization.sentences,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ] : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.royalBlue),
        prefixText: isPhone ? '+91 ' : null,
        prefixStyle: isPhone ? const TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue) : null,
        counterText: '',
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
