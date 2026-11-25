import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/closing_record.dart';
import '../models/sale_transaction.dart';
import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';
import '../widgets/thermal_receipt_dialog.dart';

class ClosingScreen extends StatefulWidget {
  const ClosingScreen({super.key});

  @override
  State<ClosingScreen> createState() => _ClosingScreenState();
}

class _ClosingScreenState extends State<ClosingScreen> {
  final TextEditingController _physicalCashController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _physicalCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _parseInt(String raw) =>
      int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _saveClosing(BtjStore store) {
    if (_physicalCashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah uang fisik di laci terlebih dahulu.'),
        ),
      );
      return;
    }

    final physical = _parseInt(_physicalCashController.text);
    final record = store.saveClosing(
      physicalCash: physical,
      note: _noteController.text,
    );

    setState(() {
      _physicalCashController.clear();
      _noteController.clear();
    });

    final diffText = record.difference == 0
        ? 'Pas'
        : record.difference > 0
            ? 'Lebih ${BtjFormatters.rupiah(record.difference)}'
            : 'Kurang ${BtjFormatters.rupiah(record.difference.abs())}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            record.difference < 0 ? BtjColors.danger : BtjColors.success,
        content: Text('Tutup kasir tersimpan ($diffText).'),
      ),
    );
  }

  void _openDailyPriceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BtjColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DailyPriceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final session = store.session;
    final expectedCash = store.expectedDrawerCash;
    final hasTypedCash = _physicalCashController.text.trim().isNotEmpty;
    final physicalCash = _parseInt(_physicalCashController.text);
    final difference = physicalCash - expectedCash;

    final (diffLabel, diffFg, diffBg, diffBorder, diffIcon) = !hasTypedCash
        ? (
            'Isi uang fisik untuk cek selisih',
            BtjColors.textSecondary,
            BtjColors.surfaceSubtle,
            BtjColors.border,
            Icons.calculate_outlined,
          )
        : difference == 0
            ? (
                'Selisih: Pas',
                BtjColors.success,
                BtjColors.successBg,
                BtjColors.successBorder,
                Icons.check_circle_outline_rounded,
              )
            : difference > 0
                ? (
                    'Selisih: Lebih ${BtjFormatters.rupiah(difference)}',
                    BtjColors.info,
                    BtjColors.infoBg,
                    BtjColors.infoBorder,
                    Icons.trending_up_rounded,
                  )
                : (
                    'Selisih: Kurang ${BtjFormatters.rupiah(difference.abs())}',
                    BtjColors.danger,
                    BtjColors.dangerBg,
                    BtjColors.dangerBorder,
                    Icons.error_outline_rounded,
                  );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (store.isOwner) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BtjColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: BtjColors.primaryBorder,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akses Owner (Lala)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: BtjColors.primaryPressed,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ubah harga modal & jual harian, langsung sinkron ke Kasir.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: BtjColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _openDailyPriceSheet(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.price_change_outlined, size: 19),
                        label: const Text('Update Harga Harian'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BtjColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BtjColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Shift (${session?.name ?? '-'})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.transactions.length} transaksi  |  ${BtjFormatters.weightKg(store.todayTotalKg)} terjual',
                      style: const TextStyle(
                        fontSize: 13,
                        color: BtjColors.textSecondary,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BtjColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BtjColors.borderStrong),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Uang Tunai Seharusnya di Laci',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: BtjColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            BtjFormatters.rupiah(expectedCash),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: BtjColors.primary,
                              fontFeatures: BtjTheme.tabularFigures,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tunai Masuk ${BtjFormatters.rupiah(store.todayCashSales)}  -  Kas Keluar ${BtjFormatters.rupiah(store.todayTotalExpenses)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: BtjColors.textSecondary,
                              fontFeatures: BtjTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NonCashTile(
                            label: 'Total QRIS',
                            amount: store.todayQrisSales,
                            accent: BtjColors.info,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NonCashTile(
                            label: 'Total Transfer',
                            amount: store.todayTransferSales,
                            accent: BtjColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BtjColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BtjColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Hitung Uang Fisik & Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _physicalCashController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Uang Fisik di Laci',
                        hintText: BtjFormatters.rupiah(
                          expectedCash < 0 ? 0 : expectedCash,
                          withPrefix: false,
                        ),
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: diffBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: diffBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(diffIcon, color: diffFg),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              diffLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: diffFg,
                                fontFeatures: BtjTheme.tabularFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tutup Kasir (Opsional)',
                        hintText: 'Contoh: setor ke brankas / selisih uang receh',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _saveClosing(store),
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Simpan Tutup Kasir'),
                    ),
                  ],
                ),
              ),
              if (store.closings.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Riwayat Tutup Kasir Sesi Ini',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: BtjColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final record in store.closings) ...[
                  _ClosingHistoryTile(record: record),
                  const SizedBox(height: 8),
                ],
              ],
              if (store.transactions.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Transaksi Terakhir (Tap untuk Cetak Ulang)',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: BtjColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final tx in store.transactions.take(5)) ...[
                  _TransactionTile(
                    transaction: tx,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => ThermalReceiptDialog(
                          transaction: tx,
                          isNewSale: false,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => context.read<BtjStore>().logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BtjColors.danger,
                  side: const BorderSide(
                    color: BtjColors.dangerBorder,
                    width: 1.4,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar Akun / Ganti Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NonCashTile extends StatelessWidget {
  const _NonCashTile({
    required this.label,
    required this.amount,
    required this.accent,
  });

  final String label;
  final int amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BtjColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BtjColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BtjFormatters.rupiah(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BtjColors.textPrimary,
              fontFeatures: BtjTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingHistoryTile extends StatelessWidget {
  const _ClosingHistoryTile({required this.record});

  final ClosingRecord record;

  @override
  Widget build(BuildContext context) {
    final (diffText, diffColor) = record.difference == 0
        ? ('Pas', BtjColors.success)
        : record.difference > 0
            ? ('+${BtjFormatters.rupiah(record.difference)}', BtjColors.info)
            : ('-${BtjFormatters.rupiah(record.difference.abs())}', BtjColors.danger);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BtjColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BtjColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${BtjFormatters.timeOnly(record.createdAt)}  |  ${record.cashierName}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: BtjColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fisik ${BtjFormatters.rupiah(record.physicalCash)}  |  Target ${BtjFormatters.rupiah(record.expectedCash)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: BtjColors.textSecondary,
                    fontFeatures: BtjTheme.tabularFigures,
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    record.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: BtjColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            diffText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: diffColor,
              fontFeatures: BtjTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final SaleTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtjColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BtjColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.receiptNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BtjColors.textPrimary,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${BtjFormatters.timeOnly(transaction.createdAt)}  |  ${transaction.items.length} item  |  ${transaction.paymentMethod.label}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: BtjColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    BtjFormatters.rupiah(transaction.grandTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BtjColors.textPrimary,
                      fontFeatures: BtjTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Lihat Struk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BtjColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPriceSheet extends StatefulWidget {
  const _DailyPriceSheet();

  @override
  State<_DailyPriceSheet> createState() => _DailyPriceSheetState();
}

class _DailyPriceSheetState extends State<_DailyPriceSheet> {
  final Map<String, TextEditingController> _costControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _sellControllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final products = context.read<BtjStore>().products;
    for (final product in products) {
      _costControllers[product.id] =
          TextEditingController(text: product.costPricePerKg.toString());
      _sellControllers[product.id] =
          TextEditingController(text: product.pricePerKg.toString());
    }
  }

  @override
  void dispose() {
    for (final c in _costControllers.values) {
      c.dispose();
    }
    for (final c in _sellControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _parseInt(String raw) =>
      int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _savePrices(BtjStore store) {
    final updates = <String, ({int costPricePerKg, int pricePerKg})>{};
    for (final product in store.products) {
      final cost = _parseInt(_costControllers[product.id]?.text ?? '');
      final sell = _parseInt(_sellControllers[product.id]?.text ?? '');
      if (cost <= 0 || sell <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BtjColors.danger,
            content: Text('Harga ${product.name} harus lebih dari 0.'),
          ),
        );
        return;
      }
      updates[product.id] = (costPricePerKg: cost, pricePerKg: sell);
    }

    store.updateDailyPrices(updates);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: BtjColors.success,
        content: Text(
          'Harga harian berhasil diperbarui dan tersinkron ke Kasir.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          16,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Update Harga Harian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Perubahan harga jual/kg langsung aktif di tab Kasir Cepat.',
                style: TextStyle(
                  fontSize: 13,
                  color: BtjColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: store.products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = store.products[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BtjColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BtjColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: BtjColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _costControllers[product.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Modal / kg',
                                    prefixText: 'Rp ',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _sellControllers[product.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Jual / kg',
                                    prefixText: 'Rp ',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _savePrices(store),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan Harga Harian'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
