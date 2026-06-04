import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expenses_provider.dart';
import '../services/api_service.dart'; // Dodany import API!
import 'savings_provider.dart'; // DODANE
import 'investments_provider.dart';

// Współdzielony provider dla ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── Modele ────────────────────────────────────────────────────────────────────

class UpcomingPayment {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String icon;

  UpcomingPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
  });

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;

  UpcomingPayment copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    String? icon,
  }) {
    return UpcomingPayment(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      icon: icon ?? this.icon,
    );
  }
}

class DashboardAlert {
  final String message;
  final AlertType type;
  DashboardAlert({required this.message, required this.type});
}

enum AlertType { warning, info, danger }

class FinancialSummary {
  final double savings;
  final double investments;
  final double expensesThisMonth;
  final double budgetLimit;

  FinancialSummary({
    required this.savings,
    required this.investments,
    required this.expensesThisMonth,
    required this.budgetLimit,
  });

  double get totalWealth => savings + investments;
  double get budgetUsedPercent => expensesThisMonth / budgetLimit;

  FinancialSummary copyWith({double? budgetLimit}) {
    return FinancialSummary(
      savings: savings,
      investments: investments,
      expensesThisMonth: expensesThisMonth,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }
}

// ── Notifier: PRAWDZIWY budżet z API ──────────────────────────────────────────

// ── Notifier: PRAWDZIWY budżet (Nasłuchuje innych providerów!) ────────────────

class FinancialSummaryNotifier extends AsyncNotifier<FinancialSummary> {
  @override
  Future<FinancialSummary> build() async {
    // Obserwujemy wydatki
    final expensesAsync = ref.watch(expensesProvider);
    final totalExpenses =
        expensesAsync.value?.fold(0.0, (s, e) => s + e.amount) ?? 0.0;

    // Obserwujemy Oszczędności (IKE, PPK, IKZE, Zwykłe)
    final savingsAsync = ref.watch(savingsProvider);
    final totalSavings =
        savingsAsync.value?.fold(0.0, (s, asset) => s + asset.value) ?? 0.0;

    // Obserwujemy Inwestycje (Giełda, Krypto)
    final investmentsAsync = ref.watch(investmentsProvider);
    final totalInvestments =
        investmentsAsync.value?.fold(0.0, (s, asset) => s + asset.value) ?? 0.0;

    return FinancialSummary(
      savings: totalSavings,
      investments: totalInvestments,
      expensesThisMonth: totalExpenses,
      budgetLimit: 3000.00, // Na razie limit na sztywno
    );
  }

  void setBudgetLimit(double newLimit) {
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(budgetLimit: newLimit));
    }
  }
}

final financialSummaryProvider =
    AsyncNotifierProvider<FinancialSummaryNotifier, FinancialSummary>(
      FinancialSummaryNotifier.new,
    );

// ── Notifier: płatności (Zostawiamy mocki póki nie mamy backendu na to) ────────

class UpcomingPaymentsNotifier extends Notifier<List<UpcomingPayment>> {
  @override
  List<UpcomingPayment> build() {
    final now = DateTime.now();
    return [
      UpcomingPayment(
        id: '1',
        title: 'Czynsz',
        amount: 1500.00,
        dueDate: DateTime(now.year, now.month + 1, 1),
        icon: 'Mieszkanie',
      ),
      UpcomingPayment(
        id: '2',
        title: 'Netflix',
        amount: 43.00,
        dueDate: DateTime(now.year, now.month, now.day + 3),
        icon: 'Rozrywka',
      ),
      UpcomingPayment(
        id: '3',
        title: 'Siłownia',
        amount: 99.00,
        dueDate: DateTime(now.year, now.month, now.day + 5),
        icon: 'Zdrowie',
      ),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void update(UpcomingPayment updated) {
    state = state.map((p) => p.id == updated.id ? updated : p).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void add(UpcomingPayment payment) {
    state = [...state, payment]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final upcomingPaymentsProvider =
    NotifierProvider<UpcomingPaymentsNotifier, List<UpcomingPayment>>(
      UpcomingPaymentsNotifier.new,
    );

// ── Provider: alerty ─────────────────────────────────────────────────────────

final dashboardAlertsProvider = Provider<List<DashboardAlert>>((ref) {
  final summaryAsync = ref.watch(financialSummaryProvider);
  final payments = ref.watch(upcomingPaymentsProvider);
  final byCategory = ref.watch(expensesByCategoryProvider);

  final alerts = <DashboardAlert>[];

  // System alertów budżetu działa tylko gdy pobierzemy pomyślnie dane z API
  if (summaryAsync.value != null) {
    final summary = summaryAsync.value!;
    if (summary.budgetUsedPercent >= 1.0) {
      alerts.add(
        DashboardAlert(
          message: 'Przekroczono miesięczny limit budżetu!',
          type: AlertType.danger,
        ),
      );
    } else if (summary.budgetUsedPercent >= 0.8) {
      alerts.add(
        DashboardAlert(
          message:
              'Wykorzystano ${(summary.budgetUsedPercent * 100).toStringAsFixed(0)}% miesięcznego budżetu.',
          type: AlertType.warning,
        ),
      );
    }
  }

  for (final p in payments.where((p) => p.daysLeft <= 3)) {
    alerts.add(
      DashboardAlert(
        message:
            '${p.title} (${p.amount.toStringAsFixed(0)} PLN) płatne ${p.daysLeft == 0 ? 'dziś' : 'za ${p.daysLeft} dni'}!',
        type: AlertType.danger,
      ),
    );
  }

  byCategory.forEach((cat, amount) {
    if (amount > 500) {
      alerts.add(
        DashboardAlert(
          message:
              'Wysokie wydatki na $cat: ${amount.toStringAsFixed(0)} PLN w tym miesiącu.',
          type: AlertType.info,
        ),
      );
    }
  });

  return alerts;
});
