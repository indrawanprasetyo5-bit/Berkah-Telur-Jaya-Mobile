import 'package:flutter/foundation.dart';

import '../models/closing_record.dart';
import '../models/egg_product.dart';
import '../models/expense_entry.dart';
import '../models/sale_transaction.dart';
import '../models/stock_log.dart';
import '../models/user_session.dart';

class BtjStore extends ChangeNotifier {
  UserSession? _session;
  final List<EggProduct> _products = <EggProduct>[
    const EggProduct(
      id: 'telur-negeri',
      name: 'Telur Ayam Negeri',
      shortName: 'Ayam Negeri',
      costPricePerKg: 24500,
      pricePerKg: 27500,
      stockKg: 145.5,
      criticalStockKg: 20,
      minStockKg: 45,
    ),
    const EggProduct(
      id: 'telur-omega',
      name: 'Telur Omega 3',
      shortName: 'Omega 3',
      costPricePerKg: 28500,
      pricePerKg: 32000,
      stockKg: 48.0,
      criticalStockKg: 10,
      minStockKg: 25,
    ),
    const EggProduct(
      id: 'telur-kampung',
      name: 'Telur Ayam Kampung',
      shortName: 'Ayam Kampung',
      costPricePerKg: 37500,
      pricePerKg: 42000,
      stockKg: 6.0,
      criticalStockKg: 8,
      minStockKg: 18,
    ),
    const EggProduct(
      id: 'telur-bebek',
      name: 'Telur Bebek',
      shortName: 'Bebek',
      costPricePerKg: 34000,
      pricePerKg: 38000,
      stockKg: 26.0,
      criticalStockKg: 8,
      minStockKg: 15,
    ),
    const EggProduct(
      id: 'telur-puyuh',
      name: 'Telur Puyuh',
      shortName: 'Puyuh',
      costPricePerKg: 32000,
      pricePerKg: 36000,
      stockKg: 12.0,
      criticalStockKg: 6,
      minStockKg: 15,
    ),
  ];

  final List<SaleTransaction> _transactions = <SaleTransaction>[];
  final List<StockLog> _stockLogs = <StockLog>[
    StockLog(
      id: 'stk-seed-1',
      type: StockLogType.kirimanMobil,
      productId: 'telur-negeri',
      productName: 'Telur Ayam Negeri',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      recordedBy: 'Kasir 1',
      crates: 10,
      grossKg: 150.0,
      brokenKg: 0.5,
      netKgDelta: 149.5,
      costPricePerKg: 24500,
      lossAmount: 12250,
      driverOrSupplier: 'Pak Dedi (Mobil Box 01)',
    ),
  ];
  final List<ExpenseEntry> _expenses = <ExpenseEntry>[];
  final List<ClosingRecord> _closings = <ClosingRecord>[];

  int _receiptSequence = 1;
  int _recordSequence = 2;

  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get isOwner => _session?.role == UserRole.owner;
  List<EggProduct> get products => List.unmodifiable(_products);
  List<SaleTransaction> get transactions => List.unmodifiable(_transactions);
  List<StockLog> get stockLogs => List.unmodifiable(_stockLogs);
  List<ExpenseEntry> get expenses => List.unmodifiable(_expenses);
  List<ClosingRecord> get closings => List.unmodifiable(_closings);

  List<EggProduct> get productsSortedByUrgency {
    final sorted = List<EggProduct>.from(_products);
    sorted.sort((a, b) {
      final levelCmp = a.stockLevel.sortOrder.compareTo(b.stockLevel.sortOrder);
      if (levelCmp != 0) return levelCmp;
      return a.stockKg.compareTo(b.stockKg);
    });
    return sorted;
  }

  int get todayTotalSales =>
      _transactions.fold<int>(0, (sum, tx) => sum + tx.grandTotal);

  int get todayCashSales => _transactions
      .where((tx) => tx.paymentMethod == PaymentMethod.tunai)
      .fold<int>(0, (sum, tx) => sum + tx.grandTotal);

  int get todayQrisSales => _transactions
      .where((tx) => tx.paymentMethod == PaymentMethod.qris)
      .fold<int>(0, (sum, tx) => sum + tx.grandTotal);

  int get todayTransferSales => _transactions
      .where((tx) => tx.paymentMethod == PaymentMethod.transfer)
      .fold<int>(0, (sum, tx) => sum + tx.grandTotal);

  double get todayTotalKg =>
      _transactions.fold<double>(0, (sum, tx) => sum + tx.totalWeightKg);

  int get todayTotalExpenses =>
      _expenses.fold<int>(0, (sum, item) => sum + item.amount);

  int get expectedDrawerCash => todayCashSales - todayTotalExpenses;

  int get todayTotalBreakageLoss =>
      _stockLogs.fold<int>(0, (sum, log) => sum + log.lossAmount);

  void loginDemoKasir() {
    _session = const UserSession(
      id: 'demo-kasir-1',
      name: 'Kasir 1',
      role: UserRole.kasir,
      isDemo: true,
    );
    notifyListeners();
  }

  void loginDemoOwner() {
    _session = const UserSession(
      id: 'demo-owner-lala',
      name: 'Lala',
      role: UserRole.owner,
      isDemo: true,
    );
    notifyListeners();
  }

  void logout() {
    _session = null;
    notifyListeners();
  }

