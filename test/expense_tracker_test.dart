import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pengujian Form Kosong Ditolak, Hapus Data, dan Persistensi saat Tutup-Buka Aplikasi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);

    // =========================================================================
    // 1. UJI: Simpan Form Kosong, Harus Ditolak
    // =========================================================================
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengeluaran'), findsOneWidget);

    // Klik tombol Simpan saat judul & nominal masih kosong
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    // Verifikasi pesan penolakan & validasi muncul
    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Nominal wajib diisi'), findsOneWidget);
    expect(find.text('Simpan form kosong ditolak! Harap isi judul dan nominal.'), findsOneWidget);
    // Pastikan tetap berada di FormPage (tidak tersimpan)
    expect(find.text('Tambah Pengeluaran'), findsOneWidget);

    // Kembali ke HomePage
    await tester.pageBack();
    await tester.pumpAndSettle();

    // =========================================================================
    // Tambah data: Makan Siang (25000) dan Bensin (15000)
    // =========================================================================
    // Data 1: Makan Siang (Rp 25.000)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Judul'), 'Makan Siang');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nominal (Rp)'), '25000');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    // Data 2: Bensin (Rp 15.000)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Judul'), 'Bensin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nominal (Rp)'), '15000');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    // Total: 25.000 + 15.000 = Rp 40.000
    expect(find.text('Rp 40.000'), findsOneWidget);
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Bensin'), findsOneWidget);

    // =========================================================================
    // 2. UJI: Tutup aplikasi sepenuhnya lalu buka lagi, data harus masih ada
    // =========================================================================
    // Simulasikan app lifecycle detached (aplikasi ditutup sepenuhnya dari OS)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pumpAndSettle();

    // Hancurkan tree widget lama (aplikasi ditutup total dari memori)
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // Buka aplikasi kembali dari awal (OS status resumed)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Data harus tetap ada lengkap dengan totalnya
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Rp 40.000'), findsOneWidget);

    // =========================================================================
    // 3. UJI: Hapus Data via Tombol Hapus (Ikon Sampah) di List Item
    // =========================================================================
    final bensinFinder = find.ancestor(
      of: find.text('Bensin'),
      matching: find.byType(ListTile),
    );
    final deleteBensinBtn = find.descendant(
      of: bensinFinder,
      matching: find.byIcon(Icons.delete_outline),
    );
    await tester.tap(deleteBensinBtn);
    await tester.pumpAndSettle();

    // Konfirmasi dialog hapus
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Bensin'), findsNothing);
    expect(find.text('Rp 25.000'), findsWidgets);

    // =========================================================================
    // 4. UJI: Tutup aplikasi lagi dan buka kembali untuk cek persistensi setelah hapus
    // =========================================================================
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Makan Siang masih ada, Bensin tetap terhapus
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Bensin'), findsNothing);
    expect(find.text('Rp 25.000'), findsWidgets);

    // =========================================================================
    // 5. UJI: Hapus semua data via swipe, lalu tutup dan buka lagi
    // =========================================================================
    await tester.drag(find.text('Makan Siang'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);

    // Buka ulang aplikasi, kondisi kosong harus tetap tersimpan
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
  });
}
