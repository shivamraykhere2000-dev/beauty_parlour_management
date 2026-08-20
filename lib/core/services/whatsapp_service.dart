import 'dart:io';

import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  static Future<void> sendInvoice({
    required String pdfPath,
    required String phoneNumber,
    required String message,
  }) async {
    final File pdfFile = File(pdfPath);

    if (!await pdfFile.exists()) {
      throw Exception('Invoice PDF not found');
    }

    final XFile pdf = XFile(
      pdfFile.path,
      mimeType: 'application/pdf',
      name: 'invoice.pdf',
    );

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        files: [pdf],
      ),
    );
  }
}
