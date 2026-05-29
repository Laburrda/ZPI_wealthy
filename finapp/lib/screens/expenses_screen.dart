import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expenses_provider.dart';
import '../models/expense_model.dart';

const _categoryColors = {
  'Jedzenie':   Color(0xFF26C6DA),
  'Transport':  Color(0xFFAB47BC),
  'Rozrywka':   Color(0xFFFF7043),
  'Mieszkanie': Color(0xFF66BB6A),
  'Zdrowie':    Color(0xFFFFCA28),
  'Zakupy':     Color(0xFFEC407A),
};

Color _colorFor(String category) =>
    _categoryColors[category] ?? Colors.white54;

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedCategory; // null = wszystkie

  void _toggleCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final byCategory = ref.watch(expensesByCategoryProvider);
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final filtered = _selectedCategory == null
        ? expenses
        : expenses.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryHeader(total: total, filtered: filtered, selectedCategory: _selectedCategory),
          const SizedBox(height: 20),
          _PieChartCard(
            byCategory: byCategory,
            total: total,
            selectedCategory: _selectedCategory,
            onSectionTap: _toggleCategory,
          ),
          const SizedBox(height: 20),
          _CategoryLegend(
            byCategory: byCategory,
            selectedCategory: _selectedCategory,
            onTap: _toggleCategory,
          ),
          const SizedBox(height: 20),
          _ExpenseList(expenses: filtered, selectedCategory: _selectedCategory),
        ],
      ),
    );
  }
}

// ── Nagłówek ─────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final double total;
  final List<ExpenseModel> filtered;
  final String? selectedCategory;
  const _SummaryHeader({required this.total, required this.filtered, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'stycznia','lutego','marca','kwietnia','maja','czerwca',
      'lipca','sierpnia','września','października','listopada','grudnia'
    ];
    final displayTotal = filtered.fold(0.0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wydatki — ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${displayTotal.toStringAsFixed(2)} PLN',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        if (selectedCategory != null)
          Text(
            'Filtr: $selectedCategory · dotknij ponownie aby wyczyścić',
            style: TextStyle(color: _colorFor(selectedCategory!), fontSize: 12),
          ),
      ],
    );
  }
}

// ── Pie chart ─────────────────────────────────────────────────────────────────

class _PieChartCard extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  final String? selectedCategory;
  final void Function(String) onSectionTap;

  const _PieChartCard({
    required this.byCategory,
    required this.total,
    required this.selectedCategory,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries.toList();

    final sections = entries.map((e) {
      final isSelected = selectedCategory == e.key;
      final isOther = selectedCategory != null && !isSelected;
      final pct = e.value / total * 100;

      return PieChartSectionData(
        value: e.value,
        color: _colorFor(e.key).withOpacity(isOther ? 0.3 : 1.0),
        title: isOther ? '' : '${pct.toStringAsFixed(0)}%',
        radius: isSelected ? 72 : 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Rozkład kategorii',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response?.touchedSection != null) {
                      final idx = response!.touchedSection!.touchedSectionIndex;
                      if (idx >= 0 && idx < entries.length) {
                        onSectionTap(entries[idx].key);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          if (selectedCategory != null) ...[
            const SizedBox(height: 12),
            Text(
              '${byCategory[selectedCategory]?.toStringAsFixed(2)} PLN na $selectedCategory',
              style: TextStyle(color: _colorFor(selectedCategory!), fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Legenda kategorii ─────────────────────────────────────────────────────────

class _CategoryLegend extends StatelessWidget {
  final Map<String, double> byCategory;
  final String? selectedCategory;
  final void Function(String) onTap;

  const _CategoryLegend({required this.byCategory, required this.selectedCategory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: byCategory.entries.map((e) {
        final isSelected = selectedCategory == e.key;
        final isOther = selectedCategory != null && !isSelected;

        return GestureDetector(
          onTap: () => onTap(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _colorFor(e.key).withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _colorFor(e.key) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: _colorFor(e.key).withOpacity(isOther ? 0.3 : 1.0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key}  ${e.value.toStringAsFixed(0)} PLN',
                  style: TextStyle(
                    color: isOther ? Colors.white30 : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Lista wydatków ────────────────────────────────────────────────────────────

class _ExpenseList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final String? selectedCategory;
  const _ExpenseList({required this.expenses, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedCategory == null ? 'Wszystkie transakcje' : 'Transakcje — $selectedCategory',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          const Center(
            child: Text('Brak wydatków', style: TextStyle(color: Colors.white38)),
          )
        else
          ...sorted.map((e) => _ExpenseTile(expense: e)),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: _colorFor(expense.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                Text(
                  '${expense.category} · ${expense.date.day}.${expense.date.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '-${expense.amount.toStringAsFixed(2)} PLN',
            style: TextStyle(
              color: _colorFor(expense.category),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}