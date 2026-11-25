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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 108,
                      height: 108,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: BtjColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: BtjColors.borderStrong,
                          width: 1.4,
                        ),
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
                  const SizedBox(height: 20),
                  const Text(
                    BtjStoreInfo.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: BtjColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            height: 1.4,
                            color: BtjColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: BtjColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BtjColors.border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Masuk Aplikasi Lapangan',
                                style: TextStyle(
                                  fontSize: 17,
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
                                  fontWeight: FontWeight.w700,
                                  color: BtjColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pilih peran untuk mulai transaksi cepat. Data tersimpan lokal dan siap disambungkan ke Supabase.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: BtjColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                            side: const BorderSide(
                              color: BtjColors.primary,
                              width: 1.6,
                            ),
                            foregroundColor: BtjColors.primary,
                          ),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Masuk Demo Owner (Lala)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'BTJ Mobile v1.0 (Tahap 1: Kasir Cepat)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: BtjColors.textMuted,
                      fontWeight: FontWeight.w500,
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
