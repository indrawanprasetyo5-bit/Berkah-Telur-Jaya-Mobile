import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _handleSendWhatsApp() async {
    final receiptText = BtjFormatters.buildThermalReceiptText(
      widget.transaction,
    );
    final formattedMessage = '```\n$receiptText\n```';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(formattedMessage)}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: receiptText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak tersedia. Teks struk telah disalin ke clipboard.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;

    return Dialog(
      backgroundColor: BtjColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: BtjColors.borderStrong, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 416),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 15, 10, 14),
              decoration: const BoxDecoration(
                color: BtjColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                border: Border(
                  bottom: BorderSide(color: BtjColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BtjColors.successBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: BtjColors.successBorder),
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Resi kertas thermal 58mm',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: BtjColors.textSecondary,
                            fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: _ThermalPaperSheet(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.48,
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
                            fontSize: 14.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          BtjStoreInfo.receiptAddressLine1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                        const Text(
                          BtjStoreInfo.receiptAddressLine2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                        const _ReceiptDashedRule(),
                        _ReceiptRow(label: 'No', value: tx.receiptNumber),
                        _ReceiptRow(
                          label: 'Tanggal',
                          value: BtjFormatters.dateTime(tx.createdAt),
                        ),
                        _ReceiptRow(label: 'Kasir', value: tx.cashierName),
                        const _ReceiptDashedRule(),
                        for (final item in tx.items) ...[
                          Text(
                            item.isCracked
                                ? '${item.productName} [Retak -${BtjFormatters.percent(item.discountPercent)}]'
                                : item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 1),
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
                                  '  Potongan ${BtjFormatters.percent(item.discountPercent)}',
                              value:
                                  '-${BtjFormatters.rupiah(item.discountAmount, withPrefix: false)}',
                              valueColor: BtjColors.warning,
                            ),
                          const SizedBox(height: 6),
                        ],
                        const _ReceiptDashedRule(),
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
                          const SizedBox(height: 4),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const _PaidStampBadge(),
                            const Spacer(),
                            Text(
                              BtjFormatters.rupiah(tx.grandTotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BtjColors.textPrimary,
                                fontFeatures: BtjTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                          const SizedBox(height: 6),
                          Text(
                            'Catatan: ${tx.note!.trim()}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: BtjColors.textSecondary,
                            ),
                          ),
                        ],
                        const _ReceiptDashedRule(),
                        const Text(
                          'Terima kasih telah berbelanja',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Telur segar setiap hari',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: BtjColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(21),
                ),
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
                          onPressed: _handleSendWhatsApp,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: BtjColors.success,
                            backgroundColor: BtjColors.successBg,
                            side: const BorderSide(
                              color: BtjColors.successBorder,
                              width: 1.4,
                            ),
                          ),
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('Kirim WA'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCopyText,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Salin Teks'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: Text(
                      widget.isNewSale ? 'Transaksi Baru' : 'Tutup Pratinjau',
                    ),
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

class _PaidStampBadge extends StatelessWidget {
  const _PaidStampBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: BtjColors.successBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: BtjColors.success, width: 1.2),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 12,
            color: BtjColors.success,
          ),
          SizedBox(width: 3),
          Text(
            'LUNAS',
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: BtjColors.success,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThermalPaperSheet extends StatelessWidget {
  const _ThermalPaperSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const clipper = _ReceiptSawtoothClipper(toothWidth: 11, toothHeight: 7);

    return CustomPaint(
      painter: const _ReceiptPaperShadowPainter(clipper: clipper),
      child: ClipPath(
        clipper: clipper,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
          color: BtjColors.surfaceWarm,
          child: child,
        ),
      ),
    );
  }
}

class _ReceiptSawtoothClipper extends CustomClipper<Path> {
  const _ReceiptSawtoothClipper({
    this.toothWidth = 11,
    this.toothHeight = 7,
  });

  static const double _topRadius = 8;

  final double toothWidth;
  final double toothHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, _topRadius);
    path.quadraticBezierTo(0, 0, _topRadius, 0);
    path.lineTo(size.width - _topRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, _topRadius);

    final baseBottom = size.height - toothHeight;
    path.lineTo(size.width, baseBottom);

    final count = (size.width / toothWidth).floor().clamp(1, 200);
    final actualToothWidth = size.width / count;

    for (var i = count; i > 0; i--) {
      final midX = (i - 0.5) * actualToothWidth;
      final leftX = (i - 1) * actualToothWidth;
      path.lineTo(midX, size.height);
      path.lineTo(leftX, baseBottom);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ReceiptSawtoothClipper oldClipper) {
    return oldClipper.toothWidth != toothWidth ||
        oldClipper.toothHeight != toothHeight;
  }
}

class _ReceiptPaperShadowPainter extends CustomPainter {
  const _ReceiptPaperShadowPainter({required this.clipper});

  final _ReceiptSawtoothClipper clipper;

  @override
  void paint(Canvas canvas, Size size) {
    final shapePath = clipper.getClip(size);

    final ambientPaint = Paint()
      ..color = const Color(0x181C1917)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.save();
    canvas.translate(0, 7);
    canvas.drawPath(shapePath, ambientPaint);
    canvas.restore();

    final keyPaint = Paint()
      ..color = const Color(0x101C1917)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(shapePath, keyPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = BtjColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(shapePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptPaperShadowPainter oldDelegate) {
    return oldDelegate.clipper != clipper;
  }
}

class _ReceiptDashedRule extends StatelessWidget {
  const _ReceiptDashedRule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter()),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BtjColors.borderStrong
      ..strokeWidth = 1.1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      final endX = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, 0), Offset(endX, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.w800 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: weight),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: weight,
              color: valueColor,
              fontFeatures: BtjTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
