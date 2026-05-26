import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/investments_provider.dart';
import '../widgets/asset_card.dart';
import 'add_asset_screen.dart'; // Odkomentowane!

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsyncValue = ref.watch(investmentsProvider);

    return Scaffold(
      body: investmentsAsyncValue.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const Center(
              child: Text(
                'Brak inwestycji. Dodaj pierwszą!',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              return AssetCard(
                asset: assets[index],
                onDelete: () {
                  ref
                      .read(investmentsProvider.notifier)
                      .deleteInvestment(assets[index].id);
                },
              );
            },
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
          // NOWOŚĆ: Otwieramy ten sam formularz, ale przekazujemy isInvestment: true
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
