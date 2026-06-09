import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/asset_model.dart';

class ApiService {
  static String? _token;

  String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // =========================================================
  // AUTORYZACJA
  // =========================================================

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        return _token;
      } else {
        throw Exception('Nieprawidłowy adres e-mail lub hasło.');
      }
    } catch (e) {
      throw Exception('Błąd połączenia z serwerem: $e');
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // UWAGA: Upewnij się, że końcówka adresu (endpoint) to faktycznie '/register' 
    // lub zmień ją na taką, jaką masz w backendzie (np. '/auth/register').
    final url = Uri.parse('$baseUrl/auth/register'); 

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "email": email,
          "password": password,
          "full_name": fullName, // backend oczekuje podkreślenia
        }),
      );

      // Status 200 lub 201 oznacza sukces
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Zależnie od tego, czy backend przy rejestracji zwraca od razu token:
        // Jeśli tak, przypisujemy go i zwracamy.
        if (data.containsKey('access_token')) {
          _token = data['access_token']; 
          return _token;
        }
        
        // Jeśli backend nie zwraca tokenu (np. każe się zalogować ręcznie po rejestracji), 
        // możesz zwrócić cokolwiek lub wywołać od razu metodę login() wewnątrz tej funkcji.
        return "success"; 
      } else {
        // Obsługa błędów (np. 400 Bad Request, e-mail zajęty)
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? 'Nie udało się zarejestrować';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Metoda pobierająca dane profilu
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/auth/me');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Pamiętaj, aby wysłać zapisany token! 
        // (Upewnij się, że zmienna nazywa się tak jak w Twoim kodzie, np. _token)
        'Authorization': 'Bearer $_token', 
      },
    );

    if (response.statusCode == 200) {
      // Zwracamy zdekodowany JSON (Map)
      return jsonDecode(response.body);
    } else {
      throw Exception('Nie udało się pobrać danych użytkownika');
    }
  }

  // Metoda czyszcząca zapisany token z pamięci API
  void logout() {
    _token = null;
  }

  // =========================================================
  // OSZCZĘDNOŚCI (SAVINGS, PPK, IKE, IKZE)
  // =========================================================

  Future<List<AssetModel>> fetchSavings() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/assets/savings/'), headers: authHeaders),
        http.get(Uri.parse('$baseUrl/assets/ppk/'), headers: authHeaders),
        http.get(Uri.parse('$baseUrl/assets/ike/'), headers: authHeaders),
        http.get(Uri.parse('$baseUrl/assets/ikze/'), headers: authHeaders),
      ]);

      List<AssetModel> allSavings = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(
            utf8.decode(response.bodyBytes),
          );

          allSavings.addAll(
            data.map((json) {
              final rawValue =
                  json['current_balance'] ??
                  json['cash_balance'] ??
                  json['current_value'] ??
                  json['value'] ??
                  0;

              final double value = rawValue is num
                  ? rawValue.toDouble()
                  : (double.tryParse(rawValue.toString()) ?? 0.0);

              json['value'] = value;
              json['amount'] = value;
              json['current_value'] = value;
              json['current_balance'] = value;
              json['cash_balance'] = value;

              json['institution'] =
                  json['institution_name'] ?? 'Brak instytucji';

              String rawType =
                  json['asset_type']?.toString().toLowerCase() ?? 'savings';
              if (rawType.contains('.')) rawType = rawType.split('.').last;

              json['type'] = rawType;
              json['asset_type'] = rawType;

              return AssetModel.fromJson(json);
            }),
          );
        } else if (response.statusCode == 401) {
          throw Exception('Brak autoryzacji. Zaloguj się ponownie.');
        }
      }
      return allSavings;
    } catch (e) {
      throw Exception('Nie udało się pobrać oszczędności z serwera: $e');
    }
  }

  Future<void> addSaving(Map<String, dynamic> savingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assets/savings/'),
      headers: authHeaders,
      body: jsonEncode(savingData),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Błąd zapisu oszczędności: ${response.statusCode}');
    }
  }

  Future<void> addPpk(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assets/ppk/'),
      headers: authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201)
      throw Exception('Błąd PPK: ${response.body}');
  }

  Future<void> addIke(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assets/ike/'),
      headers: authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201)
      throw Exception('Błąd IKE: ${response.body}');
  }

  Future<void> addIkze(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assets/ikze/'),
      headers: authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201)
      throw Exception('Błąd IKZE: ${response.body}');
  }

  Future<void> deleteSaving(dynamic id, String type) async {
    String path = 'savings';
    if (type == 'ppk')
      path = 'ppk';
    else if (type == 'ike')
      path = 'ike';
    else if (type == 'ikze')
      path = 'ikze';

    final response = await http.delete(
      Uri.parse('$baseUrl/assets/$path/$id'),
      headers: authHeaders,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Błąd usuwania ($path): ${response.body}');
    }
  }

  // =========================================================
  // INWESTYCJE (HOLDINGS + KRYPTO)
  // =========================================================

  Future<List<AssetModel>> fetchInvestments() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/holdings/'), headers: authHeaders),
        http.get(Uri.parse('$baseUrl/assets/crypto/'), headers: authHeaders),
      ]);

      List<AssetModel> allInvestments = [];

      // 1. Giełda (Holdings)
      if (responses[0].statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(responses[0].bodyBytes),
        );
        allInvestments.addAll(
          data.map((json) {
            // Pobieramy cenę oraz ilość, aby obliczyć CAŁKOWITĄ WARTOŚĆ
            final double price =
                (json['current_price'] ?? json['avg_purchase_price'] ?? 0)
                    .toDouble();
            final double quantity = (json['quantity'] ?? 1).toDouble();
            final double totalValue = price * quantity;

            json['value'] = totalValue;
            json['amount'] = totalValue;
            json['current_value'] = totalValue; // <--- TEGO BRAKOWAŁO!

            json['institution'] = 'Rachunek maklerski';

            String rawType =
                json['asset_class']?.toString().toLowerCase() ?? 'investment';
            if (rawType.contains('.')) rawType = rawType.split('.').last;
            json['type'] = rawType;

            return AssetModel.fromJson(json);
          }),
        );
      }

      // 2. Crypto
      if (responses[1].statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(responses[1].bodyBytes),
        );
        allInvestments.addAll(
          data.map((json) {
            final rawValue = json['current_value'] ?? 0;
            final double value = rawValue is num
                ? rawValue.toDouble()
                : (double.tryParse(rawValue.toString()) ?? 0.0);

            json['value'] = value;
            json['amount'] = value;
            json['institution'] = json['institution_name'] ?? 'Portfel Krypto';
            json['type'] = 'crypto';
            json['name'] = json['name'] ?? 'Portfel Krypto';

            return AssetModel.fromJson(json);
          }),
        );
      }

      return allInvestments;
    } catch (e) {
      throw Exception('Błąd pobierania inwestycji: $e');
    }
  }

  Future<void> addInvestment(Map<String, dynamic> data, String type) async {
    final url = (type == 'crypto')
        ? '$baseUrl/assets/crypto/'
        : '$baseUrl/holdings/';
    final response = await http.post(
      Uri.parse(url),
      headers: authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Błąd zapisu inwestycji: ${response.body}');
    }
  }

  Future<void> addCrypto(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assets/crypto/'),
      headers: authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Błąd zapisu krypto: ${response.body}');
    }
  }

  Future<void> deleteInvestment(String id, String type) async {
    final url = (type == 'crypto')
        ? '$baseUrl/assets/crypto/$id'
        : '$baseUrl/holdings/$id';
    final response = await http.delete(Uri.parse(url), headers: authHeaders);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Błąd usuwania inwestycji');
    }
  }

  // =========================================================
  // DASHBOARD I KALKULATORY
  // =========================================================

  Future<Map<String, dynamic>> fetchDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/summary'),
        headers: authHeaders,
      );
      if (response.statusCode == 200)
        return jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Błąd ładowania dashboardu: ${response.statusCode}');
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<Map<String, dynamic>> calculateZusRetirement(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/retirement/zus-projection'),
        headers: authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200)
        return jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Błąd kalkulatora ZUS: ${response.statusCode}');
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<Map<String, dynamic>> calculatePrivateRetirement(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/retirement/private-projection'),
        headers: authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200)
        return jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Błąd kalkulatora prywatnego: ${response.statusCode}');
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  // =========================================================
  // TRANSAKCJE I KATEGORIE
  // =========================================================

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: authHeaders,
      );
      if (response.statusCode == 200)
        return jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Błąd ładowania kategorii');
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<List<dynamic>> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/'),
        headers: authHeaders,
      );
      if (response.statusCode == 200)
        return jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Błąd ładowania transakcji');
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 422) {
        print("DEBUG 422 TRANSAKCJE: ${response.body}");
        throw Exception('Serwer odrzucił dane: ${response.body}');
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Błąd dodawania transakcji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: authHeaders,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Błąd usuwania transakcji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd komunikacji: $e');
    }
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> payload) async {
    // Upewnij się, że URL zgadza się z Twoim Swaggerem (np. /transactions/{id})
    final url = Uri.parse('$baseUrl/transactions/$id');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Nie udało się zaktualizować transakcji');
    }
  }

  // ── NOWA METODA: DODAWANIE KATEGORII ──
  Future<void> createCategory(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/categories/'); // Upewnij się, że adres jest poprawny

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Nie udało się utworzyć kategorii');
    }
  }
}
