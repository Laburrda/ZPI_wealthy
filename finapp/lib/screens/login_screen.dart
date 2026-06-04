import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Importujemy plik main.dart, w którym żyje nasz główny szkielet z dolnym paskiem
import '../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Tytuł
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FinApp',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Twój Osobisty Asystent Finansowy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                  const SizedBox(height: 48),

                  // Komunikat o błędzie
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pole: E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(
                      'Adres e-mail',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Wprowadź poprawny e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pole: Hasło
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(
                      'Hasło',
                      Icons.lock_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Hasło musi mieć minimum 6 znaków';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Przycisk resetu hasła (nieklikalny placeholder)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: null,
                      child: const Text(
                        'Zapomniałeś hasła?',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Przycisk Zaloguj
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      //walidacja loginu na razie wylaczona bo mnie pojebe zeby sie logowac za kazdym razem
                      onPressed: _isLoading
                          ? null
                          : _submitLogin, //_isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Zaloguj się',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NOWOŚĆ: Przycisk rejestracji (nieklikalny placeholder)
                  TextButton(
                    onPressed: null, // Ustawienie na null wyłącza przycisk
                    child: const Text(
                      'Nie masz jeszcze konta? Zarejestruj się!',
                      style: TextStyle(
                        color: Colors
                            .white38, // Wyciszony kolor, spójny z przyciskiem resetu
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Funkcja pomocnicza do dekoracji pól tekstowych
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.tealAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
