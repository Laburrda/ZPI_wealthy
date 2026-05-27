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

  void logout() {
    state = false;
  }
}
