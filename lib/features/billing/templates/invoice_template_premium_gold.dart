import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplatePremiumGold extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplatePremiumGold({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const goldAccent = Color(0xFFB45309);
    const goldBg = Color(0xFFFEF3C7);
    const textColor = Color(0xFF1E293B);

    final customerName = billData['customer_name'] ?? 'Walk-in Customer';
    final customerMobile = billData['customer_mobile'] ?? '';
    final subtotal = (billData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (billData['grand_total'] as num?)?.toDouble() ?? 0.0;
    final dueAmount = (billData['due_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = billData['payment_method'] ?? 'Cash';

    String formattedDate = '';
    if (billData['bill_date'] != null) {
      try {
        final date = DateTime.parse(billData['bill_date']);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        formattedDate = billData['bill_date'].toString();
      }
    }

    return Container(
      width: 380,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldAccent.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (billData['shop_name'] ?? 'RETAILFLOW POS').toString().toUpperCase(),
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        billData['shop_address'] ?? '',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'INVOICE',
                    style: GoogleFonts.outfit(color: goldAccent, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bill Info Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: goldBg.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: $customerName', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                      if (customerMobile.isNotEmpty)
                        Text(customerMobile, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bill #${billData['bill_number']}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: goldAccent)),
                    Text(formattedDate, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF78350F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('ITEM', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('RATE', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Items List
          ...itemsData.map((item) {
            final name = item['name'] ?? item['product_name'] ?? 'Item';
            final qty = item['quantity'] ?? 1;
            final rate = (item['rate'] as num?)?.toDouble() ?? (item['selling_price'] as num?)?.toDouble() ?? 0.0;
            final total = (item['total'] as num?)?.toDouble() ?? (qty * rate);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: textColor))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: textColor))),
                  Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 12, color: textColor)))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 6),

          // Total Summary Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mode: $paymentMethod', style: GoogleFonts.outfit(fontSize: 11, color: textColor)),
                  if (dueAmount > 0)
                    Text('Due: ₹${fmt.format(dueAmount)}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold))
                  else
                    Text('Status: PAID ✅', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: goldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: goldAccent),
                ),
                child: Text(
                  'TOTAL: ₹${fmt.format(grandTotal)}',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: goldAccent),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Thank you for shopping with us!',
              style: GoogleFonts.outfit(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
