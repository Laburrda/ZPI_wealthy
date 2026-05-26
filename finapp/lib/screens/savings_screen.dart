import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/savings_provider.dart';
import '../widgets/asset_card.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsyncValue = ref.watch(savingsProvider);

    return savingsAsyncValue.when(
      data: (assets) {
        return ListView.builder(
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return AssetCard(asset: assets[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
      error: (error, stack) => Center(
        child: Text('Błąd: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
