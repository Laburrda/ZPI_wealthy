// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../providers/expenses_provider.dart';
// import '../models/expense_model.dart';

// const _categoryColors = {
//   'Jedzenie': Color(0xFF26C6DA),
//   'Transport': Color(0xFFAB47BC),
//   'Rozrywka': Color(0xFFFF7043),
//   'Mieszkanie': Color(0xFF66BB6A),
//   'Zdrowie': Color(0xFFFFCA28),
//   'Zakupy': Color(0xFFEC407A),
// };

// Color _colorFor(String category) => _categoryColors[category] ?? Colors.white54;

// class ExpensesScreen extends ConsumerStatefulWidget {
//   const ExpensesScreen({super.key});

//   @override
//   ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
// }

// class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
//   String? _selectedCategory; // null = wszystkie

//   void _toggleCategory(String category) {
//     setState(() {
//       _selectedCategory = _selectedCategory == category ? null : category;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Teraz to jest asynchroniczne!
//     final expensesAsync = ref.watch(expensesProvider);
//     final byCategory = ref.watch(expensesByCategoryProvider);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: expensesAsync.when(
//         loading: () => const Center(
//           child: CircularProgressIndicator(color: Colors.tealAccent),
//         ),
//         error: (error, stack) => Center(
//           child: Text(
//             'Błąd pobierania historii transakcji: $error',
//             style: const TextStyle(color: Colors.redAccent),
//           ),
//         ),
//         data: (expenses) {
//           // Cała Twoja logika po pomyślnym załadowaniu danych!
//           final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

//           final filtered = _selectedCategory == null
//               ? expenses
//               : expenses.where((e) => e.category == _selectedCategory).toList();

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               _SummaryHeader(
//                 total: total,
//                 filtered: filtered,
//                 selectedCategory: _selectedCategory,
//               ),
//               const SizedBox(height: 20),
//               _PieChartCard(
//                 byCategory: byCategory,
//                 total: total,
//                 selectedCategory: _selectedCategory,
//                 onSectionTap: _toggleCategory,
//               ),
//               const SizedBox(height: 20),
//               _CategoryLegend(
//                 byCategory: byCategory,
//                 selectedCategory: _selectedCategory,
//                 onTap: _toggleCategory,
//               ),
//               const SizedBox(height: 20),
//               _ExpenseList(
//                 expenses: filtered,
//                 selectedCategory: _selectedCategory,
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Nagłówek ─────────────────────────────────────────────────────────────────

// class _SummaryHeader extends StatelessWidget {
//   final double total;
//   final List<ExpenseModel> filtered;
//   final String? selectedCategory;
//   const _SummaryHeader({
//     required this.total,
//     required this.filtered,
//     required this.selectedCategory,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final months = [
//       'stycznia',
//       'lutego',
//       'marca',
//       'kwietnia',
//       'maja',
//       'czerwca',
//       'lipca',
//       'sierpnia',
//       'września',
//       'października',
//       'listopada',
//       'grudnia',
//     ];
//     final displayTotal = filtered.fold(0.0, (s, e) => s + e.amount);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Wydatki — ${months[now.month - 1]} ${now.year}',
//           style: const TextStyle(color: Colors.white70, fontSize: 14),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           '${displayTotal.toStringAsFixed(2)} PLN',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         if (selectedCategory != null)
//           Text(
//             'Filtr: $selectedCategory · dotknij ponownie aby wyczyścić',
//             style: TextStyle(color: _colorFor(selectedCategory!), fontSize: 12),
//           ),
//       ],
//     );
//   }
// }

// // ── Pie chart ─────────────────────────────────────────────────────────────────

// class _PieChartCard extends StatelessWidget {
//   final Map<String, double> byCategory;
//   final double total;
//   final String? selectedCategory;
//   final void Function(String) onSectionTap;

//   const _PieChartCard({
//     required this.byCategory,
//     required this.total,
//     required this.selectedCategory,
//     required this.onSectionTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final entries = byCategory.entries.toList();

//     final sections = entries.map((e) {
//       final isSelected = selectedCategory == e.key;
//       final isOther = selectedCategory != null && !isSelected;
//       final pct = e.value / total * 100;

//       return PieChartSectionData(
//         value: e.value,
//         color: _colorFor(e.key).withOpacity(isOther ? 0.3 : 1.0),
//         title: isOther ? '' : '${pct.toStringAsFixed(0)}%',
//         radius: isSelected ? 72 : 60,
//         titleStyle: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       );
//     }).toList();

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white10,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             'Rozkład kategorii',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 200,
//             child: PieChart(
//               PieChartData(
//                 sections: sections,
//                 centerSpaceRadius: 50,
//                 sectionsSpace: 3,
//                 pieTouchData: PieTouchData(
//                   touchCallback: (event, response) {
//                     if (event is FlTapUpEvent &&
//                         response?.touchedSection != null) {
//                       final idx = response!.touchedSection!.touchedSectionIndex;
//                       if (idx >= 0 && idx < entries.length) {
//                         onSectionTap(entries[idx].key);
//                       }
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ),
//           if (selectedCategory != null) ...[
//             const SizedBox(height: 12),
//             Text(
//               '${byCategory[selectedCategory]?.toStringAsFixed(2)} PLN na $selectedCategory',
//               style: TextStyle(
//                 color: _colorFor(selectedCategory!),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ── Legenda kategorii ─────────────────────────────────────────────────────────

