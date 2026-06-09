import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importujemy wszystkie utworzone ekrany
import 'screens/landing_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/retirement_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/account_screen.dart';

void main() {
  runApp(const ProviderScope(child: FinApp()));
}

class FinApp extends StatelessWidget {
  const FinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinApp',
      debugShowCheckedModeBanner: false, // Usuwamy czerwony pasek "Debug"
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Tło aplikacji z Twojej grafiki
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        // Stylizacja dolnego paska pod kątem naszej neonowej stylistyki
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed, // Wymagane przy 5 zakładkach
        ),
      ),
      // POPRAWKA: Ustawiamy LoginScreen jako punkt startowy zamiast MainNavigationShell
      home: const LandingScreen(),
    );
  }
}

// Główny szkielet (Shell) zarządzający przełączaniem zakładek
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0; // Indeks aktualnie wybranej zakładki

  // Lista 5 ekranów w kolejności zgodnej z planem projektu
  final List<Widget> _screens = [
    const DashboardScreen(),
    const SavingsScreen(), // Twoja działka
    const InvestmentsScreen(), // Twoja działka
    const RetirementScreen(), // Twoja działka
    const ExpensesScreen(),
  ];

  // Tytuły na górnym pasku dla każdej z zakładek
  final List<String> _titles = [
    'FinApp - Dashboard',
    'FinApp - Oszczędności',
    'FinApp - Inwestycje',
    'FinApp - Emerytura',
    'FinApp - Analiza Wydatków',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_currentIndex]),

        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 30, color: Colors.tealAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          const SizedBox(width: 8), // Mały margines od krawędzi ekranu
        ],
      ),
      body:
          _screens[_currentIndex], // Wyświetlamy ekran odpowiadający indeksowi
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Zmieniamy stan po kliknięciu
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Oszczędności',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Inwestycje',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Emerytura',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wydatki',
          ),
        ],
      ),
    );
  }
}
