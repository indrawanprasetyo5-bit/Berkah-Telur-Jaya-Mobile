import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/btj_store.dart';
import '../services/formatters.dart';
import '../theme/btj_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.read<BtjStore>();

    return Scaffold(
      backgroundColor: BtjColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(6),
                      decoration: BtjTheme.cardDecoration(
                        radius: 22,
                        borderColor: BtjColors.borderStrong,
                        borderWidth: 1.3,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo-btj.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(
                              color: BtjColors.primarySoft,
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 48,
                                color: BtjColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    BtjStoreInfo.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: BtjColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: BtjColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          BtjStoreInfo.address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: BtjColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BtjTheme.cardDecoration(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Masuk Aplikasi Lapangan',
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: BtjColors.warningBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: BtjColors.warningBorder,
                                ),
                              ),
                              child: const Text(
                                'Mode Demo',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: BtjColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih peran untuk mulai transaksi cepat. Data tersimpan lokal dan siap disambungkan ke Supabase.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.48,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: store.loginDemoKasir,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          icon: const Icon(Icons.point_of_sale_rounded),
                          label: const Text('Masuk Demo Kasir (Kasir 1)'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: store.loginDemoOwner,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: BtjColors.primaryTint,
                            side: const BorderSide(
                              color: BtjColors.primary,
                              width: 1.6,
                            ),
                            foregroundColor: BtjColors.primaryPressed,
                          ),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Masuk Demo Owner (Lala)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BTJ Mobile v1.2  |  Kasir & Operasional Lapangan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: BtjColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
