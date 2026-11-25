import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/expense_entry.dart';
import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';

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
                minimumSize: const Size(96, 44),
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BtjStore>();
    final expenses = store.expenses;
    final typedAmount = _parseInt(_amountController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BtjColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BtjColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: BtjColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
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
                              fontWeight: FontWeight.w600,
                              color: BtjColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            BtjFormatters.rupiah(store.todayTotalExpenses),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: BtjColors.danger,
                              fontFeatures: BtjTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${expenses.length} catatan',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: BtjColors.textSecondary,
                        fontFeatures: BtjTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BtjColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BtjColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Input Cepat Uang Laci Keluar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
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
                      decoration: const InputDecoration(
                        labelText: 'Nominal Pengeluaran',
                        hintText: 'Contoh: 15000',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amountPresets.map((nominal) {
                        final selected = typedAmount == nominal;
                        return Material(
                          color: selected
                              ? BtjColors.primary
                              : BtjColors.background,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _amountController.text = nominal.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 14),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: BtjColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((category) {
                        final selected = _category == category;
                        return Material(
                          color: selected
                              ? BtjColors.primarySoft
                              : BtjColors.background,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => setState(() => _category = category),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? BtjColors.primary
                                      : BtjColors.borderStrong,
                                  width: selected ? 2 : 1.1,
                                ),
                              ),
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
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Singkat (Opsional)',
                        hintText: 'Contoh: beli kresek 2 pak / parkir mobil',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _saveExpense(store),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Catat Kas Keluar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Riwayat Kas Keluar Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BtjColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (expenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BtjColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BtjColors.border),
                  ),
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: BtjColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.category.label,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: BtjColors.textPrimary,
                                      ),
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
                                const SizedBox(height: 5),
                                Text(
                                  entry.note,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: BtjColors.textPrimary,
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
                            fontSize: 15,
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
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