// class _CategoryLegend extends StatelessWidget {
//   final Map<String, double> byCategory;
//   final String? selectedCategory;
//   final void Function(String) onTap;

//   const _CategoryLegend({
//     required this.byCategory,
//     required this.selectedCategory,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: byCategory.entries.map((e) {
//         final isSelected = selectedCategory == e.key;
//         final isOther = selectedCategory != null && !isSelected;

//         return GestureDetector(
//           onTap: () => onTap(e.key),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? _colorFor(e.key).withOpacity(0.2)
//                   : Colors.white10,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isSelected ? _colorFor(e.key) : Colors.transparent,
//                 width: 1.5,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: _colorFor(e.key).withOpacity(isOther ? 0.3 : 1.0),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   '${e.key}  ${e.value.toStringAsFixed(0)} PLN',
//                   style: TextStyle(
//                     color: isOther ? Colors.white30 : Colors.white70,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// // ── Lista wydatków ────────────────────────────────────────────────────────────

// class _ExpenseList extends StatelessWidget {
//   final List<ExpenseModel> expenses;
//   final String? selectedCategory;
//   const _ExpenseList({required this.expenses, required this.selectedCategory});

//   @override
//   Widget build(BuildContext context) {
//     final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           selectedCategory == null
//               ? 'Wszystkie transakcje'
//               : 'Transakcje — $selectedCategory',
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 12),
//         if (sorted.isEmpty)
//           const Center(
//             child: Text(
//               'Brak wydatków',
//               style: TextStyle(color: Colors.white38),
//             ),
//           )
//         else
//           ...sorted.map((e) => _ExpenseTile(expense: e)),
//       ],
//     );
//   }
// }

// class _ExpenseTile extends StatelessWidget {
//   final ExpenseModel expense;
//   const _ExpenseTile({required this.expense});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white10,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 10,
//             height: 10,
//             decoration: BoxDecoration(
//               color: _colorFor(expense.category),
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   expense.title,
//                   style: const TextStyle(color: Colors.white, fontSize: 15),
//                 ),
//                 Text(
//                   '${expense.category} · ${expense.date.day}.${expense.date.month.toString().padLeft(2, '0')}',
//                   style: const TextStyle(color: Colors.white54, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             '-${expense.amount.toStringAsFixed(2)} PLN',
//             style: TextStyle(
//               color: _colorFor(expense.category),
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// // ── Formularz dodawania nowej transakcji ──────────────────────────────────────

// class _AddExpenseSheet extends ConsumerStatefulWidget {
//   const _AddExpenseSheet();

//   @override
//   ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
// }

