# Berkah Telur Jaya Mobile (BTJ)

Aplikasi mobile Flutter untuk kasir dan operasional lapangan **Berkah Telur Jaya** (Jl. Letnan Sukarna, Kp. Gedong, Ciampea, Bogor). Dirancang sebagai pendamping [Web Dashboard Berkah Telur Jaya](https://github.com/indrawanprasetyo5-bit/Berkah-Telur-Jaya) ([Live Web](https://berkah-telur-jaya.vercel.app/)) agar pencatatan transaksi, stok peti, kas keluar, dan tutup kasir bisa dilakukan langsung dari HP.

## Fitur

- **Login & Role**: Mode demo cepat untuk **Owner (Lala)** dan **Kasir (Kasir 1)** agar aplikasi bisa langsung dicoba tanpa setup backend terlebih dahulu.
- **Kasir Cepat**: Pilih jenis telur, input mode **Kiloan** (`1/4 kg` sampai `1 peti`) atau **Beli Rupiah** (konversi berat otomatis), mode **Telur Retak** dengan preset maupun persen diskon bebas, pembayaran Tunai/QRIS/Transfer dengan hitung kembalian otomatis, dan tampilan **Struk Resi Thermal**.
- **Stok & Kiriman Mobil**: Kartu stok tiap jenis telur (diurutkan Kritis, Menipis, Aman) dalam `kg` dan estimasi `peti`, tombol pesan WhatsApp ke gudang, form terima kiriman mobil, dan pencatatan telur pecah/busuk.
- **Kas Keluar**: Input cepat pengeluaran uang laci harian (Plastik, Parkir, Konsumsi, Lainnya) lengkap dengan preset nominal dan riwayat hari ini.
- **Tutup Kasir & Update Harga**: Bandingkan uang fisik di laci terhadap kas seharusnya (`tunai masuk - kas keluar`), lihat ringkasan QRIS/Transfer, serta akses update harga modal/jual harian untuk Owner.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider (`ChangeNotifier`)
- **Desain**: Material 3 dengan palet warna hangat kustom (krem `#FAF7F2`, terracotta `#9A3412`, charcoal `#1C1917`)

## Menjalankan di Lokal

Pastikan Flutter SDK sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter run -d chrome
```

Untuk build Android APK (memerlukan Android SDK):

```bash
flutter build apk --release
```
