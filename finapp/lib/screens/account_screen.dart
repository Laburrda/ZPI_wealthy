import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Upewnij się, że ścieżki są poprawne
import '../providers/auth_provider.dart';
import 'landing_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nasłuchujemy danych z API
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Konto'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Riverpod .when() genialnie obsługuje stan ładowania, błędu i sukcesu
      body: userProfileAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
        error: (error, stack) => Center(
          child: Text('Błąd: $error', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (userData) {
          // Formatowanie daty (ucinamy godzinę, by zostawić samo YYYY-MM-DD)
          final createdAt = userData['created_at']?.toString().split('T').first ?? 'Brak danych';
          
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Avatar na górze
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.tealAccent,
                child: Icon(Icons.person, size: 60, color: Colors.black),
              ),
              const SizedBox(height: 32),

              // Pola z danymi (Zgodne z JSONem: email, full_name, created_at)
              _buildInfoTile('Imię i nazwisko', userData['full_name'] ?? '-'),
              const Divider(color: Colors.white24),
              _buildInfoTile('Adres e-mail', userData['email'] ?? '-'),
              const Divider(color: Colors.white24),
              _buildInfoTile('Konto aktywne od', createdAt),
              const Divider(color: Colors.white24),
              
              const SizedBox(height: 48),

              // Przycisk Wyloguj
              ElevatedButton.icon(
                onPressed: () {
                  // 1. Wyczyść stan aplikacji
                  ref.read(authProvider.notifier).logout();
                  
                  // 2. Przenieś brutalnie na Landing Page i wyczyść stos ekranów!
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Wyloguj się',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.8), // Czerwony kolor ostrzegawczy
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Funkcja pomocnicza do ładnego rysowania pól tekstowych
  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}