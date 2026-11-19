import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class StorageService {
  static const _key = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final List<Expense> expenses = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          expenses.add(Expense.fromJson(item));
        } else if (item is Map) {
          expenses.add(Expense.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      debugPrint('Berhasil memuat ${expenses.length} data pengeluaran dari SharedPreferences.');
      return expenses;
    } catch (e, stack) {
      debugPrint('Error saat memuat pengeluaran: $e\n$stack');
      return [];
    }
  }

  Future<bool> saveExpenses(List<Expense> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = expenses.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);
      final success = await prefs.setString(_key, jsonStr);
      debugPrint('Berhasil menyimpan ${expenses.length} data pengeluaran ke SharedPreferences (success: $success).');
      return success;
    } catch (e, stack) {
      debugPrint('Error saat menyimpan pengeluaran: $e\n$stack');
      return false;
    }
  }
}
