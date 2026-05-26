class AssetModel {
  final String id;
  final String name;
  final String type; // np. 'savings', 'ppk', 'ike'
  final String institution;
  final String currency;
  final double value;

  // Konstruktor klasy (wymagamy podania wszystkich pól)
  AssetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.institution,
    required this.currency,
    required this.value,
  });

  // Metoda fromJson - "Tłumacz" z języka backendu (JSON) na język Fluttera (Dart)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id']
          .toString(), // Ubezpieczamy się, gdyby backend przysłał inta zamiast stringa
      name: json['name'] ?? 'Brak nazwy',
      type: json['asset_type'] ?? 'unknown',
      institution: json['institution'] ?? 'Brak instytucji',
      currency: json['currency'] ?? 'PLN',
      // Wartości liczbowe bywają kłopotliwe, wymuszamy konwersję na typ double (zmiennoprzecinkowy)
      value: (json['current_value'] ?? 0.0).toDouble(),
    );
  }

  // Metoda toJson - "Tłumacz" z języka Fluttera z powrotem na JSON (przydatne przy formularzach)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'asset_type': type,
      'institution': institution,
      'currency': currency,
      'current_value': value,
    };
  }
}
