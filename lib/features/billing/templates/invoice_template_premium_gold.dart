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
    final goldColor = const Color(0xFFD4AF37);
    final darkBg = const Color(0xFF111111);
    
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: darkBg,
        border: Border.all(color: goldColor.withValues(alpha: 0.3), width: 2),
      ),
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
                    'RETAILFLOW POS',
                    style: GoogleFonts.cinzel(
                      color: goldColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 2, color: goldColor),
                  const SizedBox(height: 8),
                  Text(
                    'INVOICE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 2),
                ),
                child: Center(
                  child: Icon(Icons.star_rounded, color: goldColor, size: 32),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INVOICE TO:', style: GoogleFonts.outfit(color: goldColor, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(customerName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (customerMobile.isNotEmpty)
                    Text('+91 $customerMobile', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('DATE: $formattedDate', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('INV NO: ${billData['bill_number'] ?? 'N/A'}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: goldColor.withValues(alpha: 0.5)),
                bottom: BorderSide(color: goldColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.outfit(color: goldColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: goldColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: goldColor, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: GoogleFonts.outfit(color: goldColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
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
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14))
                      ),
                      Expanded(
                        flex: 1, 
                        child: Text(item['quantity']?.toString() ?? '1', 
                          textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14))
                      ),
                      Expanded(
                        flex: 2, 
                        child: Text('₹${fmt.format(item['selling_price'] ?? 0)}', 
                          textAlign: TextAlign.right, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14))
                      ),
                      Expanded(
                        flex: 2, 
                        child: Text('₹${fmt.format(item['total'] ?? 0)}', 
                          textAlign: TextAlign.right, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SUBTOTAL', style: GoogleFonts.outfit(color: Colors.white70)),
                    Text('₹${fmt.format(subtotal)}', style: GoogleFonts.outfit(color: Colors.white)),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DISCOUNT', style: GoogleFonts.outfit(color: goldColor)),
                      Text('-₹${fmt.format(discount)}', style: GoogleFonts.outfit(color: goldColor)),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white24),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GRAND TOTAL', style: GoogleFonts.outfit(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${fmt.format(grandTotal)}', style: GoogleFonts.outfit(color: goldColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Thank You',
              style: GoogleFonts.dancingScript(
                color: goldColor,
                fontSize: 42,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'For your business!',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          )
        ],
      ),
    );
  }
}