// class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
//   final _descCtrl = TextEditingController();
//   final _amountCtrl = TextEditingController();
//   String _selectedCategory = 'Jedzenie'; // Domyślna kategoria
//   DateTime _selectedDate = DateTime.now();
//   bool _isLoading = false;

//   final List<String> _categories = [
//     'Jedzenie', 'Transport', 'Rozrywka', 'Mieszkanie', 'Zdrowie', 'Zakupy', 'Inne'
//   ];

//   Future<void> _submit() async {
//     final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
//     if (amount == null || amount <= 0 || _descCtrl.text.isEmpty) return;

//     setState(() => _isLoading = true);

//     try {
//       // Paczka dla Twojego backendu (dopasuj klucze, jeśli FastAPI oczekuje innych!)
//       final newTx = {
//         "description": _descCtrl.text,
//         "amount": amount,
//         "category": _selectedCategory,
//         "date": _selectedDate.toIso8601String(),
//         // "type": "expense" <-- Odkomentuj, jeśli Twój Python tego wymaga
//       };

//       await ref.read(expensesProvider.notifier).addExpense(newTx);

//       if (mounted) Navigator.pop(context); // Zamykamy formularz po sukcesie
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: Colors.redAccent),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Odsuwamy formularz, żeby klawiatura go nie zasłaniała
//     final bottomInset = MediaQuery.of(context).viewInsets.bottom;

//     return Padding(
//       padding: EdgeInsets.only(left: 20, right: 20, bottom: bottomInset + 20, top: 20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const Text('Dodaj wydatek', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 16),

//           TextField(
//             controller: _descCtrl,
//             style: const TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               labelText: 'Opis (np. Biedronka)', labelStyle: const TextStyle(color: Colors.white54),
//               filled: true, fillColor: Colors.white10,
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//             ),
//           ),
//           const SizedBox(height: 12),

//           TextField(
//             controller: _amountCtrl,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             style: const TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               labelText: 'Kwota (PLN)', labelStyle: const TextStyle(color: Colors.white54),
//               filled: true, fillColor: Colors.white10,
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//             ),
//           ),
//           const SizedBox(height: 12),

//           DropdownButtonFormField<String>(
//             value: _selectedCategory,
//             dropdownColor: const Color(0xFF2A2A2A),
//             style: const TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               labelText: 'Kategoria', labelStyle: const TextStyle(color: Colors.white54),
//               filled: true, fillColor: Colors.white10,
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//             ),
//             items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//             onChanged: (val) => setState(() => _selectedCategory = val!),
//           ),
//           const SizedBox(height: 24),

//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.tealAccent, foregroundColor: Colors.black,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             onPressed: _isLoading ? null : _submit,
//             child: _isLoading
//                 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
//                 : const Text('Zapisz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expenses_provider.dart';
import '../models/expense_model.dart';

const _categoryColors = {
  'Jedzenie': Color(0xFF26C6DA),
  'Transport': Color(0xFFAB47BC),
  'Rozrywka': Color(0xFFFF7043),
  'Mieszkanie': Color(0xFF66BB6A),
  'Zdrowie': Color(0xFFFFCA28),
  'Zakupy': Color(0xFFEC407A),
  'Inne': Color(0xFF9E9E9E), // Dodany kolor dla "Inne"
};

Color _colorFor(String category) => _categoryColors[category] ?? Colors.white54;

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
    // Teraz to jest asynchroniczne! (AsyncValue)
    final expensesAsync = ref.watch(expensesProvider);
    final byCategory = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ── PRZYCISK DODAWANIA WYDATKU ──
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1E1E1E),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => const _AddExpenseSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),

      // ── WIDOK GŁÓWNY (Z PASKIEM ŁADOWANIA) ──
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Błąd pobierania historii transakcji:\n$error',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (expenses) {
          final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

          final filtered = _selectedCategory == null
              ? expenses
              : expenses.where((e) => e.category == _selectedCategory).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryHeader(
                total: total,
                filtered: filtered,
                selectedCategory: _selectedCategory,
              ),
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
              _ExpenseList(
                expenses: filtered,
                selectedCategory: _selectedCategory,
              ),
              const SizedBox(
                height: 80,
              ), // Dodatkowy margines na dole, żeby przycisk nie zasłaniał listy
            ],
          );
        },
      ),
    );
  }
}

