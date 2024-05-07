import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scanner extends StatelessWidget {
  Scanner({super.key});
  MobileScannerController mobileScannerController = MobileScannerController();

  void _handleBarcode(BarcodeCapture barcodes, BuildContext context) {
    mobileScannerController.stop();
    mobileScannerController.dispose();
    Navigator.of(context).pop(barcodes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanne Barcode"),
      ),
      body: MobileScanner(
        controller: mobileScannerController,
        onDetect: (capture) => _handleBarcode(capture, context),
      ),
    );
  }
}
