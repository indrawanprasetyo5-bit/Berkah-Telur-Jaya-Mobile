import 'package:btj_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login demo kasir masuk ke Kasir Cepat dan buka struk thermal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BtjMobileApp());

    expect(find.text('Berkah Telur Jaya'), findsOneWidget);
    expect(find.text('Masuk Demo Kasir (Kasir 1)'), findsOneWidget);
    expect(find.text('Masuk Demo Owner (Lala)'), findsOneWidget);

    await tester.tap(find.text('Masuk Demo Kasir (Kasir 1)'));
    await tester.pumpAndSettle();

    expect(find.text('Kasir Cepat'), findsOneWidget);

    await tester.tap(find.text('Bayar & Struk'));
    await tester.pumpAndSettle();

    expect(find.text('Transaksi Tersimpan'), findsOneWidget);
    expect(find.text('LUNAS'), findsOneWidget);
    expect(find.text('Kirim WA'), findsOneWidget);
    expect(find.text('Salin Teks'), findsOneWidget);
    expect(find.text('Cetak Struk (Bluetooth)'), findsOneWidget);

    await tester.tap(find.text('Transaksi Baru'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stok'));
    await tester.pumpAndSettle();
    expect(find.text('Terima Kiriman'), findsOneWidget);
    expect(find.text('Pecah / Busuk'), findsOneWidget);
    expect(find.text('Minta Kirim WA'), findsWidgets);

    await tester.tap(find.text('Kas Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp 10rb'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Catat Kas Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat Kas Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('1 catatan'), findsOneWidget);

    await tester.tap(find.text('Tutup Kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Uang Tunai Seharusnya di Laci'), findsOneWidget);
    expect(find.text('Update Harga Harian'), findsNothing);
  });

  testWidgets('Role Owner (Lala) memiliki akses cepat Update Harga Harian',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BtjMobileApp());

    await tester.tap(find.text('Masuk Demo Owner (Lala)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tutup Kasir'));
    await tester.pumpAndSettle();

    expect(find.text('Update Harga Harian'), findsOneWidget);

    await tester.tap(find.text('Update Harga Harian'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan Harga Harian'), findsOneWidget);
  });
}