// ── Nagłówek ─────────────────────────────────────────────────────────────────

// ── Nagłówek ─────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final double total;
  final List<ExpenseModel> filtered;
  final String? selectedCategory;
  const _SummaryHeader({
    required this.total,
    required this.filtered,
    required this.selectedCategory,
  });

  // Funkcja dodająca spacje jako separatory tysięcy i zachowująca grosze
  String _formatCurrency(double amount) {
    String amountStr = amount.toStringAsFixed(2);
    List<String> parts = amountStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ', // Dodajemy spację (lub zmień na przecinek ',')
    );
    return '$formattedInteger.$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia',
    ];
    final displayTotal = filtered.fold(0.0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wydatki — ${now.day} ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(displayTotal)} PLN', // ZASTOSOWANA FUNKCJA
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
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
    if (total == 0 || byCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Brak danych do wykresu',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

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
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
          if (selectedCategory != null &&
              byCategory.containsKey(selectedCategory)) ...[
            const SizedBox(height: 12),
            Text(
              '${byCategory[selectedCategory]?.toStringAsFixed(2)} PLN na $selectedCategory',
              style: TextStyle(
                color: _colorFor(selectedCategory!),
                fontWeight: FontWeight.bold,
              ),
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

  const _CategoryLegend({
    required this.byCategory,
    required this.selectedCategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) return const SizedBox.shrink();

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
              color: isSelected
                  ? _colorFor(e.key).withOpacity(0.2)
                  : Colors.white10,
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
                  width: 12,
                  height: 12,
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
          selectedCategory == null
              ? 'Wszystkie transakcje'
              : 'Transakcje — $selectedCategory',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Brak wydatków. Dodaj nowy używając przycisku +',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          ...sorted.map((e) => _ExpenseTile(expense: e)),
      ],
    );
  }
}

// Zmienione na ConsumerWidget, by mieć dostęp do ref
class _ExpenseTile extends ConsumerWidget {
  final ExpenseModel expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            width: 10,
            height: 10,
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
                Text(
                  expense.title,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
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
          // NOWE: Przycisk usuwania
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () {
              ref.read(expensesProvider.notifier).deleteExpense(expense.id);
            },
          ),
        ],
      ),
    );
  }
}

// ── Formularz dodawania nowej transakcji (Bottom Sheet) ───────────────────────

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int? _selectedCategoryId; // TERAZ PRZECHOWUJEMY ID KATEGORII (np. 1, 2, 3...)
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _submit() async {
    final amountText = _amountCtrl.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null ||
        amount <= 0 ||
        _descCtrl.text.isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wypełnij wszystkie pola poprawnie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Paczka w 100% zgodna z TransactionCreate w FastAPI
      final newTx = {
        "transaction_type": "expense",
        "amount": amount,
        "transaction_date": _selectedDate.toIso8601String().split('T')[0],
        "description": _descCtrl.text,
        "category_id": _selectedCategoryId, // WYSYŁAMY PRAWDZIWE ID KATEGORII!
      };

      await ref.read(expensesProvider.notifier).addExpense(newTx);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // NASZ NOWY PROVIDER KATEGORII:
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dodaj wydatek',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Opis (np. Biedronka)',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Kwota (PLN)',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // INTELIGENTNY DROPDOWN - czeka na dane z backendu
          categoriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
            error: (e, st) => Text(
              'Błąd ładowania kategorii: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
            data: (categories) {
              // Ustaw domyślną pierwszą kategorię na liście, jeśli żadna nie jest wybrana
              if (_selectedCategoryId == null && categories.isNotEmpty) {
                Future.microtask(
                  () => setState(
                    () => _selectedCategoryId = categories.first['id'] as int,
                  ),
                );
              }

              return DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Kategoria',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name'].toString()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              );
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Zapisz',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
