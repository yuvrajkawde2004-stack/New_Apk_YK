import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfInvoiceService {
  static Future<Uint8List> generatePremiumInvoice({
    required String billNumber,
    required String customerName,
    required String customerPhone,
    required String date,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double discount,
    required double grandTotal,
  }) async {
    final pdf = pw.Document();

    // Premium Colors
    final PdfColor royalMaroon = PdfColor.fromHex('#4a0e17');
    final PdfColor gold = PdfColor.fromHex('#d4af37');
    final PdfColor darkGrey = PdfColor.fromHex('#333333');
    final PdfColor lightGrey = PdfColor.fromHex('#F9F9F9');
    final PdfColor emeraldGreen = PdfColor.fromHex('#10B981');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(royalMaroon, gold),
        footer: (context) => _buildFooter(royalMaroon, darkGrey),
        build: (context) => [
          _buildMetaInfo(billNumber, customerName, customerPhone, date, paymentMode, darkGrey),
          pw.SizedBox(height: 20),
          _buildItemizedTable(items, royalMaroon, gold, lightGrey, darkGrey),
          pw.SizedBox(height: 20),
          _buildSummary(subtotal, cgst, sgst, discount, grandTotal, royalMaroon, gold, emeraldGreen, darkGrey),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(PdfColor maroon, PdfColor gold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: gold, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RETAILFLOW',
                style: pw.TextStyle(color: maroon, fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('123 Main Street, Market Area, City', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('GSTIN: 27AADCB2230M1Z2 | Ph: +91 9876543210', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: maroon,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(color: gold, fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaInfo(String billNo, String name, String phone, String date, String mode, PdfColor darkGrey) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To:', style: pw.TextStyle(color: darkGrey, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Ph: $phone', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Invoice No: $billNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Payment Mode: $mode', style: const pw.TextStyle(fontSize: 10)),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                child: pw.Text('PAID', style: pw.TextStyle(color: PdfColors.green800, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemizedTable(List<Map<String, dynamic>> items, PdfColor maroon, PdfColor gold, PdfColor lightGrey, PdfColor darkGrey) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: maroon),
          children: [
            _buildTableCell('Item Description', isHeader: true, color: gold),
            _buildTableCell('Qty', isHeader: true, color: gold, align: pw.TextAlign.center),
            _buildTableCell('Rate (₹)', isHeader: true, color: gold, align: pw.TextAlign.right),
            _buildTableCell('Total (₹)', isHeader: true, color: gold, align: pw.TextAlign.right),
          ],
        ),
        // Table Rows
        ...List.generate(items.length, (index) {
          final item = items[index];
          final bgColor = index % 2 == 0 ? PdfColors.white : lightGrey;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              _buildTableCell(item['name'], color: darkGrey),
              _buildTableCell(item['qty'].toString(), color: darkGrey, align: pw.TextAlign.center),
              _buildTableCell(item['rate'].toStringAsFixed(2), color: darkGrey, align: pw.TextAlign.right),
              _buildTableCell(item['total'].toStringAsFixed(2), color: darkGrey, align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? PdfColors.black,
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummary(double subtotal, double cgst, double sgst, double discount, double grandTotal, PdfColor maroon, PdfColor gold, PdfColor emerald, PdfColor darkGrey) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // UPI QR Code
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Scan to Pay via UPI', style: pw.TextStyle(color: darkGrey, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 80,
                width: 80,
                color: PdfColors.grey200,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'upi://pay?pa=retailflow@upi&pn=RetailFlow&am=$grandTotal',
                  color: darkGrey,
                  width: 80,
                  height: 80,
                ),
              ),
            ],
          ),
        ),
        // Totals
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', subtotal),
              _buildTotalRow('CGST (2.5%)', cgst),
              _buildTotalRow('SGST (2.5%)', sgst),
              if (discount > 0)
                _buildTotalRow('Special Discount', -discount, textColor: emerald),
              pw.Divider(color: PdfColors.grey300),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: maroon, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET TOTAL', style: pw.TextStyle(color: gold, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(color: gold, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              if (discount > 0) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(color: PdfColors.green100, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text('You Saved ₹${discount.toStringAsFixed(2)}', style: pw.TextStyle(color: emerald, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: textColor ?? PdfColors.black)),
          pw.Text(amount < 0 ? '-₹${amount.abs().toStringAsFixed(2)}' : '₹${amount.toStringAsFixed(2)}', 
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor ?? PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(PdfColor maroon, PdfColor darkGrey) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: maroon, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text('Thank you for shopping with us!', style: pw.TextStyle(color: maroon, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Terms & Conditions: Goods once sold will not be taken back. Exchange within 7 days with original receipt.', 
          style: pw.TextStyle(color: darkGrey, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