  EggProduct? findProductById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  SaleTransaction recordSale({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    required int amountPaid,
    String? note,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.grossAmount);
    final totalDiscount =
        items.fold<int>(0, (sum, item) => sum + item.discountAmount);
    final grandTotal = items.fold<int>(0, (sum, item) => sum + item.netAmount);
    final effectivePaid =
        paymentMethod == PaymentMethod.tunai ? amountPaid : grandTotal;
    final changeAmount =
        paymentMethod == PaymentMethod.tunai ? effectivePaid - grandTotal : 0;

    final tx = SaleTransaction(
      receiptNumber: _nextReceiptNumber(now),
      createdAt: now,
      cashierName: _session?.name ?? 'Kasir',
      items: List<SaleItem>.unmodifiable(items),
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      grandTotal: grandTotal,
      amountPaid: effectivePaid,
      changeAmount: changeAmount < 0 ? 0 : changeAmount,
      note: note,
    );

    for (final item in items) {
      final index = _products.indexWhere((p) => p.id == item.productId);
      if (index != -1) {
        final current = _products[index];
        final nextStock = (current.stockKg - item.weightKg).clamp(0.0, 99999.0);
        _products[index] = current.copyWith(
          stockKg: double.parse(nextStock.toStringAsFixed(2)),
        );
      }
    }

    _transactions.insert(0, tx);
    notifyListeners();
    return tx;
  }

  StockLog recordDelivery({
    required String productId,
    required double crates,
    required int costPricePerKg,
    required String driverOrSupplier,
    required double brokenKg,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    final product = index != -1 ? _products[index] : _products.first;
    final grossKg = double.parse((crates * product.kgPerCrate).toStringAsFixed(2));
    final safeBroken = brokenKg.clamp(0.0, grossKg);
    final netAddedKg =
        double.parse((grossKg - safeBroken).toStringAsFixed(2));
    final lossAmount = (safeBroken * costPricePerKg).round();

    if (index != -1) {
      final nextStock = (product.stockKg + netAddedKg).clamp(0.0, 99999.0);
      _products[index] = product.copyWith(
        costPricePerKg: costPricePerKg > 0 ? costPricePerKg : product.costPricePerKg,
        stockKg: double.parse(nextStock.toStringAsFixed(2)),
      );
    }

    final log = StockLog(
      id: 'stk-${_recordSequence++}',
      type: StockLogType.kirimanMobil,
      productId: product.id,
      productName: product.name,
      createdAt: DateTime.now(),
      recordedBy: _session?.name ?? 'Kasir',
      crates: crates,
      grossKg: grossKg,
      brokenKg: double.parse(safeBroken.toStringAsFixed(2)),
      netKgDelta: netAddedKg,
      costPricePerKg: costPricePerKg,
      lossAmount: lossAmount,
      driverOrSupplier: driverOrSupplier.trim().isEmpty
          ? 'Supir / Distributor'
          : driverOrSupplier.trim(),
    );
    _stockLogs.insert(0, log);
    notifyListeners();
    return log;
  }

  StockLog recordBrokenEggs({
    required String productId,
    required double weightKg,
    required BrokenEggReason reason,
    String? note,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    final product = index != -1 ? _products[index] : _products.first;
    final cleanKg = double.parse(weightKg.toStringAsFixed(2));
    final lossAmount = (cleanKg * product.costPricePerKg).round();

    if (index != -1) {
      final nextStock = (product.stockKg - cleanKg).clamp(0.0, 99999.0);
      _products[index] = product.copyWith(
        stockKg: double.parse(nextStock.toStringAsFixed(2)),
      );
    }

    final log = StockLog(
      id: 'brk-${_recordSequence++}',
      type: StockLogType.telurPecah,
      productId: product.id,
      productName: product.name,
      createdAt: DateTime.now(),
      recordedBy: _session?.name ?? 'Kasir',
      grossKg: cleanKg,
      brokenKg: cleanKg,
      netKgDelta: -cleanKg,
      costPricePerKg: product.costPricePerKg,
      lossAmount: lossAmount,
      reason: reason,
      note: note?.trim(),
    );
    _stockLogs.insert(0, log);
    notifyListeners();
    return log;
  }

  ExpenseEntry addExpense({
    required int amount,
    required ExpenseCategory category,
    required String note,
  }) {
    final entry = ExpenseEntry(
      id: 'exp-${_recordSequence++}',
      amount: amount,
      category: category,
      note: note.trim(),
      createdAt: DateTime.now(),
      recordedBy: _session?.name ?? 'Kasir',
    );
    _expenses.insert(0, entry);
    notifyListeners();
    return entry;
  }

  void removeExpense(String id) {
    _expenses.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  ClosingRecord saveClosing({
    required int physicalCash,
    String? note,
  }) {
    final expected = expectedDrawerCash;
    final record = ClosingRecord(
      id: 'cls-${_recordSequence++}',
      createdAt: DateTime.now(),
      cashierName: _session?.name ?? 'Kasir',
      expectedCash: expected,
      physicalCash: physicalCash,
      difference: physicalCash - expected,
      totalCashSales: todayCashSales,
      totalExpenses: todayTotalExpenses,
      totalQrisSales: todayQrisSales,
      totalTransferSales: todayTransferSales,
      note: note?.trim(),
    );
    _closings.insert(0, record);
    notifyListeners();
    return record;
  }

  void updateDailyPrices(
    Map<String, ({int costPricePerKg, int pricePerKg})> updates,
  ) {
    for (var i = 0; i < _products.length; i++) {
      final product = _products[i];
      final next = updates[product.id];
      if (next != null) {
        _products[i] = product.copyWith(
          costPricePerKg: next.costPricePerKg,
          pricePerKg: next.pricePerKg,
        );
      }
    }
    notifyListeners();
  }

  String _nextReceiptNumber(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    final datePart = '${now.year}${two(now.month)}${two(now.day)}';
    final seqPart = _receiptSequence.toString().padLeft(3, '0');
    _receiptSequence++;
    return 'BTJ-$datePart-$seqPart';
  }
}
