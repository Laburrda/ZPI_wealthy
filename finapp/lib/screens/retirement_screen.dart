import 'package:flutter/material.dart';
import 'dart:math';

class RetirementScreen extends StatefulWidget {
  const RetirementScreen({super.key});

  @override
  State<RetirementScreen> createState() => _RetirementScreenState();
}

class _RetirementScreenState extends State<RetirementScreen> {
  double _currentAge = 30;
  final double _retirementAge = 65;
  double _monthlyContribution = 1000;
  double _annualReturnRate = 6.0;

  double _calculateFutureValue() {
    final int yearsToInvest = (_retirementAge - _currentAge).toInt();
    if (yearsToInvest <= 0) return 0;

    final int totalMonths = yearsToInvest * 12;
    final double monthlyRate = (_annualReturnRate / 100) / 12;

    if (monthlyRate == 0) {
      return _monthlyContribution * totalMonths;
    }

    return _monthlyContribution *
        ((pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate);
  }

  // NOWA FUNKCJA: Formatowanie liczb z użyciem przecinków co tysiąc
  String _formatWithCommas(double number) {
    // 1. Zamienia liczbę na tekst bez miejsc po przecinku (np. "1250000")
    String numStr = number.toStringAsFixed(0);
    // 2. Używa wyrażenia regularnego, aby wstawić przecinek co 3 cyfry od końca
    return numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double futureWealth = _calculateFutureValue();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.tealAccent, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Szacowany kapitał w wieku 65 lat',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    // Używamy naszej nowej funkcji do sformatowania wyniku
                    Text(
                      '${_formatWithCommas(futureWealth)} PLN',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Parametry symulacji',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSliderRow(
              title: 'Obecny wiek',
              value: _currentAge,
              min: 18,
              max: 64,
              unit: 'lat',
              onChanged: (val) => setState(() => _currentAge = val),
            ),
            const SizedBox(height: 24),

            _buildSliderRow(
              title: 'Miesięczna wpłata',
              value: _monthlyContribution,
              min: 0,
              max: 10000,
              unit: 'PLN',
              // Tutaj używamy specjalnego formatowania, żeby suwak wpłaty też ładnie wyglądał
              isCurrency: true,
              onChanged: (val) => setState(() => _monthlyContribution = val),
            ),
            const SizedBox(height: 24),

            _buildSliderRow(
              title: 'Roczny zwrot z inwestycji',
              value: _annualReturnRate,
              min: 0,
              max: 15,
              unit: '%',
              onChanged: (val) => setState(() => _annualReturnRate = val),
            ),
          ],
        ),
      ),
    );
  }

  // Lekko zmodyfikowana funkcja pomocnicza przyjmująca flagę isCurrency
  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    bool isCurrency = false,
    required ValueChanged<double> onChanged,
  }) {
    // Decydujemy, czy sformatować wartość przecinkami
    final String displayedValue = isCurrency
        ? _formatWithCommas(value)
        : value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '$displayedValue $unit',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.tealAccent,
          inactiveColor: Colors.white24,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
