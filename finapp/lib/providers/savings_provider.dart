import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final savingsProvider =
    AsyncNotifierProvider<SavingsNotifier, List<AssetModel>>(() {
      return SavingsNotifier();
    });

class SavingsNotifier extends AsyncNotifier<List<AssetModel>> {
  @override
  Future<List<AssetModel>> build() async {
    return ref.read(apiServiceProvider).fetchSavings();
  }

  Future<void> addAsset(AssetModel newAsset) async {
    await Future.delayed(const Duration(seconds: 1));
    if (state.value != null) {
      state = AsyncValue.data([...state.value!, newAsset]);
    }
  }

  // DELETE - Usuwanie
  Future<void> deleteAsset(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      final updatedList = state.value!
          .where((asset) => asset.id != id)
          .toList();
      state = AsyncValue.data(updatedList);
    }
  }

  // UPDATE - Edycja
  Future<void> updateAsset(AssetModel updatedAsset) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      final updatedList = state.value!.map((asset) {
        // Zastępujemy stary element nowym, jeśli ID się zgadza
        return asset.id == updatedAsset.id ? updatedAsset : asset;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}
