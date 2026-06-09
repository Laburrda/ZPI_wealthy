import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Dodany import do wykresów
import '../providers/investments_provider.dart';
import '../widgets/asset_card.dart';
import '../models/asset_model.dart'; // Import modelu zasobu (potrzebny do edycji)
import 'add_asset_screen.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  // Kolory używane na wykresie kołowym
  static const List<Color> _chartColors = [
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
  ];

  // Funkcja formatująca sumę (dodaje przecinki jako separatory tysięcy)
  String _formatWithCommas(double number) {
    String numStr = number.toStringAsFixed(0);
    return numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Funkcja przeliczająca obce waluty na PLN na potrzeby wykresu
  double _convertToPLN(double value, String currency) {
    switch (currency) {
      case 'USD':
        return value * 4.00;
      case 'EUR':
        return value * 4.30;
      case 'GBP':
        return value * 5.05;
      default:
        return value;
    }
  }

  // Metoda otwierająca ekran formularza w trybie EDYCJI
  void _openEdit(BuildContext context, AssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAssetScreen(
          assetToEdit: asset,
          isInvestment: true, // Pamiętamy, że to inwestycja!
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsyncValue = ref.watch(investmentsProvider);

    return Scaffold(
      body: investmentsAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Błąd: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (allAssets) {
          if (allAssets.isEmpty) {
            return const Center(
              child: Text(
                'Brak inwestycji. Dodaj pierwszą!',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Wyliczanie całkowitej wartości do środka wykresu
          final double totalValue = allAssets.fold(
              0, (sum, a) => sum + _convertToPLN(a.value, a.currency));

          // Generowanie kawałków wykresu kołowego
          final chartSections = List.generate(allAssets.length, (i) {
            final a = allAssets[i];
            final valueInPLN = _convertToPLN(a.value, a.currency);
            final pct = totalValue > 0 ? (valueInPLN / totalValue) * 100 : 0.0;
            
            return PieChartSectionData(
              color: _chartColors[i % _chartColors.length],
              value: valueInPLN,
              title: '${pct.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            );
          });

          return ListView(
            children: [
              const SizedBox(height: 16),

              // ── Wykres ──────────────────────────────────────────────────
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: chartSections,
                        centerSpaceRadius: 60,
                        sectionsSpace: 4,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'SUMA (PLN)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_formatWithCommas(totalValue)} PLN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Lista Inwestycji ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Twoje inwestycje (${allAssets.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Scroll obsługuje główny ListView
                itemCount: allAssets.length,
                itemBuilder: (_, i) => AssetCard(
                  asset: allAssets[i],
                  onEdit: () => _openEdit(context, allAssets[i]), // Podpięta EDYCJA
                  onDelete: () => ref
                      .read(investmentsProvider.notifier)
                      .deleteInvestment(allAssets[i].id),
                ),
              ),

              const SizedBox(height: 80), // Margines nad przyciskiem FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Otwieramy formularz w trybie DODAWANIA
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAssetScreen(isInvestment: true),
            ),
          );
        },
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}