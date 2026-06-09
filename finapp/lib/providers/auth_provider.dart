import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'savings_provider.dart'; // importujemy stąd apiServiceProvider

// Nowoczesny NotifierProvider (Riverpod 2.x+)
final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Domyślny stan początkowy: false (użytkownik nie jest zalogowany)
    return false;
  }

  Future<void> login(String email, String password) async {
    try {
      // W nowym Notifierze mamy natychmiastowy, wbudowany dostęp do obiektu 'ref'
      final apiService = ref.read(apiServiceProvider);

      final token = await apiService.login(email, password);

      if (token != null) {
        // Ustawiamy stan na zalogowany
        state = true;
      }
    } catch (e) {
      // Przekazujemy błąd wyżej (do wyświetlenia na ekranie logowania)
      rethrow;
    }
  }

  // NOWA METODA REJESTRACJI
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // Wywołujemy metodę register z naszego serwisu API
      final token = await apiService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Jeśli rejestracja zwraca token i loguje użytkownika od razu:
      if (token != null) {
        state = true;
      }
    } catch (e) {
      rethrow; // Przekazujemy błąd do ekranu rejestracji (np. "E-mail już zajęty")
    }
  }

  void logout() {
    ref.read(apiServiceProvider).logout(); // Czyści token z pamięci
    state = false; // Zmienia stan autoryzacji na wylogowany
  }
}

// Provider do asynchronicznego pobierania danych profilu
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getUserProfile();
});
