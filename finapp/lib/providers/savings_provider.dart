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
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.where((asset) => asset.id != id).toList(),
      );
    }
  }

  Future<void> updateAsset(AssetModel updatedAsset) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.map((a) => a.id == updatedAsset.id ? updatedAsset : a).toList(),
      );
    }
  }
}

// Przefiltrowana lista — używana przez ekran
final filteredSavingsProvider = Provider<AsyncValue<List<AssetModel>>>((ref) {
  final savings = ref.watch(savingsProvider);
  final filter  = ref.watch(savingsTypeFilterProvider);

  return savings.whenData((assets) {
    if (filter == null) return assets;
    return assets.where((a) => a.type == filter).toList();
  });
});