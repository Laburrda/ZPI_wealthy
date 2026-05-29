import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';

final expensesProvider = Provider<List<ExpenseModel>>((ref) {
  final now = DateTime.now();
  return [
    ExpenseModel(id: '1', title: 'Biedronka',       amount: 134.50, category: 'Jedzenie',     date: DateTime(now.year, now.month, 2)),
    ExpenseModel(id: '2', title: 'Żabka',            amount: 23.99,  category: 'Jedzenie',     date: DateTime(now.year, now.month, 5)),
    ExpenseModel(id: '3', title: 'Orlen',            amount: 210.00, category: 'Transport',    date: DateTime(now.year, now.month, 6)),
    ExpenseModel(id: '4', title: 'Netflix',          amount: 43.00,  category: 'Rozrywka',     date: DateTime(now.year, now.month, 7)),
    ExpenseModel(id: '5', title: 'Empik',            amount: 59.90,  category: 'Rozrywka',     date: DateTime(now.year, now.month, 9)),
    ExpenseModel(id: '6', title: 'Czynsz',           amount: 1500.00,category: 'Mieszkanie',   date: DateTime(now.year, now.month, 10)),
    ExpenseModel(id: '7', title: 'Prąd',             amount: 180.00, category: 'Mieszkanie',   date: DateTime(now.year, now.month, 11)),
    ExpenseModel(id: '8', title: 'Bolt',             amount: 34.00,  category: 'Transport',    date: DateTime(now.year, now.month, 14)),
    ExpenseModel(id: '9', title: 'Apteka',           amount: 67.30,  category: 'Zdrowie',      date: DateTime(now.year, now.month, 15)),
    ExpenseModel(id: '10', title: 'Siłownia',        amount: 99.00,  category: 'Zdrowie',      date: DateTime(now.year, now.month, 16)),
    ExpenseModel(id: '11', title: 'Lidl',            amount: 98.20,  category: 'Jedzenie',     date: DateTime(now.year, now.month, 18)),
    ExpenseModel(id: '12', title: 'Spotify',         amount: 23.99,  category: 'Rozrywka',     date: DateTime(now.year, now.month, 20)),
    ExpenseModel(id: '13', title: 'PKP Intercity',   amount: 89.00,  category: 'Transport',    date: DateTime(now.year, now.month, 22)),
    ExpenseModel(id: '14', title: 'Restauracja',     amount: 112.00, category: 'Jedzenie',     date: DateTime(now.year, now.month, 24)),
    ExpenseModel(id: '15', title: 'Allegro',         amount: 145.00, category: 'Zakupy',       date: DateTime(now.year, now.month, 25)),
  ];
});

// Pomocniczy provider — suma per kategoria
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final Map<String, double> result = {};
  for (final e in expenses) {
    result[e.category] = (result[e.category] ?? 0) + e.amount;
  }
  return result;
});