import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateLuxuryDark extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateLuxuryDark({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const bgDark = Color(0xFF1C1917); // Dark Brown/Black
    const primaryColor = Color(0xFFD4AF37); // Luxury Gold
    const textLight = Color(0xFFFAFAF9);
    const textGray = Color(0xFFA8A29E);
    const panelBg = Color(0xFF292524);

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
      padding: const EdgeInsets.all(24),
      color: bgDark,
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
                    Row(
                      children: [
                        Icon(Icons.diamond_outlined, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(shopName, style: GoogleFonts.montserrat(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(shopAddress, style: GoogleFonts.montserrat(color: textGray, fontSize: 9)),
                    if (shopPhone.isNotEmpty) Text('Ph: $shopPhone', style: GoogleFonts.montserrat(color: textGray, fontSize: 9)),
                    if (shopGstin.isNotEmpty) Text('GSTIN: $shopGstin', style: GoogleFonts.montserrat(color: textGray, fontSize: 9)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('INVOICE', style: GoogleFonts.montserrat(color: textLight, fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 3)),
                    const SizedBox(height: 8),
                    _buildMetaRow('No:', billData['bill_number'].toString(), textGray, textLight),
                    _buildMetaRow('Date:', formattedDate, textGray, textLight),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILL TO', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(customerName, style: GoogleFonts.montserrat(color: textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (customerMobile.isNotEmpty)
                      Text(customerMobile, style: GoogleFonts.montserrat(color: textGray, fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PAYMENT', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(paymentMethod, style: GoogleFonts.montserrat(color: textLight, fontSize: 11)),
                    Text(dueAmount > 0 ? 'DUE' : 'PAID', style: GoogleFonts.montserrat(color: dueAmount > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: primaryColor.withOpacity(0.5)),
                bottom: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.montserrat(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold))),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(name, style: GoogleFonts.montserrat(fontSize: 10, color: textLight))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, color: textGray))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 10, color: textGray))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 10, color: textLight, fontWeight: FontWeight.w600))),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 12),
          Divider(color: primaryColor.withOpacity(0.3), thickness: 1),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THANK YOU', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('We appreciate your business.', style: GoogleFonts.montserrat(color: textGray, fontSize: 9, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryRow('SUBTOTAL', subtotal, textGray, textLight, fmt),
                    if (discount > 0) _buildSummaryRow('DISCOUNT', -discount, textGray, Colors.greenAccent, fmt),
                    _buildSummaryRow('TAXABLE AMT', taxableAmount, textGray, textLight, fmt),
                    if (totalGst > 0) _buildSummaryRow(cgstLabel, cgst, textGray, textLight, fmt),
                    if (totalGst > 0) _buildSummaryRow(sgstLabel, sgst, textGray, textLight, fmt),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GRAND TOTAL', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.montserrat(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: GoogleFonts.montserrat(color: labelCol, fontSize: 9)),
          Text(value, style: GoogleFonts.montserrat(color: valCol, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, Color labelCol, Color valCol, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(color: labelCol, fontSize: 9, fontWeight: FontWeight.w500)),
          Text(amount < 0 ? '-₹${fmt.format(amount.abs())}' : '₹${fmt.format(amount)}', style: GoogleFonts.montserrat(color: valCol, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
