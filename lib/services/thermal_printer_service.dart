import '../models/sale_transaction.dart';
import 'formatters.dart';

class ThermalPrintResult {
  const ThermalPrintResult({
    required this.sent,
    required this.message,
  });

  final bool sent;
  final String message;
}

// Placeholder boundary for Bluetooth ESC/POS thermal printer integration.
class ThermalPrinterService {
  const ThermalPrinterService();

  Future<ThermalPrintResult> printReceipt(SaleTransaction transaction) async {
    final payload = BtjFormatters.buildThermalReceiptText(transaction);
    if (payload.isEmpty) {
      return const ThermalPrintResult(
        sent: false,
        message: 'Data struk kosong.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ThermalPrintResult(
      sent: true,
      message:
          'Mode Demo: struk ${transaction.receiptNumber} siap dicetak ke printer Bluetooth 58mm.',
    );
  }
}
