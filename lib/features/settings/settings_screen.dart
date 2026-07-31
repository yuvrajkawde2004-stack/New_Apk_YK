import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'shop_profile_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinLock = false;
  bool _fingerprint = false;
  bool _notifications = true;
  String _selectedTemplate = 'Premium Gold';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTemplate = prefs.getString('invoice_template') ?? 'Premium Gold';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          loc.translate('settings'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. PREMIUM SHOP HEADER CARD
              GestureDetector(
                onTap: () => _openShopProfile(context),
                child: _buildLuxuryShopCard().animate().fadeIn().slideY(begin: -0.1, end: 0),
              ),
              const SizedBox(height: 24),

              // 🖨️ 2. PREMIUM INVOICE STUDIO
              _sectionTitle('PREMIUM INVOICE STUDIO'),
              const SizedBox(height: 12),
              _buildCard([
                _settingTile(
                  icon: Icons.brush_rounded,
                  color: const Color(0xFFD4AF37), // Classic Gold
                  title: 'Premium Invoice Studio',
                  subtitle: 'Current Theme: $_selectedTemplate',
                  onTap: () => _showPremiumInvoiceStudioSheet(context),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.print_rounded,
                  color: const Color(0xFF0EA5E9),
                  title: 'Thermal Printer Setup',
                  subtitle: 'Bluetooth / Wi-Fi Desktop Printer',
                  onTap: () => _showPrinterConnectionDialog(context),
                ),
              ], 100),

              const SizedBox(height: 24),

              // 🔐 3. SECURITY
              _sectionTitle(loc.translate('security')),
              const SizedBox(height: 12),
              _buildCard([
                _settingTile(
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.purpleAccent,
                  title: loc.translate('currency'),
                  subtitle: 'Indian Rupee (₹)',
                  onTap: () {},
                ),
                _divider(),
                _settingTile(
                  icon: Icons.security_rounded,
                  color: AppColors.royalBlue,
                  title: 'App Security Lock',
                  subtitle: _pinLock || _fingerprint ? 'Security Enabled' : 'Security Disabled',
                  onTap: () => _showAppLockDialog(context),
                ),
              ], 200),

              const SizedBox(height: 24),

              // ⚙️ 4. PREFERENCES & LANGUAGE
              _sectionTitle(loc.translate('preferences')),
              const SizedBox(height: 12),
              _buildCard([
                _settingTile(
                  icon: Icons.language_rounded,
                  color: AppColors.purpleAccent,
                  title: loc.translate('language'),
                  subtitle: _getLanguageName(localeProvider.locale.languageCode),
                  onTap: () => _showLanguageSelector(context, localeProvider),
                ),

                _divider(),
                _switchTile(
                  icon: Icons.notifications_rounded,
                  color: AppColors.softOrange,
                  title: loc.translate('notifications'),
                  subtitle: 'Low stock & payment alerts',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ], 300),

              const SizedBox(height: 24),

              // ℹ️ 5. ABOUT & SIGN OUT
              Container(
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
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryLight),
                      ),
                      title: Text(loc.translate('about_app'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text('RetailFlow POS • Version 2.5.0 Pro', style: GoogleFonts.outfit(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                    _divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.red),
                      ),
                      title: Text(loc.translate('sign_out'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, end: 0, delay: 400.ms).fadeIn(),

              const SizedBox(height: 80),
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
              title: Text('System PDF Printer (A4)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('Ready for A4 Invoice Print & Download', style: GoogleFonts.outfit(fontSize: 11)),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'mr': return 'मराठी';
      case 'hi': return 'हिंदी';
      case 'en': 
      default: return 'English';
    }
  }

  void _showLanguageSelector(BuildContext context, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).translate('language'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: Text('English', style: GoogleFonts.outfit()),
                trailing: localeProvider.locale.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.emeraldGreen) : null,
                onTap: () { localeProvider.setLocale(const Locale('en')); Navigator.pop(context); },
              ),
              ListTile(
                title: Text('मराठी (Marathi)', style: GoogleFonts.outfit()),
                trailing: localeProvider.locale.languageCode == 'mr' ? const Icon(Icons.check, color: AppColors.emeraldGreen) : null,
                onTap: () { localeProvider.setLocale(const Locale('mr')); Navigator.pop(context); },
              ),
              ListTile(
                title: Text('हिंदी (Hindi)', style: GoogleFonts.outfit()),
                trailing: localeProvider.locale.languageCode == 'hi' ? const Icon(Icons.check, color: AppColors.emeraldGreen) : null,
                onTap: () { localeProvider.setLocale(const Locale('hi')); Navigator.pop(context); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppLockDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: AppColors.royalBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'App Security Lock',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Protect your app using PIN or Fingerprint',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                
                // PIN Lock Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile.adaptive(
                    title: Text(
                      loc.translate('pin_lock'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Secure app with 4-digit PIN',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    value: _pinLock,
                    activeColor: AppColors.royalBlue,
                    onChanged: (val) {
                      setState(() {
                        _pinLock = val;
                      });
                      setModalState(() {});
                    },
                  ),
                ),
                
                const SizedBox(height: 12),

                // Fingerprint Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile.adaptive(
                    title: Text(
                      loc.translate('fingerprint'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _fingerprint ? loc.translate('fingerprint_enabled') : loc.translate('fingerprint_disabled'),
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    value: _fingerprint,
                    activeColor: AppColors.emeraldGreen,
                    onChanged: (val) {
                      setState(() {
                        _fingerprint = val;
                      });
                      setModalState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.royalBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      loc.translate('close'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
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

  Widget _buildLuxuryShopCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1035), Color(0xFF3B0764)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1035).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RetailFlow',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('GSTIN: 27AAAAA0000A1Z5',
                        style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('User ID: usr_a1b2c3d4e5',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Text('PREMIUM POS VERSION 2.5',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.edit_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 0.5));
  }

  Widget _buildCard(List<Widget> children, int delay) {
    return Container(
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
      child: Column(children: children),
    ).animate().slideY(begin: 0.1, end: 0, delay: delay.ms).fadeIn();
  }

  Widget _divider() => Divider(
        height: 1,
        indent: 56,
        color: AppColors.textSecondaryLight.withValues(alpha: 0.15),
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
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

// ───────────────────── PREMIUM INVOICE STUDIO SHEET ─────────────────────
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
    'Premium Gold',
    'Minimal Light',
    'Royal Blue',
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
          const SizedBox(height: 24),
          
          ..._templates.map((tmpl) {
            final sel = _selected == tmpl;
            return GestureDetector(
              onTap: () => setState(() => _selected = tmpl),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.royalBlue.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? AppColors.royalBlue : Colors.grey.shade200, width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? AppColors.royalBlue : Colors.grey.shade400, width: sel ? 6 : 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(tmpl, style: GoogleFonts.outfit(fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 20),

          // Save & Apply Button
          ElevatedButton(
            onPressed: () {
              widget.onApply(_selected);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Applied Theme: $_selected', style: GoogleFonts.outfit()),
                  backgroundColor: AppColors.royalBlue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              'Save & Apply Theme',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
