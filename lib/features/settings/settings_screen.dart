import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../dashboard/providers/dashboard_provider.dart';
import 'shop_profile_modal.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/cloudflare_api_service.dart';
import 'upi_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinLock = false;
  bool _notifications = true;
  String _selectedTemplate = 'Executive Black & Gold';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTemplate = prefs.getString('invoice_template') ?? 'Executive Black & Gold';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'App Settings & Preferences',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. PREMIUM SHOP PROFILE HEADER
              GestureDetector(
                onTap: () => _openShopProfile(context),
                child: Consumer<DashboardProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            ),
                            child: const Icon(Icons.store_rounded, color: Color(0xFFF59E0B), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.shopName,
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GSTIN: 27AAAAA0000A1Z5 • Ph: 99422 20307',
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'PRO POS EDITION 2.5',
                                    style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.05);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 🎨 2. DIGITAL INVOICE DESIGN STUDIO
              _sectionTitle('DIGITAL INVOICE STUDIO'),
              const SizedBox(height: 10),
              _buildCard([
                _settingTile(
                  icon: Icons.brush_rounded,
                  color: const Color(0xFFD4AF37),
                  title: 'Invoice Theme & Design',
                  subtitle: 'Current Selected: $_selectedTemplate',
                  onTap: () => _showPremiumInvoiceStudioSheet(context),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.print_rounded,
                  color: const Color(0xFF0EA5E9),
                  title: 'Printer Management',
                  subtitle: 'Thermal 80mm POS & PDF A4 Printer',
                  onTap: () => _showPrinterConnectionDialog(context),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.royalBlue,
                  title: 'Free UPI & Payments',
                  subtitle: 'Setup UPI ID for Dynamic QR Codes',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final upiId = prefs.getString('upi_id') ?? '';
                    if (upiId.isNotEmpty) {
                      if (!context.mounted) return;
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Edit UPI Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to edit your UPI details?', style: GoogleFonts.outfit()),
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
                      if (confirm != true) return;
                    }
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UPISettingsScreen()));
                    }
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // 🔒 3. SECURITY & SYSTEM DATA
              _sectionTitle('SECURITY & SYSTEM DATA'),
              const SizedBox(height: 10),
              _buildCard([
                _settingTile(
                  icon: Icons.restore_from_trash_rounded,
                  color: const Color(0xFFEA580C),
                  title: 'Re-add Deleted Suppliers',
                  subtitle: 'Restore soft-deleted suppliers list',
                  onTap: () => _showDeletedSuppliersDialog(context),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.security_rounded,
                  color: AppColors.royalBlue,
                  title: 'App Security & PIN Lock',
                  subtitle: _pinLock ? 'Security PIN Enabled' : 'PIN Lock Disabled',
                  onTap: () => _showAppLockDialog(context),
                ),
              ]),

              const SizedBox(height: 20),

              // ⚙️ 4. PREFERENCES & LANGUAGE
              _sectionTitle('PREFERENCES'),
              const SizedBox(height: 10),
              _buildCard([
                _settingTile(
                  icon: Icons.language_rounded,
                  color: const Color(0xFF7C3AED),
                  title: 'App Language',
                  subtitle: 'English (Default)',
                  onTap: () {},
                ),

              ]),

              const SizedBox(height: 20),

              // ℹ️ 5. ABOUT & SIGN OUT
              _buildCard([
                _settingTile(
                  icon: Icons.info_outline_rounded,
                  color: Colors.grey.shade700,
                  title: 'About RetailFlow POS',
                  subtitle: 'Version 2.5.0 Pro',
                  onTap: () {},
                ),
                _divider(),
                _settingTile(
                  icon: Icons.logout_rounded,
                  color: Colors.red,
                  title: 'Sign Out Account',
                  subtitle: 'Safely logout from this phone',
                  onTap: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: Text('Do you want to exit the app?', style: GoogleFonts.outfit()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade700)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text('OK', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirm) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_logged_in', false);
                      await DatabaseHelper.instance.closeAndReset();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _openShopProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShopProfileModal(),
    );
  }

  void _showPremiumInvoiceStudioSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumInvoiceStudioSheet(
        currentTemplate: _selectedTemplate,
        onApply: (tmpl) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('invoice_template', tmpl);
          setState(() {
            _selectedTemplate = tmpl;
          });
        },
      ),
    );
  }

  void _showPrinterConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.print_rounded, color: AppColors.royalBlue),
            const SizedBox(width: 10),
            Text('Printer Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected Printers:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.emeraldGreen),
              title: Text('System PDF Printer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('Ready for Instant Print', style: GoogleFonts.outfit(fontSize: 11)),
              trailing: const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.bluetooth_connected_rounded, color: AppColors.royalBlue),
              title: Text('Thermal 80mm Bluetooth', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('Paired (POS-80)', style: GoogleFonts.outfit(fontSize: 11)),
              trailing: const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAppLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('App Security Lock', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Protect your billing app with PIN or Fingerprint authentication.', style: GoogleFonts.outfit(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _pinLock = !_pinLock);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue),
            child: Text(_pinLock ? 'Disable Lock' : 'Enable Lock', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Wipe All Test Data?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(
          'This will clear all test sample products, purchase history, and bills from both Local Database & Cloudflare D1 so you can start adding your real stock products fresh.',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clearAllProductsAndDatabaseData();
              await CloudflareApiService.clearCloudflareDatabase();
              if (mounted) {
                Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Database reset successfully! You can now add your real products.', style: GoogleFonts.outfit()),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              }
            },
            child: const Text('Reset Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeletedSuppliersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getDeletedSuppliers(),
          builder: (ctx, snapshot) {
            final deleted = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text('Deleted Suppliers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Tap on "Re-Add / Restore" to bring supplier back to active list:', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 16),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                  else if (deleted.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('No deleted suppliers found.', style: GoogleFonts.outfit(color: Colors.grey))),
                    )
                  else
                    ...deleted.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(s['name'] != null && s['name'].toString().isNotEmpty ? s['name'][0].toUpperCase() : 'S',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Phone: ${s['phone'] ?? "N/A"}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final sId = s['id'] as int?;
                              if (sId != null) {
                                await DatabaseHelper.instance.restoreSupplier(sId);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Supplier "${s['name']}" successfully restored & re-added!'),
                                    backgroundColor: AppColors.emeraldGreen,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emeraldGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.restore_rounded, size: 16, color: Colors.white),
                            label: Text('Re-add', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        indent: 56,
        color: Colors.grey.shade100,
      );

  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM INVOICE STUDIO SHEET
// -----------------------------------------------------------------------------
class _PremiumInvoiceStudioSheet extends StatefulWidget {
  final String currentTemplate;
  final Function(String tmpl) onApply;

  const _PremiumInvoiceStudioSheet({
    required this.currentTemplate,
    required this.onApply,
  });

  @override
  State<_PremiumInvoiceStudioSheet> createState() => _PremiumInvoiceStudioSheetState();
}

class _PremiumInvoiceStudioSheetState extends State<_PremiumInvoiceStudioSheet> {
  late String _selected;

  final List<String> _templates = [
    'Executive Black & Gold',
    'Minimal Corporate',
    'Modern Indigo',
    'Elegant Emerald',
    'Luxury Dark',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentTemplate;
    if (!_templates.contains(_selected)) _selected = _templates.first;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.brush_rounded, color: Color(0xFFD4AF37)),
                  ),
                  const SizedBox(width: 12),
                  Text('Premium Invoice Studio',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Choose the visual design of your digital invoices.', 
            style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13)),
          const SizedBox(height: 20),
          
          ..._templates.map((tmpl) {
            final sel = _selected == tmpl;
            return GestureDetector(
              onTap: () => setState(() => _selected = tmpl),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.royalBlue.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? AppColors.royalBlue : Colors.grey.shade200,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: sel ? AppColors.royalBlue : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(tmpl, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Apply Selected Theme', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
