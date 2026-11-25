enum StockLogType { kirimanMobil, telurPecah }

enum BrokenEggReason {
  pecahLapak('Pecah Lapak'),
  busuk('Busuk'),
  lainnya('Lainnya');

  const BrokenEggReason(this.label);

  final String label;
}

class StockLog {
  const StockLog({
    required this.id,
    required this.type,
    required this.productId,
    required this.productName,
    required this.createdAt,
    required this.recordedBy,
    required this.grossKg,
    required this.brokenKg,
    required this.netKgDelta,
    required this.costPricePerKg,
    required this.lossAmount,
    this.crates,
    this.driverOrSupplier,
    this.reason,
    this.note,
  });

  final String id;
  final StockLogType type;
  final String productId;
  final String productName;
  final DateTime createdAt;
  final String recordedBy;
  final double grossKg;
  final double brokenKg;
  final double netKgDelta;
  final int costPricePerKg;
  final int lossAmount;
  final double? crates;
  final String? driverOrSupplier;
  final BrokenEggReason? reason;
  final String? note;
}
