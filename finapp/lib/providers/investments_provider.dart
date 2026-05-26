import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import 'savings_provider.dart'; // Importujemy stąd apiServiceProvider

// Provider zarządzający listą inwestycji
final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<AssetModel>>(() {
      return InvestmentsNotifier();
    });

class InvestmentsNotifier extends AsyncNotifier<List<AssetModel>> {
  @override
  Future<List<AssetModel>> build() async {
    // Prosimy serwis o pobranie danych z API
    return ref.read(apiServiceProvider).fetchInvestments();
  }

  // Dodawanie nowej inwestycji
  Future<void> addInvestment(AssetModel newAsset) async {
    await Future.delayed(const Duration(seconds: 1));
    if (state.value != null) {
      state = AsyncValue.data([...state.value!, newAsset]);
    }
  }

  // Usuwanie inwestycji (zgodnie z dokumentacją backendu to zostawiamy!)
  Future<void> deleteInvestment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      final updatedList = state.value!
          .where((asset) => asset.id != id)
          .toList();
      state = AsyncValue.data(updatedList);
    }
  }
}
