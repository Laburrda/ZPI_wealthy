import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import '../services/api_service.dart';

// Udostępniamy instancję naszego serwisu
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// FutureProvider to specjalny typ dla zapytań sieciowych (wymagających czasu)
final savingsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final apiService = ref.read(apiServiceProvider); // Pobieramy serwis
  return apiService.fetchSavings(); // Wywołujemy metodę pobierania
});
