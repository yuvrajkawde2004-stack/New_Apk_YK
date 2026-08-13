import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class LedgerPdfService {
  static Future<Uint8List> generateLedgerPdf({
    required String title,
    required String partyName,
    required String phone,
    required double totalOutstanding,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    // Calculate initial balance to support running balance
    double netTransactions = 0.0;
    for (var t in transactions) {
      final isBill = t['is_bill'] == true;
      final totalAmt = (t['total_amt'] as num?)?.toDouble() ?? 0.0;
      final paidAmt = (t['paid_amt'] as num?)?.toDouble() ?? 0.0;
      if (isBill) {
        netTransactions += (totalAmt - paidAmt);
      } else {
        netTransactions -= paidAmt;
      }
    }
    double currentBalance = totalOutstanding - netTransactions;

    // Sort ascending (oldest first)
    final sortedTransactions = List<Map<String, dynamic>>.from(transactions);
    sortedTransactions.sort((a, b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));

    final processedRows = <List<String>>[];
    
    // Always add Opening Balance if there are transactions or balance is non-zero
    if (sortedTransactions.isNotEmpty || currentBalance != 0.0) {
        final dateStr = sortedTransactions.isNotEmpty ? sortedTransactions.first['date'].toString() : DateFormat('yyyy-MM-dd').format(DateTime.now());
        processedRows.add([
            dateStr,
            'Opening Balance',
            '-',
            '-',
            'Rs. ${fmt.format(currentBalance)}'
        ]);
    }
    
    for (var t in sortedTransactions) {
      final isBill = t['is_bill'] == true;
      final totalAmt = (t['total_amt'] as num?)?.toDouble() ?? 0.0;
      final paidAmt = (t['paid_amt'] as num?)?.toDouble() ?? 0.0;
      
      if (isBill) {
        currentBalance += (totalAmt - paidAmt);
      } else {
        currentBalance -= paidAmt;
      }
      
      processedRows.add([
         t['date']?.toString() ?? '',
         t['description']?.toString() ?? '',
         isBill ? 'Rs. ${fmt.format(totalAmt)}' : '-',
         'Rs. ${fmt.format(paidAmt)}',
         'Rs. ${fmt.format(currentBalance)}'
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                        pw.SizedBox(height: 6),
                        pw.Text('Name: $partyName', style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#334155'), fontWeight: pw.FontWeight.bold)),
                        if (phone.isNotEmpty) pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#64748B'))),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Total Outstanding', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Rs. ${fmt.format(totalOutstanding)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: totalOutstanding > 0 ? PdfColors.red700 : PdfColors.green700)),
                        pw.SizedBox(height: 6),
                        pw.Text('Date: ${dateFmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#94A3B8'))),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1.5),
              pw.SizedBox(height: 16),
            ]
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by RetailFlow App', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#94A3B8'), fontStyle: pw.FontStyle.italic)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#94A3B8'))),
                ]
              )
            ]
          );
        },
        build: (context) {
          return [
            pw.Text('Transaction History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
            pw.SizedBox(height: 12),

            if (processedRows.isEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 40),
                alignment: pw.Alignment.center,
                child: pw.Text('No transactions found.', style: pw.TextStyle(color: PdfColor.fromHex('#94A3B8'), fontSize: 14)),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#312E81'), // Indigo 900
                ),
                cellStyle: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#334155')),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                headers: ['Date', 'Description', 'Bill Amt', 'Paid Amt', 'Pending'],
                data: processedRows,
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generatePendingCustomersReportPdf({
    required String shopName,
    required double totalPending,
    required List<Map<String, dynamic>> pendingCustomers,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    // Sort by pending amount descending
    final sorted = List<Map<String, dynamic>>.from(pendingCustomers);
    sorted.sort((a, b) => (b['due'] as double).compareTo(a['due'] as double));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('$shopName - Pending Dues Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                        pw.SizedBox(height: 6),
                        pw.Text('Report Type: All Outstanding Customers', style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#334155'), fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Total Pending to Recover', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Rs. ${fmt.format(totalPending)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        pw.SizedBox(height: 6),
                        pw.Text('Date: ${dateFmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#94A3B8'))),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1.5),
              pw.SizedBox(height: 16),
            ]
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by RetailFlow App', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#94A3B8'), fontStyle: pw.FontStyle.italic)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#94A3B8'))),
                ]
              )
            ]
          );
        },
        build: (context) {
          return [
            if (sorted.isEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 40),
                alignment: pw.Alignment.center,
                child: pw.Text('No pending customers found.', style: pw.TextStyle(color: PdfColor.fromHex('#94A3B8'), fontSize: 14)),
              )
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#312E81'), // Indigo 900
                ),
                cellStyle: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#334155')),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                headers: ['Sr No', 'Customer Name', 'Phone Number', 'Address/Notes', 'Pending Due (Rs)'],
                data: sorted.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final c = e.value;
                  return [
                    i.toString(),
                    c['name']?.toString() ?? '',
                    c['phone']?.toString() ?? '',
                    c['notes']?.toString() ?? '-',
                    'Rs. ${fmt.format(c['due'] ?? 0.0)}',
                  ];
                }).toList(),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
