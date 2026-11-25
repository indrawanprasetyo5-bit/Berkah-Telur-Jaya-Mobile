class ClosingRecord {
  const ClosingRecord({
    required this.id,
    required this.createdAt,
    required this.cashierName,
    required this.expectedCash,
    required this.physicalCash,
    required this.difference,
    required this.totalCashSales,
    required this.totalExpenses,
    required this.totalQrisSales,
    required this.totalTransferSales,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final String cashierName;
  final int expectedCash;
  final int physicalCash;
  final int difference;
  final int totalCashSales;
  final int totalExpenses;
  final int totalQrisSales;
  final int totalTransferSales;
  final String? note;
}
