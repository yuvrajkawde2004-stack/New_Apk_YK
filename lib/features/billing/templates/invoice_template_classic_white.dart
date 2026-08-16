import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateClassicWhite extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateClassicWhite({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    const primaryColor = Colors.black;
    const textDark = Colors.black87;
    const textGray = Colors.black54;

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
        border: Border.all(color: Colors.black12, width: 2),
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
                    Text(shopName, style: GoogleFonts.roboto(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(shopAddress, style: GoogleFonts.roboto(color: textGray, fontSize: 10)),
                    if (shopPhone.isNotEmpty) Text('Ph: $shopPhone', style: GoogleFonts.roboto(color: textGray, fontSize: 10)),
                    if (shopGstin.isNotEmpty) Text('GSTIN: $shopGstin', style: GoogleFonts.roboto(color: textGray, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TAX INVOICE', style: GoogleFonts.roboto(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildMetaRow('No:', billData['bill_number'].toString(), textGray, textDark),
                    _buildMetaRow('Date:', formattedDate, textGray, textDark),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILLED TO', style: GoogleFonts.roboto(color: textGray, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(customerName, style: GoogleFonts.roboto(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (customerMobile.isNotEmpty)
                      Text(customerMobile, style: GoogleFonts.roboto(color: textGray, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT INFO', style: GoogleFonts.roboto(color: textGray, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Method: $paymentMethod', style: GoogleFonts.roboto(color: textDark, fontSize: 11)),
                    Text(dueAmount > 0 ? 'Status: DUE' : 'Status: PAID', style: GoogleFonts.roboto(color: dueAmount > 0 ? Colors.red : Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.roboto(fontSize: 9, fontWeight: FontWeight.bold, color: textGray))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.roboto(fontSize: 9, fontWeight: FontWeight.bold, color: textGray))),
                Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: GoogleFonts.roboto(fontSize: 9, fontWeight: FontWeight.bold, color: textGray))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.roboto(fontSize: 9, fontWeight: FontWeight.bold, color: textGray))),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          ...itemsData.map((item) {
            final name = item['name'] ?? item['product_name'] ?? 'Item';
            final qty = item['quantity'] ?? 1;
            final rate = (item['rate'] as num?)?.toDouble() ?? (item['selling_price'] as num?)?.toDouble() ?? 0.0;
            final total = (item['total'] as num?)?.toDouble() ?? (qty * rate);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(name, style: GoogleFonts.roboto(fontSize: 10, color: textDark))),
                  Expanded(flex: 1, child: Text('$qty', textAlign: TextAlign.center, style: GoogleFonts.roboto(fontSize: 10, color: textDark))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(rate)}', textAlign: TextAlign.right, style: GoogleFonts.roboto(fontSize: 10, color: textDark))),
                  Expanded(flex: 2, child: Text('₹${fmt.format(total)}', textAlign: TextAlign.right, style: GoogleFonts.roboto(fontSize: 10, color: textDark))),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TERMS & CONDITIONS', style: GoogleFonts.roboto(color: textGray, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('1. Payment is due within 15 days.', style: GoogleFonts.roboto(color: textGray, fontSize: 8)),
                    Text('2. Goods once sold will not be taken back.', style: GoogleFonts.roboto(color: textGray, fontSize: 8)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryRow('SUBTOTAL', subtotal, textGray, textDark, fmt),
                    if (discount > 0) _buildSummaryRow('DISCOUNT', -discount, textGray, Colors.green, fmt),
                    _buildSummaryRow('TAXABLE AMOUNT', taxableAmount, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(cgstLabel, cgst, textGray, textDark, fmt),
                    if (totalGst > 0) _buildSummaryRow(sgstLabel, sgst, textGray, textDark, fmt),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL', style: GoogleFonts.roboto(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.roboto(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (paidAmount > 0) _buildSummaryRow('PAID AMOUNT', paidAmount, textGray, Colors.green, fmt),
                    if (dueAmount > 0) _buildSummaryRow('PENDING DUE', dueAmount, textGray, Colors.red, fmt),
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
          Text(label, style: GoogleFonts.roboto(color: labelCol, fontSize: 10)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.roboto(color: valCol, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color labelCol, Color valCol, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.roboto(color: labelCol, fontSize: 9, fontWeight: FontWeight.w600)),
          Text('₹${fmt.format(amount)}', style: GoogleFonts.roboto(color: valCol, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
