import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateElegantEmerald extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateElegantEmerald({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const primaryColor = Color(0xFF047857); // Emerald Green
    const textDark = Color(0xFF064E3B);
    const textGray = Color(0xFF4B5563);
    const bgAccent = Color(0xFFECFDF5);

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.eco_rounded, color: primaryColor, size: 32),
                const SizedBox(height: 8),
                Text(shopName, style: GoogleFonts.playfairDisplay(color: textDark, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(shopAddress, style: GoogleFonts.lato(color: textGray, fontSize: 10)),
                if (shopPhone.isNotEmpty) Text('Ph: $shopPhone', style: GoogleFonts.lato(color: textGray, fontSize: 10)),
                if (shopGstin.isNotEmpty) Text('GSTIN: $shopGstin', style: GoogleFonts.lato(color: textGray, fontSize: 10)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: primaryColor, width: 1),
                bottom: BorderSide(color: primaryColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('INVOICE', style: GoogleFonts.playfairDisplay(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMetaRow('No:', billData['bill_number'].toString(), textGray, textDark),
                    _buildMetaRow('Date:', formattedDate, textGray, textDark),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILL TO', style: GoogleFonts.lato(color: textGray, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(customerName, style: GoogleFonts.lato(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (customerMobile.isNotEmpty)
                      Text(customerMobile, style: GoogleFonts.lato(color: textGray, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: bgAccent,
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.lato(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.lato(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.lato(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.lato(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold))),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(name, style: GoogleFonts.lato(fontSize: 11, color: textDark))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 11, color: textGray))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.lato(fontSize: 11, color: textGray))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.lato(fontSize: 11, color: textDark, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT', style: GoogleFonts.lato(color: textGray, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Mode: $paymentMethod', style: GoogleFonts.lato(color: textGray, fontSize: 10)),
                    if (dueAmount > 0)
                      Text('Status: DUE', style: GoogleFonts.lato(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))
                    else
                      Text('Status: PAID', style: GoogleFonts.lato(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal, textGray, textDark, fmt),
                    if (discount > 0) _buildSummaryRow('Discount', -discount, textGray, primaryColor, fmt),
                    _buildSummaryRow('Taxable Amount', taxableAmount, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(cgstLabel, cgst, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(sgstLabel, sgst, textGray, textDark, fmt),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: primaryColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GRAND TOTAL', style: GoogleFonts.lato(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.lato(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 20),
          Center(
            child: Text('Thank you for your business!', style: GoogleFonts.playfairDisplay(color: textGray, fontSize: 12, fontStyle: FontStyle.italic)),
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
          Text('$label ', style: GoogleFonts.lato(color: labelCol, fontSize: 11)),
          Text(value, style: GoogleFonts.lato(color: valCol, fontSize: 11, fontWeight: FontWeight.bold)),
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
          Text(label, style: GoogleFonts.lato(color: labelCol, fontSize: 10)),
          Text(amount < 0 ? '-₹${fmt.format(amount.abs())}' : '₹${fmt.format(amount)}', style: GoogleFonts.lato(color: valCol, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
