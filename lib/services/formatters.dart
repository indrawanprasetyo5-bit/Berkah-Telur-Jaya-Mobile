import '../models/sale_transaction.dart';

class BtjStoreInfo {
  BtjStoreInfo._();

  static const String name = 'Berkah Telur Jaya';
  static const String shortName = 'BTJ';
  static const String address = 'Jl. Letnan Sukarna, Kp. Gedong, Ciampea, Bogor';
  static const String receiptAddressLine1 = 'Jl. Letnan Sukarna, Kp. Gedong';
  static const String receiptAddressLine2 = 'Ciampea, Bogor';
}

class BtjFormatters {
  BtjFormatters._();

  static String rupiah(int amount, {bool withPrefix = true}) {
    final isNegative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }
    final sign = isNegative ? '-' : '';
    return withPrefix ? '${sign}Rp $buffer' : '$sign$buffer';
  }

  static String weightKg(double kg) {
    if (kg == kg.roundToDouble()) {
      return '${kg.toInt()} kg';
    }
    final formatted = kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    final trimmed = formatted.endsWith('.')
        ? formatted.substring(0, formatted.length - 1)
        : formatted;
    return '${trimmed.replaceAll('.', ',')} kg';
  }

  static String crates(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} peti';
    }
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} peti';
  }

  static String percent(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  static String dateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  static String timeOnly(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  // Formats a 32-column plain text layout matching standard 58mm thermal paper.
  static String buildThermalReceiptText(SaleTransaction tx) {
    const width = 32;
    String center(String text) {
      if (text.length >= width) return text.substring(0, width);
      final pad = (width - text.length) ~/ 2;
      return '${' ' * pad}$text';
    }

    String pair(String left, String right) {
      final space = width - left.length - right.length;
      if (space <= 1) return '$left $right';
      return '$left${' ' * space}$right';
    }

    final sep = '-' * width;
    final lines = <String>[
      center(BtjStoreInfo.name.toUpperCase()),
      center(BtjStoreInfo.receiptAddressLine1),
      center(BtjStoreInfo.receiptAddressLine2),
      sep,
      pair('No', tx.receiptNumber),
      pair('Tgl', dateTime(tx.createdAt)),
      pair('Kasir', tx.cashierName),
      sep,
    ];

    for (final item in tx.items) {
      final crackedTag = item.isCracked
          ? ' [Retak -${percent(item.discountPercent)}]'
          : '';
      lines.add('${item.productName}$crackedTag');
      final detail =
          '  ${weightKg(item.weightKg)} x ${rupiah(item.unitPricePerKg, withPrefix: false)}';
      lines.add(pair(detail, rupiah(item.netAmount, withPrefix: false)));
      if (item.discountAmount > 0) {
        lines.add(
          pair(
            '  Diskon ${percent(item.discountPercent)}',
            '-${rupiah(item.discountAmount, withPrefix: false)}',
          ),
        );
      }
    }

    lines.add(sep);
    if (tx.totalDiscount > 0) {
      lines.add(pair('Subtotal', rupiah(tx.subtotal)));
      lines.add(pair('Total Diskon', '-${rupiah(tx.totalDiscount)}'));
    }
    lines.add(pair('TOTAL', rupiah(tx.grandTotal)));
    lines.add(pair('Bayar (${tx.paymentMethod.label})', rupiah(tx.amountPaid)));
    if (tx.paymentMethod == PaymentMethod.tunai) {
      lines.add(pair('Kembalian', rupiah(tx.changeAmount)));
    }
    if (tx.note != null && tx.note!.trim().isNotEmpty) {
      lines.add('Catatan: ${tx.note!.trim()}');
    }
    lines.add(sep);
    lines.add(center('Terima kasih telah berbelanja'));
    lines.add(center('Telur segar setiap hari'));
    return lines.join('\n');
  }
}
