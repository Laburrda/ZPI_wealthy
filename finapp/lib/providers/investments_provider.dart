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
  // Usuwanie inwestycji (Krypto lub Holdings)
  Future<void> deleteInvestment(String id) async {
    try {
      // 0. Upewniamy się, że mamy załadowaną listę
      final assets = state.value ?? [];

      // 1. Szukamy inwestycji na liście, żeby poznać jej TYP
      final assetToDeleteList = assets.where((a) => a.id == id).toList();
      if (assetToDeleteList.isEmpty) return; // Jeśli nie znaleziono, przerywamy

      final type = assetToDeleteList.first.type;

      // 2. Prawdziwe usunięcie z API (TERAZ PODAJEMY ID ORAZ TYP!)
      await ref.read(apiServiceProvider).deleteInvestment(id, type);

      // 3. Jeśli serwer usunął bez błędu, aktualizujemy listę na ekranie
      state = AsyncValue.data(assets.where((asset) => asset.id != id).toList());
    } catch (e) {
      // Wyświetlamy ewentualny błąd w konsoli
      print('Błąd usuwania inwestycji: $e');
    }
  }
}
