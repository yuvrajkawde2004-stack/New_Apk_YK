import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/customer.dart';
import '../../core/theme/app_colors.dart';
import '../billing/billing_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final List<Map<String, dynamic>> _mockBills = [
    {'id': 'INV-2025-001', 'amount': '₹ 10,500', 'date': 'Today, 02:30 PM', 'paid': true},
    {'id': 'INV-2025-014', 'amount': '₹ 3,800', 'date': '25 Jul 2025', 'paid': true},
    {'id': 'INV-2025-042', 'amount': '₹ 4,500', 'date': '18 Jun 2025', 'paid': false},
  ];

  Future<void> _openWhatsAppChat(Map<String, dynamic> bill) async {
    final rawPhone = widget.customer.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '9876543210';
    final phone = rawPhone.length == 10 ? '91$rawPhone' : rawPhone;

    final message = '''
Hello ${widget.customer.name},

Here is your invoice summary from *RetailFlow*:

📄 *Bill No:* ${bill['id']}
📅 *Date:* ${bill['date']}
💰 *Total Amount:* ${bill['amount']}
💳 *Status:* ${bill['paid'] ? 'Paid ✅' : 'Pending ⏳'}

Thank you for shopping with us!
*RetailFlow - Smart Billing. Smarter Inventory.*
''';

    final encodedMsg = Uri.encodeComponent(message);
    final whatsappScheme = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMsg');
    final webScheme = Uri.parse('https://wa.me/$phone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(whatsappScheme)) {
        await launchUrl(whatsappScheme);
      } else {
        await launchUrl(webScheme, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(webScheme, mode: LaunchMode.externalApplication);
    }
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
                        _openWhatsAppChat(_mockBills[selectedIndex]);
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
                  itemCount: _mockBills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final bill = _mockBills[i];
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
                                    bill['id'],
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    bill['date'],
                                    style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  bill['amount'],
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
                      _openWhatsAppChat(_mockBills[selectedIndex]);
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillingScreen(customer: widget.customer),
                        ),
                      );
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
                  ..._mockBills.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMockInvoiceCard(b['id'], b['amount'], b['date'], b['paid'], () {
                      _openWhatsAppChat(b);
                    }),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockInvoiceCard(String id, String amount, String date, bool paid, VoidCallback onShare) {
    return Container(
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
    );
  }
}
