import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One line item on an invoice.
class InvoiceLineItem {
  const InvoiceLineItem({required this.name, required this.price});
  final String name;
  final int price;
}

/// Generates the salon's PDF invoice. Used by the Billing screen's
/// "WhatsApp Bill" action (and available for any future "Print/Share
/// Invoice" action) — one shared implementation, not duplicated per
/// screen.
abstract class PdfInvoiceService {
  const PdfInvoiceService._();

  static Future<File> generateInvoice({
    required String invoiceNumber,
    required String businessName,
    required String customerName,
    required String customerPhone,
    required String dateTimeLabel,
    required List<InvoiceLineItem> lineItems,
    required int subtotal,
    required int discountPercent,
    required int discountAmount,
    required int total,
    required String paymentMethod,
  }) async {
    final pw.Document doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(businessName,
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Invoice #$invoiceNumber',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
              pw.Text(dateTimeLabel,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('Billed To',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(customerName,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(customerPhone, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
              pw.Table(
                columnWidths: const <int, pw.TableColumnWidth>{
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1)
                },
                children: <pw.TableRow>[
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey400))),
                    children: <pw.Widget>[
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text('Service',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text('Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  for (final InvoiceLineItem item in lineItems)
                    pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Text(item.name)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Text('Rs. ${item.price}',
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              _summaryRow('Subtotal', 'Rs. $subtotal'),
              _summaryRow(
                  'Discount ($discountPercent%)', '- Rs. $discountAmount'),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text('Total',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. $total',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Payment Method: $paymentMethod',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 24),
              pw.Center(
                  child: pw.Text('Thank you for visiting $businessName!',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey600))),
            ],
          );
        },
      ),
    );

    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
