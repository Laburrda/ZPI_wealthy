import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart'; // Podpinamy nasz serwis!

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Asynchroniczny Notifier pobierający historię z Pythona
class ExpensesNotifier extends AsyncNotifier<List<ExpenseModel>> {
  @override
  Future<List<ExpenseModel>> build() async {
    final api = ref.read(apiServiceProvider);

    // Pobieramy dane z API
    final data = await api.fetchTransactions();

    // Mapujemy JSON z Pythona na Twojego ExpenseModel
    return data.map((json) {
      // 1. KULOODPORNA KATEGORIA
      // Sprawdzamy, czy Python przysłał obiekt (Map), czy zwykły tekst (String)
      String categoryName = 'Inne';
      if (json['category'] is Map) {
        categoryName = json['category']['name'] ?? 'Inne';
      } else if (json['category'] is String) {
        categoryName = json['category'];
      } else if (json['category_name'] is String) {
        categoryName = json['category_name'];
      }

      // 2. BEZPIECZNE ZWRACANIE
      return ExpenseModel(
        id:
            json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title:
            (json['description'] ?? json['title'] ?? json['name'] ?? 'Nieznana')
                .toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        category: categoryName,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
  }

  Future<void> deleteExpense(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      // 1. Usuwamy z bazy Pythona
      await api.deleteTransaction(id);

      // 2. Odświeżamy listę na ekranie
      ref.invalidateSelf();
    } catch (e) {
      print("Błąd usuwania: $e");
    }
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);

    // Wysyłamy do Pythona
    await api.addTransaction(data);

    // Odświeżamy listę – Riverpod sam pobierze zaktualizowane dane z bazy!
    ref.invalidateSelf();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<ExpenseModel>>(
      ExpensesNotifier.new,
    );

// Pomocniczy provider — suma per kategoria (teraz bezpieczny dla danych z sieci)
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);

  // Jesli mamy dane (zakończyło się ładowanie), to je przeliczamy
  return expensesAsync.maybeWhen(
    data: (expenses) {
      final Map<String, double> result = {};
      for (final e in expenses) {
        result[e.category] = (result[e.category] ?? 0) + e.amount;
      }
      return result;
    },
    // Jeśli ładuje się lub jest błąd, zwracamy pustą mapę
    orElse: () => {},
  );
});
// ── Pobieranie prawdziwych kategorii z backendu ──
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.fetchCategories();

  // Konwertujemy List<dynamic> z Pythona na listę bezpiecznych map (słowników)
  return List<Map<String, dynamic>>.from(data);
});
