import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';

class ContactSelectionSheet extends StatefulWidget {
  final bool isSupplier;
  final VoidCallback? onAdded;

  const ContactSelectionSheet({super.key, this.isSupplier = false, this.onAdded});

  static void show(BuildContext context, {bool isSupplier = false, VoidCallback? onAdded}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactSelectionSheet(isSupplier: isSupplier, onAdded: onAdded),
    );
  }

  @override
  State<ContactSelectionSheet> createState() => _ContactSelectionSheetState();
}

class _ContactSelectionSheetState extends State<ContactSelectionSheet> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final Set<String> _selectedContactIds = {};
  
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isSaving = false;
  
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _avatarColors = [
    const Color(0xFFF87171), // Red
    const Color(0xFF34D399), // Emerald
    const Color(0xFF60A5FA), // Blue
    const Color(0xFFFBBF24), // Amber
    const Color(0xFF818CF8), // Indigo
    const Color(0xFFF472B6), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    final cleanQuery = query.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final nameMatches = contact.displayName.toLowerCase().contains(query);
        
        bool phoneMatches = false;
        if (cleanQuery.isNotEmpty) {
          phoneMatches = contact.phones.any((phone) {
            final cleanPhone = phone.number.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
            return cleanPhone.contains(cleanQuery);
          });
        }
        
        return nameMatches || phoneMatches;
      }).toList();
    });
  }

  Future<void> _addSelectedContacts() async {
    if (_selectedContactIds.isEmpty) return;
    
    setState(() => _isSaving = true);
    int addedCount = 0;

    for (final contactId in _selectedContactIds) {
      try {
        final contact = _contacts.firstWhere((c) => c.id == contactId);
        final name = contact.displayName;
        String phone = '';
        if (contact.phones.isNotEmpty) {
          phone = contact.phones.first.number;
        }
        if (phone.isEmpty) {
          phone = 'N/A_${DateTime.now().millisecondsSinceEpoch}_$addedCount';
        }

        if (widget.isSupplier) {
          await DatabaseHelper.instance.addSupplier({
            'name': name,
            'phone': phone,
            'email': '',
            'address': '',
            'gst_number': '',
            'outstanding_due': 0.0,
            'total_purchased': 0.0,
            'total_paid': 0.0,
          });
        } else {
          await DatabaseHelper.instance.addCustomer({
            'name': name,
            'phone': phone,
            'email': '',
            'address': '',
            'category': 'Regular',
            'outstanding_balance': 0.0,
          });
        }
        addedCount++;
      } catch (e) {
        // Skip errors for individual duplicates
      }
    }

    if (mounted) {
      widget.onAdded?.call();
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount ${widget.isSupplier ? 'Suppliers' : 'Customers'} added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Select Contact',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                    : _permissionDenied
                        ? Center(
                            child: Text(
                              'Contacts permission denied.\nPlease enable it in settings.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                            ),
                          )
                        : _filteredContacts.isEmpty
                            ? Center(
                                child: Text(
                                  'No contacts found',
                                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100), // padding for FAB
                                itemCount: _filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = _filteredContacts[index];
                                  final phone = contact.phones.isNotEmpty
                                      ? contact.phones.first.number
                                      : 'No Phone Number';
                                  final isSelected = _selectedContactIds.contains(contact.id);
                                  
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedContactIds.remove(contact.id);
                                        } else {
                                          _selectedContactIds.add(contact.id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      color: isSelected ? AppColors.royalBlue.withOpacity(0.05) : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: _getAvatarColor(contact.displayName).withOpacity(0.9),
                                            child: Text(
                                              _getInitials(contact.displayName),
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.displayName,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: AppColors.textPrimaryDark,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  phone,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[400],
                                            size: 26,
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
          
          if (_selectedContactIds.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: _isSaving ? null : _addSelectedContacts,
                backgroundColor: const Color(0xFF1E293B), // Dark slate blue from design
                elevation: 4,
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Add ${_selectedContactIds.length} ${widget.isSupplier ? 'Suppliers' : 'Customers'}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
