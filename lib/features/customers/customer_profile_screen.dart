import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/customer.dart';
import '../../core/theme/app_colors.dart';
import '../billing/billing_screen.dart';
import '../../core/database/database_helper.dart';
import '../billing/templates/invoice_template_classic_gst.dart';
import '../billing/templates/invoice_template_premium_gold.dart';
import '../billing/templates/invoice_template_modern_emerald.dart';
import '../billing/templates/invoice_template_royal_violet.dart';
import '../billing/templates/invoice_template_minimal_slate.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  List<Map<String, dynamic>> _customerBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerBills();
  }

  Future<void> _loadCustomerBills() async {
    try {
      final bills = await DatabaseHelper.instance.getCustomerBills(
        widget.customer.id ?? 0, 
        customerName: widget.customer.name, 
        customerPhone: widget.customer.phone,
      );
      setState(() {
        _customerBills = bills;
        _isLoading = false;
      });
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
            
            final tmpl = snapshot.data!.getString('invoice_template') ?? 'Royal Blue';
            
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
                      Text('Color Invoice (रंगीन बिल)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
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
                          final image = await screenshotController.capture(pixelRatio: 2.0);
                          if (image == null) return;
                          
                          final directory = await getTemporaryDirectory();
                          final imagePath = await File('${directory.path}/invoice_${billData['bill_number']}.png').create();
                          await imagePath.writeAsBytes(image);
                          
                          final dueAmt = (billData['due_amount'] as num?)?.toDouble() ?? 0.0;
                          final statusMsg = dueAmt > 0 
                              ? 'Your remaining balance is ₹${dueAmt.toStringAsFixed(0)}.' 
                              : 'Payment Status: PAID ✅';
                          
                          await Share.shareXFiles(
                            [XFile(imagePath.path)], 
                            text: 'नमस्कार ${billData['customer_name']},\n\nतुमचे रंगीन बिल (Color Invoice) सोबत जोडले आहे.\n$statusMsg\n\nधन्यवाद!'
                          );
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
                          'WhatsApp बिल निवडा',
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
                        'Done (पूर्ण)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ग्राहक: ${widget.customer.name} (${widget.customer.phone ?? ""})',
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
                      'WhatsApp वर पाठवा (Send Bill)',
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

  @override
  Widget build(BuildContext context) {
    final hasDue = widget.customer.outstandingBalance > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.customer.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'customer_avatar_${widget.customer.id}',
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                      child: Text(
                        widget.customer.name[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: AppColors.royalBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'customer_name_${widget.customer.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.customer.name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.customer.phone ?? 'No Phone Number',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp / Message Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showSelectBillWhatsAppSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                          foregroundColor: const Color(0xFF25D366),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                        label: Text('WhatsApp', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showSelectBillWhatsAppSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                          foregroundColor: AppColors.royalBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.message_rounded, size: 20),
                        label: Text('Message', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Balance Due Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasDue ? AppColors.softOrange.withValues(alpha: 0.1) : AppColors.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: hasDue ? AppColors.softOrange.withValues(alpha: 0.3) : AppColors.emeraldGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasDue ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          color: hasDue ? AppColors.softOrange : AppColors.emeraldGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasDue ? 'Outstanding Due: ₹${widget.customer.outstandingBalance.toStringAsFixed(0)}' : 'Clear (No Dues)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: hasDue ? AppColors.softOrange : AppColors.emeraldGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🌟 PRIMARY ACTION: CREATE NEW BILL (ONLY ACCESSIBLE HERE)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillingScreen(customer: widget.customer),
                        ),
                      );
                      _loadCustomerBills();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.royalBlue, Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            '+ CREATE NEW BILL',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Billing History Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing & Invoice History',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _customerBills.isEmpty
                          ? const Text('No bills found for this customer yet.')
                          : Column(
<<<<<<< HEAD
                              children: _customerBills.map((b) {
                                final dueAmt = (b['due_amount'] as num?)?.toDouble() ?? 0.0;
                                final isPaid = dueAmt <= 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMockInvoiceCard(
                                    b['bill_number'] ?? '', 
                                    '₹ ${b['grand_total']}', 
                                    b['bill_date'] ?? '', 
                                    isPaid, 
                                    dueAmt,
                                    () {
                                      _openWhatsAppChat(b);
                                    },
                                    onLongPress: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => BillingScreen(billToEdit: b)),
                                      );
                                      _loadCustomerBills();
                                    },
                                  ),
                                );
                              }).toList(),
=======
                              children: _customerBills.map((b) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildMockInvoiceCard(
                                  b['bill_number'] ?? '', 
                                  '₹ ${b['grand_total']}', 
                                  b['bill_date'] ?? '', 
                                  true, // Assuming paid for now
                                  () {
                                    _openWhatsAppChat(b);
                                  },
                                  onLongPress: () {
                                    _showBillOptionsBottomSheet(b);
                                  },
                                ),
                              )).toList(),
>>>>>>> f9f7ac957573f0687f6e1d8855c034856ebba6c0
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildMockInvoiceCard(String id, String amount, String date, bool paid, double dueAmount, VoidCallback onShare, {VoidCallback? onLongPress}) {
    final statusColor = paid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Status Circle Indicator: RED for Pending, GREEN for Paid
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 1.8),
                  ),
                  child: Icon(
                    paid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paid ? 'Paid ✅' : 'Due: ₹${dueAmount.toStringAsFixed(0)} 🔴',
                        style: GoogleFonts.outfit(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                  onPressed: onShare,
                  tooltip: 'WhatsApp वर पाठवा',
                ),
              ],
            ),
          ],
        ),
      ),
=======
  Widget _buildMockInvoiceCard(String id, String amount, String date, bool paid, VoidCallback onShare, {VoidCallback? onLongPress}) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_rounded, color: AppColors.royalBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: paid ? AppColors.emeraldGreen.withValues(alpha: 0.1) : AppColors.softOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      paid ? 'Paid' : 'Pending',
                      style: GoogleFonts.outfit(
                        color: paid ? AppColors.emeraldGreen : AppColors.softOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
                onPressed: onShare,
                tooltip: 'WhatsApp वर पाठवा',
              ),
            ],
          ),
        ],
      ),
    ),
>>>>>>> f9f7ac957573f0687f6e1d8855c034856ebba6c0
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
              Text(
                'Amount: ₹${bill['grand_total']}',
                style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                title: const Text('View & Share Color Bill (रंगीन बिल पहा/पाठवा)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showColorInvoicePreview(bill);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.royalBlue),
                title: const Text('Edit Bill (बिल एडिट करा)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BillingScreen(billToEdit: bill)),
                  );
                  _loadCustomerBills();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text('Delete Bill (बिल डिलीट करा)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
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
}
