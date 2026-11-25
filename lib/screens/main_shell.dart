import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/btj_store.dart';
import '../theme/btj_theme.dart';
import 'closing_screen.dart';
import 'expense_screen.dart';
import 'kasir_screen.dart';
import 'stock_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Kasir Cepat',
    'Stok Telur',
    'Kas Keluar',
    'Tutup Kasir',
  ];

  static const List<Widget> _pages = <Widget>[
    KasirScreen(),
    StockScreen(),
    ExpenseScreen(),
    ClosingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<BtjStore>().session;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: BtjColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BtjColors.borderStrong),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo-btj.jpg',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 34,
                      height: 34,
                      color: BtjColors.primarySoft,
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 20,
                        color: BtjColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titles[_selectedIndex],
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: BtjColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Berkah Telur Jaya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BtjColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BtjColors.primaryTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BtjColors.primaryBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: BtjColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${session.name} (${session.roleLabel})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: BtjColors.primaryPressed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BtjColors.surface,
          border: Border(
            top: BorderSide(color: BtjColors.border, width: 1),
          ),
          boxShadow: BtjTheme.topBarShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              animationDuration: const Duration(milliseconds: 220),
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: 'Kasir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Stok',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: 'Kas Keluar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded),
                  label: 'Tutup Kasir',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
