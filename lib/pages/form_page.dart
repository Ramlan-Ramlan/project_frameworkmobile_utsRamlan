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
    final isTitleEmpty = _titleCtrl.text.trim().isEmpty;
    final isAmountEmpty = _amountCtrl.text.trim().isEmpty;

    if (isTitleEmpty && isAmountEmpty) {
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan form kosong ditolak! Harap isi judul dan nominal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan ditolak! Harap periksa kembali isian form.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Yakin ingin menghapus "${widget.expense!.title}"?'),
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
    if (confirm == true && mounted) {
      Navigator.pop(context, 'delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus data',
              onPressed: _deleteExpense,
            ),
        ],
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
                  prefixIcon: Icon(Icons.edit_note),
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
                  prefixIcon: Icon(Icons.monetization_on_outlined),
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
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
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
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text(
                    'Hapus Pengeluaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _deleteExpense,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
