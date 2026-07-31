import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/customer.dart';
import '../../core/theme/app_colors.dart';
import '../billing/billing_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final hasDue = customer.outstandingBalance > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(customer.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                    tag: 'customer_avatar_${customer.id}',
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                      child: Text(
                        customer.name[0].toUpperCase(),
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
                    tag: 'customer_name_${customer.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        customer.name,
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
                    customer.phone ?? 'No Phone Number',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call / Message Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _contactButton(Icons.call_rounded, 'Call', AppColors.emeraldGreen),
                      const SizedBox(width: 16),
                      _contactButton(Icons.message_rounded, 'Message', AppColors.royalBlue),
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
                          hasDue ? 'Outstanding Due: ₹${customer.outstandingBalance.toStringAsFixed(0)}' : 'Clear (No Dues)',
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
                          builder: (_) => BillingScreen(customer: customer),
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
                  _buildMockInvoiceCard('INV-2025-001', '₹ 10,500', 'Today, 02:30 PM', true),
                  const SizedBox(height: 12),
                  _buildMockInvoiceCard('INV-2025-014', '₹ 3,800', '25 Jul 2025', true),
                  const SizedBox(height: 12),
                  _buildMockInvoiceCard('INV-2025-042', '₹ 4,500', '18 Jun 2025', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMockInvoiceCard(String id, String amount, String date, bool paid) {
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
        ],
      ),
    );
  }
}
