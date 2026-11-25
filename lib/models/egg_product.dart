enum StockLevel {
  kritis(0, 'Kritis'),
  menipis(1, 'Menipis'),
  aman(2, 'Aman');

  const StockLevel(this.sortOrder, this.label);

  final int sortOrder;
  final String label;
}

class EggProduct {
  const EggProduct({
    required this.id,
    required this.name,
    required this.shortName,
    required this.costPricePerKg,
    required this.pricePerKg,
    required this.stockKg,
    required this.criticalStockKg,
    required this.minStockKg,
    this.kgPerCrate = 15.0,
  });

  final String id;
  final String name;
  final String shortName;
  final int costPricePerKg;
  final int pricePerKg;
  final double stockKg;
  final double criticalStockKg;
  final double minStockKg;
  final double kgPerCrate;

  double get estimatedCrates => kgPerCrate <= 0 ? 0 : stockKg / kgPerCrate;

  int get marginPerKg => pricePerKg - costPricePerKg;

  StockLevel get stockLevel {
    if (stockKg <= criticalStockKg) return StockLevel.kritis;
    if (stockKg <= minStockKg) return StockLevel.menipis;
    return StockLevel.aman;
  }

  EggProduct copyWith({
    int? costPricePerKg,
    int? pricePerKg,
    double? stockKg,
  }) {
    return EggProduct(
      id: id,
      name: name,
      shortName: shortName,
      costPricePerKg: costPricePerKg ?? this.costPricePerKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      stockKg: stockKg ?? this.stockKg,
      criticalStockKg: criticalStockKg,
      minStockKg: minStockKg,
      kgPerCrate: kgPerCrate,
    );
  }
}
