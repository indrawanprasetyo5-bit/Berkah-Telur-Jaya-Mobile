import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/sale_transaction.dart';
import '../services/formatters.dart';
import '../services/thermal_printer_service.dart';
import '../theme/btj_theme.dart';

class ThermalReceiptDialog extends StatefulWidget {
  const ThermalReceiptDialog({
    super.key,
    required this.transaction,
    this.isNewSale = true,
  });

  final SaleTransaction transaction;
  final bool isNewSale;

  @override
  State<ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<ThermalReceiptDialog> {
  final ThermalPrinterService _printerService = const ThermalPrinterService();
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final result = await _printerService.printReceipt(widget.transaction);
    if (!mounted) return;
    setState(() => _isPrinting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.sent ? BtjColors.success : BtjColors.danger,
      ),
    );
  }

  Future<void> _handleCopyText() async {
    final text = BtjFormatters.buildThermalReceiptText(widget.transaction);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks struk 58mm disalin ke clipboard.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;

    return Dialog(
      backgroundColor: BtjColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: BtjColors.borderStrong, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
              decoration: const BoxDecoration(
                color: BtjColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                border: Border(
                  bottom: BorderSide(color: BtjColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BtjColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: BtjColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isNewSale
                              ? 'Transaksi Tersimpan'
                              : 'Pratinjau Struk Thermal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Format kertas thermal 58mm',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BtjColors.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.45,
                      color: BtjColors.textPrimary,
                      fontFeatures: BtjTheme.tabularFigures,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'BERKAH TELUR JAYA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          BtjStoreInfo.receiptAddressLine1,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5),
                        ),
                        const Text(
                          BtjStoreInfo.receiptAddressLine2,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5),
                        ),
                        const _ReceiptDashedDivider(),
                        _ReceiptRow(label: 'No', value: tx.receiptNumber),
                        _ReceiptRow(
                          label: 'Tgl',
                          value: BtjFormatters.dateTime(tx.createdAt),
                        ),
                        _ReceiptRow(label: 'Kasir', value: tx.cashierName),
                        const _ReceiptDashedDivider(),
                        for (final item in tx.items) ...[
                          Text(
                            item.isCracked
                                ? '${item.productName} [Retak -${BtjFormatters.percent(item.discountPercent)}]'
                                : item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          _ReceiptRow(
                            label:
                                '  ${BtjFormatters.weightKg(item.weightKg)} x ${BtjFormatters.rupiah(item.unitPricePerKg, withPrefix: false)}',
                            value: BtjFormatters.rupiah(
                              item.netAmount,
                              withPrefix: false,
                            ),
                          ),
                          if (item.discountAmount > 0)
                            _ReceiptRow(
                              label:
                                  '  Diskon ${BtjFormatters.percent(item.discountPercent)}',
                              value:
                                  '-${BtjFormatters.rupiah(item.discountAmount, withPrefix: false)}',
                              valueColor: BtjColors.warning,
                            ),
                          const SizedBox(height: 4),
                        ],
                        const _ReceiptDashedDivider(),
                        if (tx.totalDiscount > 0) ...[
                          _ReceiptRow(
                            label: 'Subtotal',
                            value: BtjFormatters.rupiah(tx.subtotal),
                          ),
                          _ReceiptRow(
                            label: 'Total Diskon',
                            value: '-${BtjFormatters.rupiah(tx.totalDiscount)}',
                            valueColor: BtjColors.warning,
                          ),
                        ],
                        _ReceiptRow(
                          label: 'TOTAL',
                          value: BtjFormatters.rupiah(tx.grandTotal),
                          isBold: true,
                          fontSize: 14,
                        ),
                        const SizedBox(height: 2),
                        _ReceiptRow(
                          label: 'Bayar (${tx.paymentMethod.label})',
                          value: BtjFormatters.rupiah(tx.amountPaid),
                        ),
                        if (tx.paymentMethod == PaymentMethod.tunai)
                          _ReceiptRow(
                            label: 'Kembalian',
                            value: BtjFormatters.rupiah(tx.changeAmount),
                            isBold: true,
                            valueColor: BtjColors.success,
                          ),
                        if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Catatan: ${tx.note!.trim()}'),
                        ],
                        const _ReceiptDashedDivider(),
                        const Text(
                          'Terima kasih telah berbelanja',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Telur segar setiap hari',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: BtjColors.surface,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(17)),
                border: Border(
                  top: BorderSide(color: BtjColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded),
                    label: Text(
                      _isPrinting
                          ? 'Menyiapkan Printer...'
                          : 'Cetak Struk (Bluetooth)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCopyText,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Salin Teks'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            widget.isNewSale ? 'Transaksi Baru' : 'Tutup',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final double? fontSize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.w800 : FontWeight.w500;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: weight, fontSize: fontSize),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: weight,
            fontSize: fontSize,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ReceiptDashedDivider extends StatelessWidget {
  const _ReceiptDashedDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '--------------------------------',
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(color: BtjColors.textMuted, letterSpacing: 0.5),
      ),
    );
  }
}
