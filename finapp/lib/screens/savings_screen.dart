import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/savings_provider.dart';
import '../widgets/asset_card.dart';
import '../models/asset_model.dart';
import 'add_asset_screen.dart';

const _savingsTypeLabels = {
  'savings': 'Konto',
  'ppk':     'PPK',
  'ike':     'IKE',
  'ikze':    'IKZE',
  'crypto':  'Crypto',
};

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  static const List<Color> _chartColors = [
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
  ];

  String _formatWithCommas(double number) {
    String numStr = number.toStringAsFixed(0);
    return numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  double _convertToPLN(double value, String currency) {
    switch (currency) {
      case 'USD': return value * 4.00;
      case 'EUR': return value * 4.30;
      case 'GBP': return value * 5.05;
      default:    return value;
    }
  }

  void _openEdit(BuildContext context, AssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAssetScreen(assetToEdit: asset, isInvestment: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSavingsAsync      = ref.watch(savingsProvider);
    final filteredSavingsAsync = ref.watch(filteredSavingsProvider);
    final activeFilter         = ref.watch(savingsTypeFilterProvider);

    return Scaffold(
      body: allSavingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: const TextStyle(color: Colors.red))),
        data: (allAssets) {
          if (allAssets.isEmpty) {
            return const Center(
              child: Text('Brak oszczędności. Dodaj pierwszą!',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          // Wykres zawsze na podstawie wszystkich aktywów
          final double totalValue = allAssets.fold(0, (sum, a) =>
              sum + _convertToPLN(a.value, a.currency));

          final chartSections = List.generate(allAssets.length, (i) {
            final a = allAssets[i];
            final valueInPLN = _convertToPLN(a.value, a.currency);
            final pct = totalValue > 0 ? (valueInPLN / totalValue) * 100 : 0.0;
            return PieChartSectionData(
              color: _chartColors[i % _chartColors.length],
              value: valueInPLN,
              title: '${pct.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            );
          });

          // Lista przefiltrowana
          final filtered = filteredSavingsAsync.value ?? allAssets;

          // Dostępne typy do filtrowania
          final availableTypes = allAssets.map((a) => a.type).toSet().toList();

          return ListView(
            children: [
              const SizedBox(height: 16),

              // ── Wykres ──────────────────────────────────────────────────
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(PieChartData(
                      sections: chartSections,
                      centerSpaceRadius: 60,
                      sectionsSpace: 4,
                    )),
                    Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('SUMA (PLN)',
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('${_formatWithCommas(totalValue)} PLN',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Filtry po typie ─────────────────────────────────────────
              if (availableTypes.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Przycisk "Wszystkie"
                        _FilterChip(
                          label: 'Wszystkie',
                          isActive: activeFilter == null,
                          onTap: () => ref.read(savingsTypeFilterProvider.notifier).setFilter(null),
                        ),
                        const SizedBox(width: 8),
                        ...availableTypes.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: _savingsTypeLabels[type] ?? type,
                            isActive: activeFilter == type,
                            onTap: () => ref.read(savingsTypeFilterProvider.notifier).setFilter(activeFilter == type ? null : type),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Lista ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  activeFilter == null
                      ? 'Twoje konta'
                      : '${_savingsTypeLabels[activeFilter] ?? activeFilter} (${filtered.length})',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Brak pozycji tego typu.',
                      style: TextStyle(color: Colors.white38))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => AssetCard(
                    asset: filtered[i],
                    onEdit: () => _openEdit(context, filtered[i]),
                    onDelete: () => ref.read(savingsProvider.notifier).deleteAsset(filtered[i].id),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAssetScreen()),
        ),
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// ── Widget filtra ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.tealAccent.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.tealAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.tealAccent : Colors.white54,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}