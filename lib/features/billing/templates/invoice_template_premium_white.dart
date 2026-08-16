import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplatePremiumWhite extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplatePremiumWhite({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const primaryColor = Color(0xFF374151); // Dark Gray
    const accentColor = Color(0xFF6B7280); // Lighter Gray
    const textDark = Color(0xFF111827);
    const textGray = Color(0xFF6B7280);

    final customerName = billData['customer_name'] ?? 'Walk-in Customer';
    final customerMobile = billData['customer_mobile'] ?? '';
    final shopName = (billData['shop_name'] ?? 'RETAILFLOW').toString().toUpperCase();
    final shopAddress = billData['shop_address'] ?? '';
    final shopPhone = billData['shop_phone'] ?? '';
    final shopGstin = billData['shop_gstin'] ?? '';
    
    final subtotal = (billData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (billData['grand_total'] as num?)?.toDouble() ?? 0.0;
    final totalGst = (billData['gst'] as num?)?.toDouble() ?? 0.0;
    final discount = (billData['discount'] as num?)?.toDouble() ?? 0.0;
    
    final cgst = totalGst / 2;
    final sgst = totalGst / 2;
    final taxableAmount = subtotal - discount;

    final paidAmount = (billData['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final dueAmount = (billData['due_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = billData['payment_method'] ?? 'Cash';
    
    String cgstLabel = 'CGST';
    String sgstLabel = 'SGST';
    if (taxableAmount > 0 && totalGst > 0) {
      final gstPercent = (totalGst / taxableAmount) * 100;
      final halfPercent = (gstPercent / 2).toStringAsFixed(1).replaceAll('.0', '');
      cgstLabel = 'CGST @ $halfPercent%';
      sgstLabel = 'SGST @ $halfPercent%';
    }

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
      width: 400,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shopName, style: GoogleFonts.outfit(color: textDark, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(shopAddress, style: GoogleFonts.outfit(color: textGray, fontSize: 11)),
                    if (shopPhone.isNotEmpty) Text('Ph: $shopPhone', style: GoogleFonts.outfit(color: textGray, fontSize: 11)),
                    if (shopGstin.isNotEmpty) Text('GSTIN: $shopGstin', style: GoogleFonts.outfit(color: textGray, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('INVOICE', style: GoogleFonts.outfit(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    _buildMetaRow('No.', billData['bill_number'].toString(), textGray, textDark),
                    _buildMetaRow('Date', formattedDate, textGray, textDark),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade200, thickness: 1),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILLED TO', style: GoogleFonts.outfit(color: accentColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(customerName, style: GoogleFonts.outfit(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (customerMobile.isNotEmpty)
                      Text(customerMobile, style: GoogleFonts.outfit(color: textGray, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT INFO', style: GoogleFonts.outfit(color: accentColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text('Method: $paymentMethod', style: GoogleFonts.outfit(color: textDark, fontSize: 12)),
                    Text(dueAmount > 0 ? 'Status: DUE' : 'Status: PAID', style: GoogleFonts.outfit(color: dueAmount > 0 ? Colors.redAccent : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('ITEM', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: textGray, letterSpacing: 0.5))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: textGray, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: textGray, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: textGray, letterSpacing: 0.5))),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          ...itemsData.map((item) {
            final name = item['name'] ?? item['product_name'] ?? 'Item';
            final qty = item['quantity'] ?? 1;
            final rate = (item['rate'] as num?)?.toDouble() ?? (item['selling_price'] as num?)?.toDouble() ?? 0.0;
            final total = (item['total'] as num?)?.toDouble() ?? (qty * rate);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(name, style: GoogleFonts.outfit(fontSize: 11, color: textDark, fontWeight: FontWeight.w500))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: textDark))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: textDark))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: textDark, fontWeight: FontWeight.w600))),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, thickness: 1),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOTES', style: GoogleFonts.outfit(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text('1. Please pay within 15 days.', style: GoogleFonts.outfit(color: textGray, fontSize: 9)),
                    Text('2. All items are non-refundable.', style: GoogleFonts.outfit(color: textGray, fontSize: 9)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal, textGray, textDark, fmt),
                    if (discount > 0) _buildSummaryRow('Discount', -discount, textGray, Colors.green, fmt),
                    _buildSummaryRow('Taxable Amount', taxableAmount, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(cgstLabel, cgst, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(sgstLabel, sgst, textGray, textDark, fmt),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GRAND TOTAL', style: GoogleFonts.outfit(color: textDark, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (paidAmount > 0) _buildSummaryRow('PAID AMOUNT', paidAmount, textGray, Colors.green, fmt),
                    if (dueAmount > 0) _buildSummaryRow('PENDING DUE', dueAmount, textGray, Colors.redAccent, fmt),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Center(
            child: Text('Thank you for your business!', style: GoogleFonts.outfit(color: accentColor, fontSize: 11, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color labelCol, Color valCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.outfit(color: labelCol, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Text(value, style: GoogleFonts.outfit(color: valCol, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color labelCol, Color valCol, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: labelCol, fontSize: 10, fontWeight: FontWeight.w500)),
          Text('₹${fmt.format(amount)}', style: GoogleFonts.outfit(color: valCol, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
