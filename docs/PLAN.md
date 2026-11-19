# Rencana Implementasi: Pencatat Pengeluaran Harian (Flutter)

Spesifikasi: `docs/superpowers/specs/2026-11-12-expense-tracker-flutter-design.md`

Urutan dibuat supaya aplikasi bisa dijalankan setelah setiap tugas. Jalankan `flutter run` di akhir tiap tugas untuk memastikan tidak ada error sebelum lanjut.

## Tugas 1: Buat proyek dan tambah package

```bash
flutter create expense_tracker
cd expense_tracker
flutter pub add shared_preferences intl
flutter run
```

Hasil: aplikasi counter bawaan berjalan di emulator atau HP.

## Tugas 2: Model `Expense`

Buat `lib/models/expense.dart`:

```dart
class Expense {
  final String id;
  final String title;
  final int amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: json['amount'] as int,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}
```

## Tugas 3: `StorageService`

Buat `lib/services/storage.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class StorageService {
  static const _key = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }
}
```

## Tugas 4: `main.dart`

Ganti seluruh isi `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatat Pengeluaran',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
```

File ini baru bisa dijalankan setelah Tugas 5 dan 6 selesai (`HomePage` dan `FormPage` belum ada).

## Tugas 5: `FormPage`

Buat `lib/pages/form_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

const kCategories = ['Makanan', 'Transport', 'Belanja', 'Hiburan', 'Lainnya'];

class FormPage extends StatefulWidget {
  final Expense? expense;
  const FormPage({super.key, this.expense});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late String _category;
  late DateTime _date;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(text: e?.amount.toString() ?? '');
    _category = e?.category ?? kCategories.first;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final result = Expense(
      id: widget.expense?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: int.parse(_amountCtrl.text.trim()),
      category: _category,
      date: _date,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Nominal harus berupa angka';
                  if (n <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Tanggal'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Tugas 6: `HomePage`

Buat `lib/pages/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage.dart';
import 'form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = StorageService();
  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('dd/MM/yyyy');
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadExpenses();
    if (!mounted) return;
    setState(() => _expenses = data);
  }

  int get _total => _expenses.fold(0, (sum, e) => sum + e.amount);

  Future<void> _openForm([Expense? existing]) async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (_) => FormPage(expense: existing)),
    );
    if (result == null || !mounted) return;
    setState(() {
      final i = _expenses.indexWhere((e) => e.id == result.id);
      if (i >= 0) {
        _expenses[i] = result;
      } else {
        _expenses.insert(0, result);
      }
    });
    await _storage.saveExpenses(_expenses);
  }

  Future<void> _delete(Expense e) async {
    setState(() => _expenses.removeWhere((x) => x.id == e.id));
    await _storage.saveExpenses(_expenses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencatat Pengeluaran')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pengeluaran'),
                  Text(
                    _rupiah.format(_total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('Belum ada pengeluaran'))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, i) {
                      final e = _expenses[i];
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _delete(e),
                        child: ListTile(
                          title: Text(e.title),
                          subtitle: Text(
                            '${e.category} • ${_dateFmt.format(e.date)}',
                          ),
                          trailing: Text(_rupiah.format(e.amount)),
                          onTap: () => _openForm(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

## Tugas 7: Pengujian manual

- Tambah tiga data, cek total benar.
- Edit satu data, cek nilai dan total berubah.
- Geser satu data ke kiri untuk menghapus, cek total berkurang.
- Simpan form kosong, harus ditolak dengan pesan validasi.
- Isi nominal dengan huruf, harus ditolak.
- Tutup aplikasi sepenuhnya lalu buka lagi, data harus masih ada.
- Hapus semua data, harus tampil "Belum ada pengeluaran".

## Catatan

- Kode di atas belum pernah dijalankan karena Flutter tidak terpasang di lingkungan penyusunnya. Jika ada error saat `flutter run`, kirim pesan error-nya untuk diperbaiki.
- Jika `DropdownButtonFormField` menampilkan peringatan `value` deprecated pada versi Flutter terbaru, ganti `value:` menjadi `initialValue:`. Peringatan ini tidak menghentikan aplikasi.
- Jika nominal pernah tersimpan dengan format lama dan error saat dimuat, hapus data aplikasi di emulator (uninstall lalu install ulang).

