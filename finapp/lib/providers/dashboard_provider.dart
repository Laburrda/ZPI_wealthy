import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expenses_provider.dart';

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

  UpcomingPayment copyWith({String? title, double? amount, DateTime? dueDate, String? icon}) {
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

// ── Notifier: budżet ──────────────────────────────────────────────────────────

class FinancialSummaryNotifier extends Notifier<FinancialSummary> {
  @override
  FinancialSummary build() {
    final expenses = ref.watch(expensesProvider);
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    return FinancialSummary(
      savings: 24500.00,
      investments: 18750.00,
      expensesThisMonth: totalExpenses,
      budgetLimit: 3000.00,
    );
  }

  void setBudgetLimit(double newLimit) {
    state = state.copyWith(budgetLimit: newLimit);
  }
}

final financialSummaryProvider =
    NotifierProvider<FinancialSummaryNotifier, FinancialSummary>(
        FinancialSummaryNotifier.new);

// ── Notifier: płatności ───────────────────────────────────────────────────────

class UpcomingPaymentsNotifier extends Notifier<List<UpcomingPayment>> {
  @override
  List<UpcomingPayment> build() {
    final now = DateTime.now();
    return [
      UpcomingPayment(id: '1', title: 'Czynsz',   amount: 1500.00, dueDate: DateTime(now.year, now.month + 1, 1),        icon: 'Mieszkanie'),
      UpcomingPayment(id: '2', title: 'Netflix',  amount: 43.00,   dueDate: DateTime(now.year, now.month, now.day + 3),  icon: 'Rozrywka'),
      UpcomingPayment(id: '3', title: 'Siłownia', amount: 99.00,   dueDate: DateTime(now.year, now.month, now.day + 5),  icon: 'Zdrowie'),
      UpcomingPayment(id: '4', title: 'Spotify',  amount: 23.99,   dueDate: DateTime(now.year, now.month, now.day + 7),  icon: 'Rozrywka'),
      UpcomingPayment(id: '5', title: 'Prąd',     amount: 180.00,  dueDate: DateTime(now.year, now.month, now.day + 12), icon: 'Mieszkanie'),
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
        UpcomingPaymentsNotifier.new);

// ── Provider: alerty (tylko do odczytu) ──────────────────────────────────────

final dashboardAlertsProvider = Provider<List<DashboardAlert>>((ref) {
  final summary = ref.watch(financialSummaryProvider);
  final payments = ref.watch(upcomingPaymentsProvider);
  final byCategory = ref.watch(expensesByCategoryProvider);

  final alerts = <DashboardAlert>[];

  if (summary.budgetUsedPercent >= 1.0) {
    alerts.add(DashboardAlert(message: 'Przekroczono miesięczny limit budżetu!', type: AlertType.danger));
  } else if (summary.budgetUsedPercent >= 0.8) {
    alerts.add(DashboardAlert(
      message: 'Wykorzystano ${(summary.budgetUsedPercent * 100).toStringAsFixed(0)}% miesięcznego budżetu.',
      type: AlertType.warning,
    ));
  }

  for (final p in payments.where((p) => p.daysLeft <= 3)) {
    alerts.add(DashboardAlert(
      message: '${p.title} (${p.amount.toStringAsFixed(0)} PLN) płatne ${p.daysLeft == 0 ? 'dziś' : 'za ${p.daysLeft} dni'}!',
      type: AlertType.danger,
    ));
  }

  byCategory.forEach((cat, amount) {
    if (amount > 500) {
      alerts.add(DashboardAlert(
        message: 'Wysokie wydatki na $cat: ${amount.toStringAsFixed(0)} PLN w tym miesiącu.',
        type: AlertType.info,
      ));
    }
  });

  return alerts;
});