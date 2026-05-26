import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/savings_provider.dart';
import '../widgets/asset_card.dart';
import 'add_asset_screen.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  // Lista neonowych kolorów dla sekcji wykresu
  static const List<Color> _chartColors = [
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
  ];

  // 1. POPRAWKA: Formatowanie liczb z użyciem przecinków co tysiąc (bez groszy dla sumy głównej)
  String _formatWithCommas(double number) {
    String numStr = number.toStringAsFixed(0);
    return numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 2. POPRAWKA: Symulator kursów walut (Mock API) do ujednolicenia wykresu
  double _convertToPLN(double value, String currency) {
    switch (currency) {
      case 'USD':
        return value * 4.00; // Przykładowy kurs dolara
      case 'EUR':
        return value * 4.30; // Przykładowy kurs euro
      case 'GBP':
        return value * 5.05; // Przykładowy kurs funta
      case 'PLN':
      default:
        return value; // Dla PLN zwracamy bez zmian
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsyncValue = ref.watch(savingsProvider);

    return Scaffold(
      body: savingsAsyncValue.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const Center(
              child: Text(
                'Brak oszczędności. Dodaj pierwszą!',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Obliczamy łączną wartość portfela, przeliczając każdą pozycję na PLN
          final double totalValue = assets.fold(0, (sum, item) {
            return sum + _convertToPLN(item.value, item.currency);
          });

          // Mapujemy aktywa na sekcje wykresu kołowego na podstawie wartości w PLN
          final List<PieChartSectionData> chartSections = List.generate(
            assets.length,
            (index) {
              final asset = assets[index];
              final double valueInPLN = _convertToPLN(
                asset.value,
                asset.currency,
              );
              final double percentage = totalValue > 0
                  ? (valueInPLN / totalValue) * 100
                  : 0;

              return PieChartSectionData(
                color: _chartColors[index % _chartColors.length],
                value: valueInPLN,
                title: '${percentage.toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              );
            },
          );

          // Układ ekranu: Wykres na górze, lista kont na dole
          return ListView(
            children: [
              const SizedBox(height: 16),
              // --- SEKCJA WYKRESU (DONUT CHART) ---
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: chartSections,
                        centerSpaceRadius: 60, // Tworzy estetyczny pierścień
                        sectionsSpace: 4, // Odstępy między sekcjami
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
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Twoje konta',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- SEKCJA LISTY KAFELKÓW ---
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Przewijaniem zarządza główny ListView ekranu
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  return AssetCard(
                    asset: assets[index],
                    onDelete: () {
                      ref
                          .read(savingsProvider.notifier)
                          .deleteAsset(assets[index].id);
                    },
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Błąd: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAssetScreen()),
          );
        },
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
