import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expenses_provider.dart';

const _categoryColors = {
  'Jedzenie':   Color(0xFF26C6DA),
  'Transport':  Color(0xFFAB47BC),
  'Rozrywka':   Color(0xFFFF7043),
  'Mieszkanie': Color(0xFF66BB6A),
  'Zdrowie':    Color(0xFFFFCA28),
  'Zakupy':     Color(0xFFEC407A),
};

const _categoryList = ['Jedzenie', 'Transport', 'Rozrywka', 'Mieszkanie', 'Zdrowie', 'Zakupy'];

Color _colorFor(String category) => _categoryColors[category] ?? Colors.white54;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary  = ref.watch(financialSummaryProvider);
    final alerts   = ref.watch(dashboardAlertsProvider);
    final payments = ref.watch(upcomingPaymentsProvider);
    final byCategory = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WealthSummaryCard(summary: summary),
          const SizedBox(height: 16),
          _BudgetProgressCard(summary: summary),
          const SizedBox(height: 16),
          if (alerts.isNotEmpty) ...[
            _AlertsSection(alerts: alerts),
            const SizedBox(height: 16),
          ],
          _ExpensesPieCard(byCategory: byCategory, total: summary.expensesThisMonth),
          const SizedBox(height: 16),
          _UpcomingPaymentsCard(payments: payments),
        ],
      ),
    );
  }
}

// ── Karta łącznego majątku ────────────────────────────────────────────────────

class _WealthSummaryCard extends StatelessWidget {
  final FinancialSummary summary;
  const _WealthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A3A), Color(0xFF0D1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Łączny majątek', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '${summary.totalWealth.toStringAsFixed(2)} PLN',
            style: const TextStyle(color: Colors.tealAccent, fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _WealthTile(label: 'Oszczędności', amount: summary.savings,     color: const Color(0xFF66BB6A))),
            const SizedBox(width: 12),
            Expanded(child: _WealthTile(label: 'Inwestycje',   amount: summary.investments, color: const Color(0xFFAB47BC))),
          ]),
        ],
      ),
    );
  }
}

class _WealthTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _WealthTile({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${amount.toStringAsFixed(0)} PLN',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Pasek budżetu (klikalny) ──────────────────────────────────────────────────

class _BudgetProgressCard extends ConsumerWidget {
  final FinancialSummary summary;
  const _BudgetProgressCard({required this.summary});

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: summary.budgetLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Ustaw limit budżetu', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Limit miesięczny (PLN)',
            labelStyle: const TextStyle(color: Colors.white60),
            suffixText: 'PLN',
            suffixStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.tealAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                ref.read(financialSummaryProvider.notifier).setBudgetLimit(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = summary.budgetUsedPercent.clamp(0.0, 1.0);
    final color = pct >= 1.0 ? Colors.redAccent : pct >= 0.8 ? Colors.orangeAccent : Colors.tealAccent;

    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budżet miesięczny', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(children: [
                  Text('${summary.expensesThisMonth.toStringAsFixed(0)} / ${summary.budgetLimit.toStringAsFixed(0)} PLN',
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, color: Colors.white38, size: 16),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pozostało ${(summary.budgetLimit - summary.expensesThisMonth).toStringAsFixed(2)} PLN · dotknij aby zmienić limit',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alerty ────────────────────────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  final List<DashboardAlert> alerts;
  const _AlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alerty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...alerts.map((a) => _AlertTile(alert: a)),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final DashboardAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (alert.type) {
      AlertType.danger  => (Colors.redAccent,    Icons.warning_rounded),
      AlertType.warning => (Colors.orangeAccent, Icons.info_outline),
      AlertType.info    => (Colors.tealAccent,   Icons.lightbulb_outline),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(alert.message, style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}

// ── Mini pie chart wydatków ───────────────────────────────────────────────────

class _ExpensesPieCard extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  const _ExpensesPieCard({required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final sections = byCategory.entries.map((e) => PieChartSectionData(
      value: e.value, color: _colorFor(e.key), title: '', radius: 40,
    )).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wydatki w tym miesiącu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(
              height: 120, width: 120,
              child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 35, sectionsSpace: 2)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: byCategory.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: _colorFor(e.key), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    Text('${e.value.toStringAsFixed(0)} PLN', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                )).toList(),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Nadchodzące płatności (klikalne) ─────────────────────────────────────────

class _UpcomingPaymentsCard extends ConsumerWidget {
  final List<UpcomingPayment> payments;
  const _UpcomingPaymentsCard({required this.payments});

  void _showManageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentsManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showManageSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nadchodzące płatności',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Row(children: [
                  Text('zarządzaj', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.edit, color: Colors.white38, size: 16),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            ...payments.map((p) => _PaymentTile(payment: p)),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final UpcomingPayment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isUrgent = payment.daysLeft <= 3;
    final color = isUrgent ? Colors.redAccent : Colors.white54;
    final daysLabel = payment.daysLeft == 0 ? 'dziś'
        : payment.daysLeft == 1 ? 'jutro'
        : 'za ${payment.daysLeft} dni';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.redAccent.withOpacity(0.08) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? Colors.redAccent.withOpacity(0.4) : Colors.transparent),
      ),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: _colorFor(payment.icon), shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
            Text(daysLabel, style: TextStyle(color: color, fontSize: 12)),
          ],
        )),
        Text('${payment.amount.toStringAsFixed(2)} PLN',
            style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }
}

// ── Bottom sheet: zarządzanie płatnościami ────────────────────────────────────

class _PaymentsManagerSheet extends ConsumerWidget {
  const _PaymentsManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(upcomingPaymentsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Regularne płatności',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton.icon(
                  onPressed: () => _showEditDialog(context, ref, null),
                  icon: const Icon(Icons.add, color: Colors.tealAccent, size: 18),
                  label: const Text('Dodaj', style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: payments.length,
                itemBuilder: (_, i) {
                  final p = payments[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: _colorFor(p.icon), shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          Text('${p.amount.toStringAsFixed(2)} PLN · ${p.dueDate.day}.${p.dueDate.month.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                        onPressed: () => _showEditDialog(context, ref, p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => ref.read(upcomingPaymentsProvider.notifier).remove(p.id),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, UpcomingPayment? existing) {
    final titleCtrl   = TextEditingController(text: existing?.title ?? '');
    final amountCtrl  = TextEditingController(text: existing?.amount.toStringAsFixed(2) ?? '');
    DateTime selectedDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String selectedCategory = existing?.icon ?? 'Mieszkanie';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(existing == null ? 'Dodaj płatność' : 'Edytuj płatność',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleCtrl,  'Nazwa',  Icons.label_outline),
                const SizedBox(height: 12),
                _dialogField(amountCtrl, 'Kwota (PLN)', Icons.payments_outlined,
                    inputType: TextInputType.number),
                const SizedBox(height: 12),
                // Wybór kategorii
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogDecoration('Kategoria', Icons.category_outlined),
                  items: _categoryList.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: _colorFor(c), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(c),
                    ]),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                // Wybór daty
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: Colors.tealAccent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.tealAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${selectedDate.day}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (titleCtrl.text.isEmpty || amount == null || amount <= 0) return;

                final payment = UpcomingPayment(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  amount: amount,
                  dueDate: selectedDate,
                  icon: selectedCategory,
                );

                if (existing == null) {
                  ref.read(upcomingPaymentsProvider.notifier).add(payment);
                } else {
                  ref.read(upcomingPaymentsProvider.notifier).update(payment);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Dodaj' : 'Zapisz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogDecoration(label, icon),
    );
  }

  InputDecoration _dialogDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.tealAccent)),
    );
  }
}