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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _storage = StorageService();
  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('dd/MM/yyyy');
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Memastikan data langsung tersimpan saat aplikasi diminimalkan / ditutup
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _storage.saveExpenses(_expenses);
    }
  }

  Future<void> _load() async {
    final data = await _storage.loadExpenses();
    if (!mounted) return;
    setState(() {
      _expenses = data;
      _isLoading = false;
    });
  }

  int get _total => _expenses.fold(0, (sum, e) => sum + e.amount);

  Future<void> _openForm([Expense? existing]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormPage(expense: existing)),
    );
    if (result == null || !mounted) return;

    if (result == 'delete' && existing != null) {
      await _delete(existing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "${existing.title}" berhasil dihapus')),
        );
      }
      return;
    }

    if (result is Expense) {
      final isEdit = existing != null;
      setState(() {
        final i = _expenses.indexWhere((e) => e.id == result.id);
        if (i >= 0) {
          _expenses[i] = result;
        } else {
          _expenses.insert(0, result);
        }
      });
      await _storage.saveExpenses(_expenses);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Data "${result.title}" berhasil diperbarui'
                  : 'Data "${result.title}" berhasil disimpan',
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(Expense e) async {
    setState(() => _expenses.removeWhere((x) => x.id == e.id));
    await _storage.saveExpenses(_expenses);
  }

  Future<void> _confirmDelete(Expense e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Apakah Anda yakin ingin menghapus "${e.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _delete(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "${e.title}" berhasil dihapus')),
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text('Apakah Anda yakin ingin menghapus semua pengeluaran?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _expenses.clear());
      await _storage.saveExpenses(_expenses);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data berhasil dihapus')),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Belanja':
        return Icons.shopping_bag;
      case 'Hiburan':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance_wallet),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pencatat Pengeluaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_expenses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Hapus Semua Data',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pengeluaran',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _rupiah.format(_total),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola keuangan harian dengan lebih teratur',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/app_logo.png',
                              width: 64,
                              height: 64,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada pengeluaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tekan tombol + di bawah untuk mencatat pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
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
                              onDismissed: (_) {
                                _delete(e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Data "${e.title}" berhasil dihapus'),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade50,
                                  child: Icon(
                                    _getCategoryIcon(e.category),
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                title: Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                subtitle: Text(
                                  '${e.category} • ${_dateFmt.format(e.date)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _rupiah.format(e.amount),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.teal.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Hapus data',
                                      onPressed: () => _confirmDelete(e),
                                    ),
                                  ],
                                ),
                                onTap: () => _openForm(e),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
