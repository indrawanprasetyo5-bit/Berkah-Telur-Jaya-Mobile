import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/egg_product.dart';
import '../models/stock_log.dart';
import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';
import '../widgets/btj_ui.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  Future<void> _requestRestockViaWhatsApp(
    BuildContext context,
    EggProduct product,
  ) async {
    final message =
        'Halo, stok ${product.name} di ${BtjStoreInfo.name} sisa '
        '${BtjFormatters.weightKg(product.stockKg)} '
        '(${BtjFormatters.crates(product.estimatedCrates)}). '
        'Mohon dikirim tambahan stok hari ini. Terima kasih.';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!context.mounted) return;
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: message));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak tersedia di perangkat ini. Pesan permintaan stok disalin ke clipboard.',
          ),
        ),
      );
    }
  }

  void _openDeliverySheet(BuildContext context, {EggProduct? initialProduct}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BtjColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReceiveDeliverySheet(initialProduct: initialProduct),
    );
  }

  void _openBrokenEggSheet(BuildContext context, {EggProduct? initialProduct}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BtjColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RecordBrokenEggSheet(initialProduct: initialProduct),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final products = store.productsSortedByUrgency;
    final logs = store.stockLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openDeliverySheet(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Terima Kiriman'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openBrokenEggSheet(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        foregroundColor: BtjColors.warning,
                        side: const BorderSide(
                          color: BtjColors.warningBorder,
                          width: 1.5,
                        ),
                        backgroundColor: BtjColors.warningBg,
                      ),
                      icon: const Icon(Icons.egg_outlined),
                      label: const Text('Pecah / Busuk'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const BtjSectionHeader(
                title: 'Stok Telur Saat Ini',
                trailing: Text(
                  'Prioritas Kritis -> Aman',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BtjColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final product in products) ...[
                _StockCard(
                  product: product,
                  onRequestWa: () =>
                      _requestRestockViaWhatsApp(context, product),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              BtjSectionHeader(
                title: 'Riwayat Kiriman & Pecah Terbaru',
                trailing: store.todayTotalBreakageLoss > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BtjColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BtjColors.dangerBorder),
                        ),
                        child: Text(
                          'Rugi ${BtjFormatters.rupiah(store.todayTotalBreakageLoss)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.danger,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BtjTheme.cardDecoration(),
                  child: const Text(
                    'Belum ada catatan kiriman mobil atau telur pecah hari ini.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: BtjColors.textSecondary,
                    ),
                  ),
                )
              else
                for (final log in logs.take(10)) ...[
                  _StockLogTile(log: log),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.product,
    required this.onRequestWa,
  });

  final EggProduct product;
  final VoidCallback onRequestWa;

  @override
  Widget build(BuildContext context) {
    final (badgeFg, badgeBg, badgeBorder) = switch (product.stockLevel) {
      StockLevel.kritis => (
          BtjColors.danger,
          BtjColors.dangerBg,
          BtjColors.dangerBorder,
        ),
      StockLevel.menipis => (
          BtjColors.warning,
          BtjColors.warningBg,
          BtjColors.warningBorder,
        ),
      StockLevel.aman => (
          BtjColors.success,
          BtjColors.successBg,
          BtjColors.successBorder,
        ),
    };

    final isUrgent = product.stockLevel != StockLevel.aman;
    final capacityRef = (product.minStockKg * 2.5).clamp(15.0, 9999.0);
    final fillRatio = (product.stockKg / capacityRef).clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BtjTheme.cardDecoration(
        borderColor: product.stockLevel == StockLevel.kritis
            ? BtjColors.dangerBorder
            : BtjColors.border,
        borderWidth: product.stockLevel == StockLevel.kritis ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: BtjColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            product.stockLevel.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: badgeFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Modal ${BtjFormatters.rupiah(product.costPricePerKg)}  |  Jual ${BtjFormatters.rupiah(product.pricePerKg)}/kg',
                      style: const TextStyle(
                        fontSize: 13,
                        color: BtjColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    BtjFormatters.weightKg(product.stockKg),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: product.stockLevel == StockLevel.kritis
                          ? BtjColors.danger
                          : BtjColors.textPrimary,
                      fontFeatures: BtjTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BtjColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '~${BtjFormatters.crates(product.estimatedCrates)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BtjColors.textSecondary,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 5,
              backgroundColor: BtjColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(badgeFg),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onRequestWa,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor:
                    isUrgent ? BtjColors.successBg : BtjColors.background,
                foregroundColor: BtjColors.success,
                side: BorderSide(
                  color: isUrgent ? BtjColors.success : BtjColors.successBorder,
                  width: isUrgent ? 1.5 : 1.2,
                ),
              ),
              icon: const Icon(Icons.chat_outlined, size: 19),
              label: const Text('Minta Kirim WA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockLogTile extends StatelessWidget {
  const _StockLogTile({required this.log});

  final StockLog log;

  @override
  Widget build(BuildContext context) {
    final isDelivery = log.type == StockLogType.kirimanMobil;
    final accent = isDelivery ? BtjColors.success : BtjColors.danger;
    final bg = isDelivery ? BtjColors.successBg : BtjColors.dangerBg;

    final subtitleParts = <String>[
      BtjFormatters.timeOnly(log.createdAt),
      if (isDelivery && log.crates != null)
        '${BtjFormatters.crates(log.crates!)} (${log.driverOrSupplier ?? 'Supir'})',
      if (!isDelivery && log.reason != null) log.reason!.label,
      if (log.brokenKg > 0 && isDelivery)
        'Pecah ${BtjFormatters.weightKg(log.brokenKg)}',
      if (log.note != null && log.note!.isNotEmpty) log.note!,
    ];

    final deltaLabel = isDelivery
        ? '+${BtjFormatters.weightKg(log.netKgDelta)}'
        : '-${BtjFormatters.weightKg(log.netKgDelta.abs())}';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BtjTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isDelivery
                  ? Icons.local_shipping_outlined
                  : Icons.warning_amber_rounded,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.productName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: BtjColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleParts.join('  |  '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: BtjColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                deltaLabel,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFeatures: BtjTheme.tabularFigures,
                ),
              ),
              if (log.lossAmount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '-${BtjFormatters.rupiah(log.lossAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BtjColors.danger,
                    fontFeatures: BtjTheme.tabularFigures,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiveDeliverySheet extends StatefulWidget {
  const _ReceiveDeliverySheet({this.initialProduct});

  final EggProduct? initialProduct;

  @override
  State<_ReceiveDeliverySheet> createState() => _ReceiveDeliverySheetState();
}

class _ReceiveDeliverySheetState extends State<_ReceiveDeliverySheet> {
  late String _selectedProductId;
  final TextEditingController _cratesController =
      TextEditingController(text: '5');
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _brokenController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final store = context.read<BtjStore>();
    final initial = widget.initialProduct ?? store.products.first;
    _selectedProductId = initial.id;
    _costController.text = initial.costPricePerKg.toString();
  }

  @override
  void dispose() {
    _cratesController.dispose();
    _costController.dispose();
    _driverController.dispose();
    _brokenController.dispose();
    super.dispose();
  }

  double _parseDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  int _parseInt(String raw) =>
      int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _submit(BtjStore store, EggProduct product) {
    final crates = _parseDouble(_cratesController.text);
    final costPrice = _parseInt(_costController.text);
    final brokenKg = _parseDouble(_brokenController.text);
    if (crates <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah peti yang valid.')),
      );
      return;
    }

    final log = store.recordDelivery(
      productId: product.id,
      crates: crates,
      costPricePerKg: costPrice > 0 ? costPrice : product.costPricePerKg,
      driverOrSupplier: _driverController.text,
      brokenKg: brokenKg,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: BtjColors.success,
        content: Text(
          'Kiriman ${log.productName} (+${BtjFormatters.weightKg(log.netKgDelta)}) berhasil dicatat.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final product =
        store.findProductById(_selectedProductId) ?? store.products.first;
    final crates = _parseDouble(_cratesController.text);
    final grossKg = crates * product.kgPerCrate;
    final brokenKg = _parseDouble(_brokenController.text).clamp(0.0, grossKg);
    final netKg = (grossKg - brokenKg).clamp(0.0, 99999.0);
    final costPrice = _parseInt(_costController.text);
    final lossAmount =
        (brokenKg * (costPrice > 0 ? costPrice : product.costPricePerKg))
            .round();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: BtjColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Terima Kiriman Mobil',
                      style: TextStyle(
                        fontSize: 18.5,
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: product.id,
                decoration: const InputDecoration(labelText: 'Jenis Telur'),
                items: store.products
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final next = store.findProductById(value);
                  setState(() {
                    _selectedProductId = value;
                    if (next != null) {
                      _costController.text = next.costPricePerKg.toString();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cratesController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jumlah Peti',
                        suffixText: 'peti',
                        helperText:
                            '1 peti = ${product.kgPerCrate.toInt()} kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _brokenController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Pecah di Jalan',
                        suffixText: 'kg',
                        helperText: 'Otomatis kurangi stok',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: BtjTheme.tabularFigures,
                ),
                decoration: const InputDecoration(
                  labelText: 'Harga Modal / kg Hari Ini',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _driverController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Supir / Distributor',
                  hintText: 'Contoh: Pak Dedi / Peternakan Sukabumi',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BtjColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BtjColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimasi Berat Kotor',
                          style: TextStyle(
                            fontSize: 13,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                        Text(
                          BtjFormatters.weightKg(grossKg),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stok Masuk Bersih',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.textPrimary,
                          ),
                        ),
                        Text(
                          '+${BtjFormatters.weightKg(netKg)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.success,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    if (lossAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kerugian Pecah Pengiriman',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: BtjColors.danger,
                            ),
                          ),
                          Text(
                            '-${BtjFormatters.rupiah(lossAmount)}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: BtjColors.danger,
                              fontFeatures: BtjTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _submit(store, product),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan Kiriman ke Stok'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordBrokenEggSheet extends StatefulWidget {
  const _RecordBrokenEggSheet({this.initialProduct});

  final EggProduct? initialProduct;

  @override
  State<_RecordBrokenEggSheet> createState() => _RecordBrokenEggSheetState();
}

class _RecordBrokenEggSheetState extends State<_RecordBrokenEggSheet> {
  late String _selectedProductId;
  BrokenEggReason _reason = BrokenEggReason.pecahLapak;
  final TextEditingController _kgController =
      TextEditingController(text: '0.5');
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final store = context.read<BtjStore>();
    _selectedProductId = (widget.initialProduct ?? store.products.first).id;
  }

  @override
  void dispose() {
    _kgController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  void _submit(BtjStore store, EggProduct product) {
    final kg = _parseDouble(_kgController.text);
    if (kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan berat telur pecah/busuk (kg).')),
      );
      return;
    }

    final log = store.recordBrokenEggs(
      productId: product.id,
      weightKg: kg,
      reason: _reason,
      note: _noteController.text,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: BtjColors.warning,
        content: Text(
          'Dicatat ${BtjFormatters.weightKg(log.brokenKg)} ${log.productName} (${_reason.label}).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final product =
        store.findProductById(_selectedProductId) ?? store.products.first;
    final kg = _parseDouble(_kgController.text);
    final estLoss = (kg * product.costPricePerKg).round();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: BtjColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Catat Telur Pecah / Busuk',
                      style: TextStyle(
                        fontSize: 18.5,
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: product.id,
                decoration: const InputDecoration(labelText: 'Jenis Telur'),
                items: store.products
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.name} (Sisa ${BtjFormatters.weightKg(p.stockKg)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedProductId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kgController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFeatures: BtjTheme.tabularFigures,
                ),
                decoration: const InputDecoration(
                  labelText: 'Jumlah (kg)',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Alasan',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: BtjColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: BrokenEggReason.values.map((reason) {
                  final selected = _reason == reason;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: reason == BrokenEggReason.values.last ? 0 : 8,
                      ),
                      child: Material(
                        color:
                            selected ? BtjColors.warningBg : BtjColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => setState(() => _reason = reason),
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 48),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? BtjColors.warning
                                        : BtjColors.borderStrong,
                                    width: selected ? 2 : 1.1,
                                  ),
                                ),
                                child: Text(
                                  reason.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? BtjColors.warning
                                        : BtjColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Positioned(
                                  top: 5,
                                  right: 5,
                                  child: BtjCheckBadge(
                                    size: 16,
                                    color: BtjColors.warning,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Contoh: jatuh saat susun rak',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BtjColors.dangerBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BtjColors.dangerBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimasi Kerugian (Modal)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: BtjColors.danger,
                      ),
                    ),
                    Text(
                      BtjFormatters.rupiah(estLoss),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.danger,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _submit(store, product),
                style: FilledButton.styleFrom(
                  backgroundColor: BtjColors.danger,
                ),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                label: const Text('Kurangi Stok & Catat Rugi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
