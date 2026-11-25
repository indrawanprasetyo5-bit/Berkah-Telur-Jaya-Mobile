enum InputSaleMode { kiloan, rupiah }

enum PaymentMethod { tunai, qris, transfer }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.tunai:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.transfer:
        return 'Transfer';
    }
  }
}

class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPricePerKg,
    required this.weightKg,
    required this.inputMode,
    required this.isCracked,
    required this.discountPercent,
    required this.grossAmount,
    required this.discountAmount,
    required this.netAmount,
  });

  final String productId;
  final String productName;
  final int unitPricePerKg;
  final double weightKg;
  final InputSaleMode inputMode;
  final bool isCracked;
  final double discountPercent;
  final int grossAmount;
  final int discountAmount;
  final int netAmount;
}

class SaleTransaction {
  const SaleTransaction({
    required this.receiptNumber,
    required this.createdAt,
    required this.cashierName,
    required this.items,
    required this.paymentMethod,
    required this.subtotal,
    required this.totalDiscount,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeAmount,
    this.note,
  });

  final String receiptNumber;
  final DateTime createdAt;
  final String cashierName;
  final List<SaleItem> items;
  final PaymentMethod paymentMethod;
  final int subtotal;
  final int totalDiscount;
  final int grandTotal;
  final int amountPaid;
  final int changeAmount;
  final String? note;

  double get totalWeightKg =>
      items.fold<double>(0, (sum, item) => sum + item.weightKg);
}
