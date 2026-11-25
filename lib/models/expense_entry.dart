enum ExpenseCategory {
  plastik('Plastik'),
  parkir('Parkir'),
  konsumsi('Konsumsi'),
  lainnya('Lainnya');

  const ExpenseCategory(this.label);

  final String label;
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdAt,
    required this.recordedBy,
  });

  final String id;
  final int amount;
  final ExpenseCategory category;
  final String note;
  final DateTime createdAt;
  final String recordedBy;
}
