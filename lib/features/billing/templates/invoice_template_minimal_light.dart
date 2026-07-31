import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateMinimalLight extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateMinimalLight({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    final primaryColor = const Color(0xFF1E293B); // Slate 800
    final secondaryColor = const Color(0xFF64748B); // Slate 500
    
    final customerName = billData['customer_name'] ?? 'Walk-in Customer';
    final customerMobile = billData['customer_mobile'] ?? '';
    final subtotal = (billData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final discount = (billData['discount'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (billData['grand_total'] as num?)?.toDouble() ?? 0.0;
    
    String formattedDate = '';
    if (billData['bill_date'] != null) {
      try {
         final date = DateTime.parse(billData['bill_date']);
         formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
         formattedDate = billData['bill_date'].toString().substring(0, 10);
      }
    }

    return Container(
      width: 600,
      height: 848,
      padding: const EdgeInsets.all(48),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RETAILFLOW',
                    style: GoogleFonts.outfit(
                      color: primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Clothing & Apparel',
                    style: GoogleFonts.outfit(
                      color: secondaryColor,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'INVOICE',
                  style: GoogleFonts.outfit(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Billed To', style: GoogleFonts.outfit(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(customerName, style: GoogleFonts.outfit(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (customerMobile.isNotEmpty)
                    Text('+91 $customerMobile', style: GoogleFonts.outfit(color: secondaryColor, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Invoice Details', style: GoogleFonts.outfit(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('No: ${billData['bill_number'] ?? 'N/A'}', style: GoogleFonts.outfit(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Date: $formattedDate', style: GoogleFonts.outfit(color: secondaryColor, fontSize: 14)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Item Description', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: itemsData.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = itemsData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, 
                        child: Text(item['product_name']?.toString() ?? 'Item', 
                          style: GoogleFonts.outfit(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500))
                      ),
                      Expanded(
                        flex: 1, 
                        child: Text(item['quantity']?.toString() ?? '1', 
                          textAlign: TextAlign.center, style: GoogleFonts.outfit(color: secondaryColor, fontSize: 14))
                      ),
                      Expanded(
                        flex: 2, 
                        child: Text('₹${fmt.format(item['selling_price'] ?? 0)}', 
                          textAlign: TextAlign.right, style: GoogleFonts.outfit(color: secondaryColor, fontSize: 14))
                      ),
                      Expanded(
                        flex: 2, 
                        child: Text('₹${fmt.format(item['total'] ?? 0)}', 
                          textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Divider(color: Colors.grey.shade200, thickness: 2),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: GoogleFonts.outfit(color: secondaryColor)),
                        Text('₹${fmt.format(subtotal)}', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount', style: GoogleFonts.outfit(color: secondaryColor)),
                          Text('-₹${fmt.format(discount)}', style: GoogleFonts.outfit(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: GoogleFonts.outfit(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Thank you for shopping with us!',
                  style: GoogleFonts.outfit(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
