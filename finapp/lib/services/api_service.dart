import '../models/asset_model.dart';

class ApiService {
  // Symulujemy zapytanie sieciowe (jak GET /assets/savings)
  Future<List<AssetModel>> fetchSavings() async {
    // Udajemy, że czekamy 2 sekundy na odpowiedź z serwera Pythona
    await Future.delayed(const Duration(seconds: 2));

    // Zwracamy listę zasobów
    return [
      AssetModel(
        id: '1',
        name: 'Konto Oszczędnościowe',
        type: 'savings',
        institution: 'mBank',
        currency: 'PLN',
        value: 12500.50,
      ),
      AssetModel(
        id: '2',
        name: 'Lokata Nocna',
        type: 'savings',
        institution: 'PKO BP',
        currency: 'PLN',
        value: 5000.00,
      ),
    ];
  }

  Future<List<AssetModel>> fetchInvestments() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      AssetModel(
        id: '3',
        name: 'IKE (Obligacje Skarbowe)',
        type: 'investment',
        institution: 'PKO BP',
        currency: 'PLN',
        value: 34000.00,
      ),
      AssetModel(
        id: '4',
        name: 'Konto Maklerskie (ETFy)',
        type: 'investment',
        institution: 'XTB',
        currency: 'USD',
        value: 8500.00,
      ),
    ];
  }
}
