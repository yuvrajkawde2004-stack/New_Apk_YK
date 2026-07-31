import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceTemplateRoyalBlue extends StatelessWidget {
  final Map<String, dynamic> billData;
  final List<Map<String, dynamic>> itemsData;

  const InvoiceTemplateRoyalBlue({
    super.key,
    required this.billData,
    required this.itemsData,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    final primaryColor = const Color(0xFF1E40AF); // Blue 800
    final secondaryColor = const Color(0xFF60A5FA); // Blue 400
    final bgColor = const Color(0xFFF8FAFC);
    
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
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No: ${billData['bill_number'] ?? 'N/A'}',
                      style: GoogleFonts.outfit(
                        color: secondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.storefront_rounded, color: primaryColor, size: 40),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INVOICE TO', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(customerName, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold)),
                        if (customerMobile.isNotEmpty)
                          Text('+91 $customerMobile', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('DATE', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(formattedDate, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))),
                            Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))),
                            Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))),
                            Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))),
                          ],
                        ),
                      ),
                      
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: itemsData.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
                        itemBuilder: (context, index) {
                          final item = itemsData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3, 
                                  child: Text(item['product_name']?.toString() ?? 'Item', 
                                    style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600))
                                ),
                                Expanded(
                                  flex: 1, 
                                  child: Text(item['quantity']?.toString() ?? '1', 
                                    textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14))
                                ),
                                Expanded(
                                  flex: 2, 
                                  child: Text('₹${fmt.format(item['selling_price'] ?? 0)}', 
                                    textAlign: TextAlign.right, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14))
                                ),
                                Expanded(
                                  flex: 2, 
                                  child: Text('₹${fmt.format(item['total'] ?? 0)}', 
                                    textAlign: TextAlign.right, style: GoogleFonts.outfit(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold))
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 280,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: GoogleFonts.outfit(color: secondaryColor)),
                              Text('₹${fmt.format(subtotal)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount', style: GoogleFonts.outfit(color: secondaryColor)),
                                Text('-₹${fmt.format(discount)}', style: GoogleFonts.outfit(color: const Color(0xFFFCD34D), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Colors.white24),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Thank you for your business',
                        style: GoogleFonts.outfit(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We hope to see you again soon!',
                        style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
