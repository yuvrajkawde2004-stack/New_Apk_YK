import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateExecutiveBlack extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateExecutiveBlack({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const goldAccent = Color(0xFFD97706); // Rich Gold
    const goldLight = Color(0xFFFBBF24); 
    const bgDark = Color(0xFF0F172A); // Executive Black/Slate
    const textLight = Color(0xFFF8FAFC);
    const textGray = Color(0xFF94A3B8);

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
    
    // Calculate CGST and SGST from total GST (assuming equal split)
    final cgst = totalGst / 2;
    final sgst = totalGst / 2;
    final taxableAmount = subtotal - discount;

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldAccent.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: GoogleFonts.cinzel(color: goldLight, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(shopAddress, style: GoogleFonts.outfit(color: textGray, fontSize: 9)),
                    if (shopPhone.isNotEmpty) Text('Phone: $shopPhone', style: GoogleFonts.outfit(color: textGray, fontSize: 9)),
                    if (shopGstin.isNotEmpty) Text('GSTIN: $shopGstin', style: GoogleFonts.outfit(color: textGray, fontSize: 9)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('INVOICE', style: GoogleFonts.cinzel(color: goldLight, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    _buildMetaRow('Invoice No', billData['bill_number'].toString(), textGray, textLight),
                    _buildMetaRow('Invoice Date', formattedDate, textGray, textLight),
                    _buildMetaRow('Due Date', formattedDate, textGray, textLight),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(color: goldAccent.withOpacity(0.3), thickness: 1),
          const SizedBox(height: 10),
          
          // Bill To Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: goldAccent, size: 14),
                        const SizedBox(width: 4),
                        Text('BILL TO', style: GoogleFonts.outfit(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(customerName, style: GoogleFonts.outfit(color: textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (customerMobile.isNotEmpty)
                      Text('Phone: $customerMobile', style: GoogleFonts.outfit(color: textGray, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, color: goldAccent, size: 14),
                        const SizedBox(width: 4),
                        Text('PAYMENT DETAILS', style: GoogleFonts.outfit(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Mode: $paymentMethod', style: GoogleFonts.outfit(color: textLight, fontSize: 11)),
                    Text(dueAmount > 0 ? 'Status: DUE' : 'Status: PAID', style: GoogleFonts.outfit(color: dueAmount > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: goldAccent.withOpacity(0.15),
              border: Border(
                top: BorderSide(color: goldAccent.withOpacity(0.3)),
                bottom: BorderSide(color: goldAccent.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.outfit(color: goldLight, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: goldLight, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: goldLight, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: goldLight, fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Table Rows
          ...itemsData.map((item) {
            final name = item['name'] ?? item['product_name'] ?? 'Item';
            final qty = item['quantity'] ?? 1;
            final rate = (item['rate'] as num?)?.toDouble() ?? (item['selling_price'] as num?)?.toDouble() ?? 0.0;
            final total = (item['total'] as num?)?.toDouble() ?? (qty * rate);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(name, style: GoogleFonts.outfit(fontSize: 10, color: textLight))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, color: textLight))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, color: textLight))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, color: textLight))),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          Divider(color: goldAccent.withOpacity(0.3), thickness: 1),
          const SizedBox(height: 12),
          
          // Summary Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOTES', style: GoogleFonts.outfit(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Thank you for your business!', style: GoogleFonts.outfit(color: textGray, fontSize: 9, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    if (dueAmount > 0) ...[
                      Text('REMAINING DUE', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('₹${fmt.format(dueAmount)}', style: GoogleFonts.outfit(color: textLight, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryRow('SUBTOTAL', subtotal, textGray, textLight, fmt),
                    if (discount > 0) _buildSummaryRow('DISCOUNT', -discount, textGray, Colors.greenAccent, fmt),
                    _buildSummaryRow('TAXABLE AMOUNT', taxableAmount, textGray, textLight, fmt),
                    if (totalGst > 0) _buildSummaryRow(cgstLabel, cgst, textGray, textLight, fmt),
                    if (totalGst > 0) _buildSummaryRow(sgstLabel, sgst, textGray, textLight, fmt),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: goldAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GRAND TOTAL', style: GoogleFonts.outfit(color: goldLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(color: goldLight, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color labelCol, Color valCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  :  ', style: GoogleFonts.outfit(color: labelCol, fontSize: 9)),
          Text(value, style: GoogleFonts.outfit(color: valCol, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, Color labelCol, Color valCol, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: labelCol, fontSize: 9, fontWeight: FontWeight.w500)),
          Text(amount < 0 ? '-₹${fmt.format(amount.abs())}' : '₹${fmt.format(amount)}', style: GoogleFonts.outfit(color: valCol, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
