import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider aktywnego filtra typu oszczędności
class SavingsFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? type) => state = type;
}

final savingsTypeFilterProvider =
    NotifierProvider<SavingsFilterNotifier, String?>(SavingsFilterNotifier.new);

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

  Future<void> deleteAsset(String id) async {
    try {
      // 1. Zabezpieczenie: upewniamy się, że mamy listę
      final assets = state.value ?? [];

      // 2. Szukamy naszego aktywa na liście, żeby poznać jego TYP
      final assetToDeleteList = assets.where((a) => a.id == id).toList();
      if (assetToDeleteList.isEmpty) return; // Nie znaleziono

      final assetToDelete = assetToDeleteList.first;

      // 3. Prawdziwe usunięcie z bazy (TERAZ PODAJEMY ID ORAZ TYP!)
      await ref.read(apiServiceProvider).deleteSaving(id, assetToDelete.type);

      // 4. Jeśli serwer potwierdził usunięcie, wyrzucamy kafelek z ekranu
      state = AsyncValue.data(assets.where((asset) => asset.id != id).toList());
    } catch (e) {
      // W razie problemów wyświetlamy błąd w konsoli
      print('Błąd usuwania oszczędności: $e');
    }
  }

  Future<void> updateAsset(AssetModel updatedAsset) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!
            .map((a) => a.id == updatedAsset.id ? updatedAsset : a)
            .toList(),
      );
    }
  }
}

// Przefiltrowana lista — używana przez ekran
final filteredSavingsProvider = Provider<AsyncValue<List<AssetModel>>>((ref) {
  final savings = ref.watch(savingsProvider);
  final filter = ref.watch(savingsTypeFilterProvider);

  return savings.whenData((assets) {
    if (filter == null) return assets;
    return assets.where((a) => a.type == filter).toList();
  });
});
