import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/egg_product.dart';
import '../models/sale_transaction.dart';
import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';
import '../widgets/btj_ui.dart';
import '../widgets/thermal_receipt_dialog.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String _selectedProductId = 'telur-negeri';
  InputSaleMode _inputMode = InputSaleMode.kiloan;
  bool _isCracked = false;
  PaymentMethod _paymentMethod = PaymentMethod.tunai;

  final TextEditingController _kgController = TextEditingController(text: '1');
  final TextEditingController _rupiahController =
      TextEditingController(text: '50000');
  final TextEditingController _discountController =
      TextEditingController(text: '15');
  final TextEditingController _cashPaidController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<SaleItem> _cart = <SaleItem>[];

  static const List<double> _kgPresets = <double>[0.5, 1, 2, 5, 10, 15];
  static const List<int> _rupiahPresets = <int>[
    10000,
    20000,
    50000,
    100000,
    150000,
  ];
  static const List<double> _discountPresets = <double>[10, 15, 20, 25, 30];
  static const List<int> _cashPresets = <int>[20000, 50000, 100000, 200000];

  @override
  void dispose() {
    _kgController.dispose();
    _rupiahController.dispose();
    _discountController.dispose();
    _cashPaidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  int _parseInt(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  double get _activeDiscountPercent {
    if (!_isCracked) return 0;
    return _parseDouble(_discountController.text).clamp(0, 90);
  }

  SaleItem? _buildDraftItem(EggProduct product) {
    final discountPct = _activeDiscountPercent;

    if (_inputMode == InputSaleMode.kiloan) {
      final weightKg = _parseDouble(_kgController.text);
      if (weightKg <= 0) return null;
      final grossAmount = (weightKg * product.pricePerKg).round();
      final discountAmount = (grossAmount * discountPct / 100).round();
      final netAmount = grossAmount - discountAmount;
      return SaleItem(
        productId: product.id,
        productName: product.name,
        unitPricePerKg: product.pricePerKg,
        weightKg: double.parse(weightKg.toStringAsFixed(2)),
        inputMode: InputSaleMode.kiloan,
        isCracked: _isCracked,
        discountPercent: discountPct,
        grossAmount: grossAmount,
        discountAmount: discountAmount,
        netAmount: netAmount < 0 ? 0 : netAmount,
      );
    }

    final nominalRp = _parseInt(_rupiahController.text);
    if (nominalRp <= 0 || product.pricePerKg <= 0) return null;
    final weightKg = nominalRp / product.pricePerKg;
    final discountAmount = (nominalRp * discountPct / 100).round();
    final netAmount = nominalRp - discountAmount;
    return SaleItem(
      productId: product.id,
      productName: product.name,
      unitPricePerKg: product.pricePerKg,
      weightKg: double.parse(weightKg.toStringAsFixed(2)),
      inputMode: InputSaleMode.rupiah,
      isCracked: _isCracked,
      discountPercent: discountPct,
      grossAmount: nominalRp,
      discountAmount: discountAmount,
      netAmount: netAmount < 0 ? 0 : netAmount,
    );
  }

  List<SaleItem> _effectiveCheckoutItems(EggProduct selectedProduct) {
    if (_cart.isNotEmpty) return _cart;
    final draft = _buildDraftItem(selectedProduct);
    return draft == null ? const <SaleItem>[] : <SaleItem>[draft];
  }

  void _addDraftToCart(EggProduct selectedProduct) {
    final draft = _buildDraftItem(selectedProduct);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Masukkan berat (kg) atau nominal Rupiah terlebih dahulu.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _cart.add(draft);
      _isCracked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${draft.productName} (${BtjFormatters.weightKg(draft.weightKg)}) masuk daftar belanja.',
        ),
      ),
    );
  }

  void _removeCartItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _completeSale(BtjStore store, EggProduct selectedProduct) {
    final items = _effectiveCheckoutItems(selectedProduct);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada item yang valid untuk dibayar.'),
        ),
      );
      return;
    }

    final grandTotal = items.fold<int>(0, (sum, item) => sum + item.netAmount);
    var amountPaid = grandTotal;

    if (_paymentMethod == PaymentMethod.tunai) {
      final typedCash = _parseInt(_cashPaidController.text);
      amountPaid = typedCash == 0 ? grandTotal : typedCash;
      if (amountPaid < grandTotal) {
        final kurang = grandTotal - amountPaid;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BtjColors.danger,
            content: Text(
              'Uang tunai masih kurang ${BtjFormatters.rupiah(kurang)}.',
            ),
          ),
        );
        return;
      }
    }

    final tx = store.recordSale(
      items: items,
      paymentMethod: _paymentMethod,
      amountPaid: amountPaid,
      note: _noteController.text,
    );

    setState(() {
      _cart.clear();
      _isCracked = false;
      _kgController.text = '1';
      _rupiahController.text = '50000';
      _discountController.text = '15';
      _cashPaidController.clear();
      _noteController.clear();
    });

    showDialog<void>(
      context: context,
      builder: (_) => ThermalReceiptDialog(transaction: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final products = store.products;
    final selectedProduct =
        store.findProductById(_selectedProductId) ?? products.first;
    final draftItem = _buildDraftItem(selectedProduct);
    final checkoutItems = _effectiveCheckoutItems(selectedProduct);
    final grandTotal =
        checkoutItems.fold<int>(0, (sum, item) => sum + item.netAmount);
    final totalDiscount =
        checkoutItems.fold<int>(0, (sum, item) => sum + item.discountAmount);

    final typedCash = _parseInt(_cashPaidController.text);
    final effectiveCash = typedCash == 0 ? grandTotal : typedCash;
    final cashDelta = effectiveCash - grandTotal;
    final isCashShort =
        _paymentMethod == PaymentMethod.tunai && typedCash > 0 && cashDelta < 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BtjSectionHeader(
                      title: 'Pilih Jenis Telur',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BtjColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BtjColors.primaryBorder),
                        ),
                        child: Text(
                          '${BtjFormatters.rupiah(selectedProduct.pricePerKg)}/kg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.primaryPressed,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EggProductGrid(
                      products: products,
                      selectedId: selectedProduct.id,
                      onSelected: (product) {
                        setState(() => _selectedProductId = product.id);
                      },
                    ),
                    const SizedBox(height: 24),
                    const BtjSectionHeader(title: 'Mode Input & Jumlah'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BtjTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeSwitcher(
                            mode: _inputMode,
                            onChanged: (nextMode) {
                              setState(() => _inputMode = nextMode);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_inputMode == InputSaleMode.kiloan) ...[
                            TextField(
                              controller: _kgController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: BtjColors.textPrimary,
                                fontFeatures: BtjTheme.tabularFigures,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Berat Telur (kg)',
                                hintText: 'Contoh: 1.5',
                                suffixText: 'kg',
                                suffixStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _kgPresets.map((kg) {
                                final isSelected =
                                    _parseDouble(_kgController.text) == kg;
                                return _PresetChip(
                                  label: kg == 15
                                      ? '15 kg (1 peti)'
                                      : BtjFormatters.weightKg(kg),
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _kgController.text =
                                          kg == kg.roundToDouble()
                                              ? kg.toInt().toString()
                                              : kg.toString();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ] else ...[
                            TextField(
                              controller: _rupiahController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: BtjColors.textPrimary,
                                fontFeatures: BtjTheme.tabularFigures,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Nominal Beli (Rupiah)',
                                hintText: 'Contoh: 50000',
                                prefixText: 'Rp ',
                                prefixStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.textSecondary,
                                ),
                                helperText: draftItem != null
                                    ? 'Setara ${BtjFormatters.weightKg(draftItem.weightKg)} ${selectedProduct.shortName}'
                                    : 'Masukkan nominal pembelian',
                                helperStyle: const TextStyle(
                                  color: BtjColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: BtjTheme.tabularFigures,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _rupiahPresets.map((nominal) {
                                final isSelected =
                                    _parseInt(_rupiahController.text) ==
                                        nominal;
                                return _PresetChip(
                                  label: '${nominal ~/ 1000} rb',
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _rupiahController.text =
                                          nominal.toString();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () =>
                                setState(() => _isCracked = !_isCracked),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _isCracked
                                          ? BtjColors.warningBg
                                          : BtjColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.egg_outlined,
                                      size: 20,
                                      color: _isCracked
                                          ? BtjColors.warning
                                          : BtjColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Telur Retak',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: BtjColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Aktifkan potongan diskon persen bebas',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: BtjColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isCracked,
                                    activeThumbColor: BtjColors.warning,
                                    activeTrackColor: BtjColors.warningBg,
                                    onChanged: (value) {
                                      setState(() => _isCracked = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isCracked) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: BtjColors.warningBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: BtjColors.warningBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _discountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]'),
                                      ),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: BtjTheme.tabularFigures,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Diskon Retak (%)',
                                      hintText: '0 - 90',
                                      suffixText: '%',
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _discountPresets.map((pct) {
                                      final isSelected =
                                          _activeDiscountPercent == pct;
                                      return _PresetChip(
                                        label: '${pct.toInt()}%',
                                        selected: isSelected,
                                        accentColor: BtjColors.warning,
                                        onTap: () {
                                          setState(() {
                                            _discountController.text =
                                                pct.toInt().toString();
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (draftItem != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: BtjColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: BtjColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${selectedProduct.shortName}  |  ${BtjFormatters.weightKg(draftItem.weightKg)}',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: BtjColors.textSecondary,
                                            fontFeatures:
                                                BtjTheme.tabularFigures,
                                          ),
                                        ),
                                        if (draftItem.discountAmount > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Hemat ${BtjFormatters.rupiah(draftItem.discountAmount)} (-${BtjFormatters.percent(draftItem.discountPercent)})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: BtjColors.warning,
                                              fontFeatures:
                                                  BtjTheme.tabularFigures,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    BtjFormatters.rupiah(draftItem.netAmount),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: BtjColors.textPrimary,
                                      fontFeatures: BtjTheme.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: draftItem == null
                                ? null
                                : () => _addDraftToCart(selectedProduct),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: Text(
                              _cart.isEmpty
                                  ? 'Tambah ke Daftar (Multi-Item)'
                                  : 'Tambah Item Lagi (${_cart.length} di daftar)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_cart.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      BtjSectionHeader(
                        title: 'Daftar Belanja (${_cart.length} item)',
                        trailing: TextButton(
                          onPressed: () => setState(_cart.clear),
                          child: const Text('Kosongkan'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BtjTheme.cardDecoration(),
                        child: Column(
                          children: [
                            for (var i = 0; i < _cart.length; i++) ...[
                              _CartItemRow(
                                item: _cart[i],
                                onRemove: () => _removeCartItem(i),
                              ),
                              if (i < _cart.length - 1) const Divider(),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const BtjSectionHeader(title: 'Metode Pembayaran'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BtjTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _PaymentMethodButton(
                                  label: 'Tunai',
                                  icon: Icons.payments_outlined,
                                  selected:
                                      _paymentMethod == PaymentMethod.tunai,
                                  onTap: () {
                                    setState(() {
                                      _paymentMethod = PaymentMethod.tunai;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PaymentMethodButton(
                                  label: 'QRIS',
                                  icon: Icons.qr_code_2_rounded,
                                  selected:
                                      _paymentMethod == PaymentMethod.qris,
                                  onTap: () {
                                    setState(() {
                                      _paymentMethod = PaymentMethod.qris;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PaymentMethodButton(
                                  label: 'Transfer',
                                  icon: Icons.account_balance_outlined,
                                  selected:
                                      _paymentMethod == PaymentMethod.transfer,
                                  onTap: () {
                                    setState(() {
                                      _paymentMethod = PaymentMethod.transfer;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_paymentMethod == PaymentMethod.tunai) ...[
                            TextField(
                              controller: _cashPaidController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: BtjColors.textPrimary,
                                fontFeatures: BtjTheme.tabularFigures,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Uang Diterima (Kosong = Uang Pas)',
                                hintText: BtjFormatters.rupiah(
                                  grandTotal,
                                  withPrefix: false,
                                ),
                                prefixText: 'Rp ',
                                prefixStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.textSecondary,
                                ),
                                suffixIcon: _cashPaidController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          setState(_cashPaidController.clear);
                                        },
                                        icon: const Icon(Icons.clear_rounded),
                                        tooltip: 'Hapus nominal',
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PresetChip(
                                  label: 'Uang Pas',
                                  selected: _cashPaidController.text.isEmpty ||
                                      typedCash == grandTotal,
                                  accentColor: BtjColors.success,
                                  onTap: () {
                                    setState(() {
                                      _cashPaidController.text =
                                          grandTotal.toString();
                                    });
                                  },
                                ),
                                ..._cashPresets.map((cash) {
                                  return _PresetChip(
                                    label: '${cash ~/ 1000} rb',
                                    selected: typedCash == cash,
                                    accentColor: BtjColors.success,
                                    onTap: () {
                                      setState(() {
                                        _cashPaidController.text =
                                            cash.toString();
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isCashShort
                                    ? BtjColors.dangerBg
                                    : BtjColors.successBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCashShort
                                      ? BtjColors.dangerBorder
                                      : BtjColors.successBorder,
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCashShort
                                        ? Icons.error_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: isCashShort
                                        ? BtjColors.danger
                                        : BtjColors.success,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isCashShort ? 'Uang Kurang' : 'Kembalian',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: isCashShort
                                            ? BtjColors.danger
                                            : BtjColors.success,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    BtjFormatters.rupiah(cashDelta.abs()),
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: isCashShort
                                          ? BtjColors.danger
                                          : BtjColors.success,
                                      fontFeatures: BtjTheme.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: BtjColors.infoBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: BtjColors.infoBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    color: BtjColors.info,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Pastikan pembayaran ${_paymentMethod.label} masuk tepat ${BtjFormatters.rupiah(grandTotal)} sebelum cetak struk.',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: BtjColors.info,
                                        fontFeatures: BtjTheme.tabularFigures,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _noteController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Catatan (Opsional)',
                              hintText:
                                  'Nama pelanggan / warung / no referensi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: BtjColors.surface,
            border: Border(
              top: BorderSide(color: BtjColors.border, width: 1),
            ),
            boxShadow: BtjTheme.topBarShadow,
          ),
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalDiscount > 0
                              ? 'Total (Hemat ${BtjFormatters.rupiah(totalDiscount)})'
                              : 'Total Bayar',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: totalDiscount > 0
                                ? BtjColors.warning
                                : BtjColors.textSecondary,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          BtjFormatters.rupiah(grandTotal),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: BtjColors.textPrimary,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: checkoutItems.isEmpty || isCashShort
                        ? null
                        : () => _completeSale(store, selectedProduct),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(178, 56),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Bayar & Struk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EggProductGrid extends StatelessWidget {
  const _EggProductGrid({
    required this.products,
    required this.selectedId,
    required this.onSelected,
  });

  final List<EggProduct> products;
  final String selectedId;
  final ValueChanged<EggProduct> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 520 ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products.map((product) {
            final isSelected = product.id == selectedId;
            final stockColor = switch (product.stockLevel) {
              StockLevel.aman => BtjColors.success,
              StockLevel.menipis => BtjColors.warning,
              StockLevel.kritis => BtjColors.danger,
            };

            return SizedBox(
              width: itemWidth,
              child: Container(
                decoration: BtjTheme.cardDecoration(
                  color: isSelected ? BtjColors.primaryTint : BtjColors.surface,
                  borderColor:
                      isSelected ? BtjColors.primary : BtjColors.border,
                  borderWidth: isSelected ? 2.0 : 1.0,
                  radius: 16,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => onSelected(product),
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 98),
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: isSelected ? 24 : 0,
                                ),
                                child: Text(
                                  product.shortName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? BtjColors.primaryPressed
                                        : BtjColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${BtjFormatters.rupiah(product.pricePerKg)}/kg',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.textPrimary,
                                  fontFeatures: BtjTheme.tabularFigures,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: stockColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Stok ${BtjFormatters.weightKg(product.stockKg)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: stockColor,
                                        fontFeatures: BtjTheme.tabularFigures,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: BtjCheckBadge(size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.mode,
    required this.onChanged,
  });

  final InputSaleMode mode;
  final ValueChanged<InputSaleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BtjColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BtjColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Kiloan (kg)',
              icon: Icons.scale_outlined,
              selected: mode == InputSaleMode.kiloan,
              onTap: () => onChanged(InputSaleMode.kiloan),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeTab(
              label: 'Beli Rupiah (Rp)',
              icon: Icons.payments_outlined,
              selected: mode == InputSaleMode.rupiah,
              onTap: () => onChanged(InputSaleMode.rupiah),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? BtjColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : BtjColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : BtjColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor = BtjColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor : BtjColors.background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? accentColor : BtjColors.borderStrong,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : BtjColors.textPrimary,
              fontFeatures: BtjTheme.tabularFigures,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BtjColors.primaryTint : BtjColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? BtjColors.primary : BtjColors.borderStrong,
                  width: selected ? 2 : 1.1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color:
                        selected ? BtjColors.primary : BtjColors.textSecondary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? BtjColors.primaryPressed
                          : BtjColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 7,
                right: 7,
                child: BtjCheckBadge(size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onRemove,
  });

  final SaleItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isCracked
                      ? '${item.productName} (Retak -${BtjFormatters.percent(item.discountPercent)})'
                      : item.productName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: BtjColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${BtjFormatters.weightKg(item.weightKg)} x ${BtjFormatters.rupiah(item.unitPricePerKg)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: BtjColors.textSecondary,
                    fontFeatures: BtjTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            BtjFormatters.rupiah(item.netAmount),
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: BtjColors.textPrimary,
              fontFeatures: BtjTheme.tabularFigures,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: BtjColors.danger,
            ),
            tooltip: 'Hapus item',
          ),
        ],
      ),
    );
  }
}
