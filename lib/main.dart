import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/btj_store.dart';
import 'theme/btj_theme.dart';

void main() {
  runApp(const BtjMobileApp());
}

class BtjMobileApp extends StatelessWidget {
  const BtjMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BtjStore>(
      create: (_) => BtjStore(),
      child: MaterialApp(
        title: 'Berkah Telur Jaya Mobile',
        debugShowCheckedModeBanner: false,
        theme: BtjTheme.build(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<BtjStore, bool>((s) => s.isLoggedIn);
    return isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
