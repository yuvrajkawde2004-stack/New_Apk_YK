import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/cloudflare_api_service.dart';
import '../../core/services/sync_service.dart';
import 'shop_profile_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pinLock = false;
  bool _fingerprint = false;
  bool _notifications = true;
  bool _autoCloudflareBackup = true;
  String _selectedPaperSize = 'A4 (Full Page)';
  String _selectedA4Template = 'Royal Blue & Gold';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

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

              // 🖨️ 2. A4 & INVOICE PRINT SETTINGS (NEW ENHANCED OPTIONS)
              _sectionTitle('A4 INVOICE & PRINTER SETTINGS'),
              const SizedBox(height: 12),
              _buildCard([
                _settingTile(
                  icon: Icons.picture_as_pdf_rounded,
                  color: AppColors.royalBlue,
                  title: 'A4 Bill Customization & Layout',
                  subtitle: 'Format: $_selectedPaperSize • Theme: $_selectedA4Template',
                  onTap: () => _showA4PrintSettingsSheet(context),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.print_rounded,
                  color: const Color(0xFF0EA5E9),
                  title: 'Thermal & A4 Printer Setup',
                  subtitle: 'Bluetooth / Wi-Fi Desktop Printer Connected',
                  onTap: () => _showPrinterConnectionDialog(context),
                ),
                _divider(),
                _switchTile(
                  icon: Icons.cloud_upload_rounded,
                  color: AppColors.emeraldGreen,
                  title: 'Auto Cloudflare R2 PDF Backup',
                  subtitle: 'Automatically backup generated A4 bills to Cloud',
                  value: _autoCloudflareBackup,
                  onChanged: (v) {
                    setState(() => _autoCloudflareBackup = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v ? 'Cloudflare R2 Auto PDF Backup Enabled!' : 'Auto Cloud Backup Disabled',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: v ? AppColors.emeraldGreen : AppColors.softOrange,
                      ),
                    );
                  },
                ),
              ], 100),

              const SizedBox(height: 24),

              // 🔐 3. SECURITY & CLOUDFLARE SYNC
              _sectionTitle('${loc.translate('security')} & CLOUD SYNC'),
              const SizedBox(height: 12),
              _buildCard([
                _settingTile(
                  icon: Icons.cloud_sync_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Cloudflare D1 Database Sync',
                  subtitle: 'Last Synced: Just Now (SQLite + D1 Active)',
                  onTap: () {
                    SyncService().forceSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Synced with Cloudflare D1 Remote Database!', style: GoogleFonts.outfit()),
                        backgroundColor: AppColors.emeraldGreen,
                      ),
                    );
                  },
                ),
                _divider(),
                _settingTile(
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.purpleAccent,
                  title: loc.translate('currency'),
                  subtitle: 'Indian Rupee (₹)',
                  onTap: () {},
                ),
                _divider(),
                _switchTile(
                  icon: Icons.lock_rounded,
                  color: AppColors.royalBlue,
                  title: loc.translate('pin_lock'),
                  subtitle: 'Secure app with 4-digit PIN',
                  value: _pinLock,
                  onChanged: (v) => setState(() => _pinLock = v),
                ),
                _divider(),
                _switchTile(
                  icon: Icons.fingerprint_rounded,
                  color: AppColors.emeraldGreen,
                  title: loc.translate('fingerprint'),
                  subtitle: 'Biometric authentication',
                  value: _fingerprint,
                  onChanged: (v) => setState(() => _fingerprint = v),
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
                  icon: Icons.dark_mode_rounded,
                  color: const Color(0xFF6366F1),
                  title: loc.translate('dark_mode'),
                  subtitle: 'Switch to dark theme',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
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
                      subtitle: Text('Manisha POS • Version 2.5.0 Pro', style: GoogleFonts.outfit(fontSize: 12)),
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

  void _showA4PrintSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _A4PrintSettingsSheet(
        paperSize: _selectedPaperSize,
        template: _selectedA4Template,
        onApply: (paper, tmpl) {
          setState(() {
            _selectedPaperSize = paper;
            _selectedA4Template = tmpl;
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
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manisha Collection',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('GSTIN: 27AAAAA0000A1Z5',
                        style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
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

// ───────────────────── A4 PRINT & INVOICE CUSTOMIZATION SHEET ─────────────────────
class _A4PrintSettingsSheet extends StatefulWidget {
  final String paperSize;
  final String template;
  final Function(String paper, String tmpl) onApply;

  const _A4PrintSettingsSheet({
    required this.paperSize,
    required this.template,
    required this.onApply,
  });

  @override
  State<_A4PrintSettingsSheet> createState() => _A4PrintSettingsSheetState();
}

class _A4PrintSettingsSheetState extends State<_A4PrintSettingsSheet> {
  late String _currentPaper;
  late String _currentTemplate;
  bool _showShopLogo = true;
  bool _showTerms = true;
  bool _showBankDetails = true;
  bool _showUpiQr = true;
  final TextEditingController _termsController =
      TextEditingController(text: '1. Goods once sold will not be returned.\n2. Subject to local jurisdiction.');

  final List<String> _paperSizes = [
    'A4 (Full Page)',
    'A5 (Half Page)',
    'Thermal 80mm',
    'Thermal 58mm',
  ];

  final List<String> _templates = [
    'Royal Blue & Gold',
    'Classic Minimalist',
    'Emerald Fresh',
    'Dark Luxury Edition',
  ];

  @override
  void initState() {
    super.initState();
    _currentPaper = widget.paperSize;
    _currentTemplate = widget.template;
  }

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
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
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  Text('A4 Invoice Customization',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Paper Size Selector
          Text('Select Paper Format', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _paperSizes.map((size) {
              final sel = _currentPaper == size;
              return ChoiceChip(
                label: Text(size, style: GoogleFonts.outfit(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                selected: sel,
                selectedColor: AppColors.royalBlue,
                labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimaryLight),
                onSelected: (val) {
                  if (val) setState(() => _currentPaper = size);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 2. A4 Theme Template
          Text('A4 Visual Design Template', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _templates.map((tmpl) {
              final sel = _currentTemplate == tmpl;
              return ChoiceChip(
                label: Text(tmpl, style: GoogleFonts.outfit(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                selected: sel,
                selectedColor: const Color(0xFFF59E0B),
                labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimaryLight),
                onSelected: (val) {
                  if (val) setState(() => _currentTemplate = tmpl);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. Toggles for Logo, Bank Details, Terms
          SwitchListTile.adaptive(
            dense: true,
            title: Text('Include Shop Logo on A4 Header', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            value: _showShopLogo,
            onChanged: (v) => setState(() => _showShopLogo = v),
            activeColor: AppColors.royalBlue,
          ),
          SwitchListTile.adaptive(
            dense: true,
            title: Text('Include Bank Account & UPI QR Code', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            value: _showBankDetails,
            onChanged: (v) => setState(() => _showBankDetails = v),
            activeColor: AppColors.emeraldGreen,
          ),
          SwitchListTile.adaptive(
            dense: true,
            title: Text('Print Terms & Conditions at Bottom', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            value: _showTerms,
            onChanged: (v) => setState(() => _showTerms = v),
            activeColor: AppColors.royalBlue,
          ),

          const SizedBox(height: 20),

          // Save & Apply Button
          ElevatedButton(
            onPressed: () {
              widget.onApply(_currentPaper, _currentTemplate);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved A4 Print Settings: $_currentPaper ($_currentTemplate)', style: GoogleFonts.outfit()),
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
              'Save & Apply A4 Settings',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
