import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/expense_entry.dart';
import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';
import '../widgets/btj_ui.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.plastik;

  static const List<int> _amountPresets = <int>[5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _parseInt(String raw) =>
      int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _saveExpense(BtjStore store) {
    final amount = _parseInt(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal pengeluaran terlebih dahulu.'),
        ),
      );
      return;
    }

    final entry = store.addExpense(
      amount: amount,
      category: _category,
      note: _noteController.text,
    );

    setState(() {
      _amountController.clear();
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: BtjColors.success,
        content: Text(
          'Kas keluar ${BtjFormatters.rupiah(entry.amount)} (${entry.category.label}) dicatat.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BtjStore store,
    ExpenseEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: BtjColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus Catatan Kas Keluar?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Hapus ${entry.category.label} sebesar ${BtjFormatters.rupiah(entry.amount)} dari catatan hari ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: BtjColors.danger,
                minimumSize: const Size(96, 46),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      store.removeExpense(entry.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan kas keluar dihapus.')),
      );
    }
  }

  IconData _iconForCategory(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.plastik => Icons.shopping_bag_outlined,
      ExpenseCategory.parkir => Icons.local_parking_rounded,
      ExpenseCategory.konsumsi => Icons.restaurant_outlined,
      ExpenseCategory.lainnya => Icons.receipt_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final expenses = store.expenses;
    final typedAmount = _parseInt(_amountController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BtjTheme.cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: BtjColors.dangerBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: BtjColors.dangerBorder),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: BtjColors.danger,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Kas Keluar Hari Ini',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: BtjColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            BtjFormatters.rupiah(store.todayTotalExpenses),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: BtjColors.danger,
                              fontFeatures: BtjTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: BtjColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${expenses.length} catatan',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: BtjColors.textPrimary,
                          fontFeatures: BtjTheme.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BtjTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Input Cepat Uang Laci Keluar',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
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
                      decoration: const InputDecoration(
                        labelText: 'Nominal Pengeluaran',
                        hintText: 'Contoh: 15000',
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BtjColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amountPresets.map((nominal) {
                        final selected = typedAmount == nominal;
                        return Material(
                          color: selected
                              ? BtjColors.primary
                              : BtjColors.background,
                          borderRadius: BorderRadius.circular(11),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _amountController.text = nominal.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: selected
                                      ? BtjColors.primary
                                      : BtjColors.borderStrong,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                'Rp ${nominal ~/ 1000}rb',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : BtjColors.textPrimary,
                                  fontFeatures: BtjTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final itemWidth = (constraints.maxWidth - spacing) / 2;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: ExpenseCategory.values.map((category) {
                            final selected = _category == category;
                            return SizedBox(
                              width: itemWidth,
                              child: Material(
                                color: selected
                                    ? BtjColors.primaryTint
                                    : BtjColors.background,
                                borderRadius: BorderRadius.circular(13),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _category = category),
                                  borderRadius: BorderRadius.circular(13),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(
                                          minHeight: 52,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          border: Border.all(
                                            color: selected
                                                ? BtjColors.primary
                                                : BtjColors.borderStrong,
                                            width: selected ? 2 : 1.1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconForCategory(category),
                                              size: 19,
                                              color: selected
                                                  ? BtjColors.primary
                                                  : BtjColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                category.label,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: selected
                                                      ? BtjColors.primaryPressed
                                                      : BtjColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (selected)
                                        const Positioned(
                                          top: 6,
                                          right: 6,
                                          child: BtjCheckBadge(size: 17),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _noteController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Singkat (Opsional)',
                        hintText: 'Contoh: beli kresek 2 pak / parkir mobil',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _saveExpense(store),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Catat Kas Keluar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const BtjSectionHeader(title: 'Riwayat Kas Keluar Hari Ini'),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BtjTheme.cardDecoration(),
                  child: const Text(
                    'Belum ada pengeluaran dari uang laci hari ini.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: BtjColors.textSecondary,
                    ),
                  ),
                )
              else
                for (final entry in expenses) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
                    decoration: BtjTheme.cardDecoration(),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: BtjColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            _iconForCategory(entry.category),
                            size: 19,
                            color: BtjColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.category.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: BtjColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${BtjFormatters.timeOnly(entry.createdAt)}  |  ${entry.recordedBy}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: BtjColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.note.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  entry.note,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: BtjColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          BtjFormatters.rupiah(entry.amount),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: BtjColors.danger,
                            fontFeatures: BtjTheme.tabularFigures,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDelete(context, store, entry),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: BtjColors.danger,
                          ),
                          tooltip: 'Hapus pengeluaran',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
