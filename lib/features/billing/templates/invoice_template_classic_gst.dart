import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateClassicGst extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateClassicGst({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
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
        formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(date);
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
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Shop Title
          Center(
            child: Column(
              children: [
                Text(
                  (billData['shop_name'] ?? 'RETAILFLOW CLOTH SHOP').toString().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  billData['shop_address'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700),
                ),
                Text(
                  'GSTIN: ${billData['shop_gstin'] ?? '27AADCB2230M1Z2'} | Ph: ${billData['shop_phone'] ?? '99422 20307'}',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1.2, color: Colors.black54),
          const SizedBox(height: 8),

          // Bill Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill No: #${billData['bill_number']}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('Date: $formattedDate', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  'TAX INVOICE',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('Customer: $customerName ${customerMobile.isNotEmpty ? "($customerMobile)" : ""}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),

          const SizedBox(height: 12),

          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('ITEM', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('RATE', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold))),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12))),
                  Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 12)))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(thickness: 1.2, color: Colors.black54),
          const SizedBox(height: 6),

          // Total Summary Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Mode: $paymentMethod', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade800)),
                  if (dueAmount > 0)
                    Text('Due: ₹${fmt.format(dueAmount)}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold))
                  else
                    Text('Status: PAID ✅', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal: ₹${fmt.format(subtotal)}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  Text('GRAND TOTAL: ₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Center(
            child: Text(
              'Thank you! Visit again 🙏',
              style: GoogleFonts.outfit(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
