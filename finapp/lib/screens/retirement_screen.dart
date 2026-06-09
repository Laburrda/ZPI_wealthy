import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RetirementScreen extends StatefulWidget {
  const RetirementScreen({super.key});

  @override
  State<RetirementScreen> createState() => _RetirementScreenState();
}

class _RetirementScreenState extends State<RetirementScreen> {
  final _api = ApiService();
  bool _isLoading = false;

  // --- WSPÓLNE PARAMETRY ---
  double _currentAge = 30;
  final double _retirementAge = 65;

  // --- PARAMETRY: PRYWATNA EMERYTURA ---
  double _monthlyContribution = 1000;
  double _annualReturnRate = 6.0;
  
  double _privatePortfolio = 0.0;
  double _privateMonthlyIncome = 0.0; // NOWOŚĆ: Miesięczny dochód

  // --- PARAMETRY: ZUS ---
  double _grossSalary = 6000;
  double _zusAccumulatedCapital = 0; // Ile już zebraliśmy w ZUS
  
  double _zusNominalPension = 0.0;
  double _zusRealPension = 0.0; // NOWOŚĆ: Realna wartość dzisiejsza

  // ─── WYWOŁANIE API: PRYWATNA EMERYTURA ───
  Future<void> _fetchPrivateCalculation() async {
    setState(() => _isLoading = true);
    try {
      final int yearsLeft = (_retirementAge - _currentAge).toInt();
      final data = {
        "current_portfolio_value": 0.0, 
        "monthly_contribution": _monthlyContribution,
        "years_to_retirement": yearsLeft <= 0 ? 1 : yearsLeft,
        "annual_return_rate": _annualReturnRate / 100,
        "safe_withdrawal_rate": 0.04, 
      };

      final response = await _api.calculatePrivateRetirement(data);

      setState(() {
        _privatePortfolio = (response['portfolio_at_retirement'] as num).toDouble();
        _privateMonthlyIncome = (response['monthly_sustainable_income'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── WYWOŁANIE API: ZUS ───
  Future<void> _fetchZusCalculation() async {
    setState(() => _isLoading = true);
    try {
      // Budujemy paczkę dokładnie pod to, czego wymaga Swagger dla ZUS
      final data = {
        "current_age": _currentAge.toInt(),
        "retirement_age": _retirementAge.toInt(),
        "monthly_gross_salary": _grossSalary,
        "accumulated_capital": _zusAccumulatedCapital,
        "annual_salary_growth": 0.03, // Założenie na sztywno
        "annual_valorization": 0.05,  // Założenie na sztywno
        "annual_inflation": 0.035,    // Założenie na sztywno
      };

      // ZAKŁADAM, że masz (lub dodasz) tę metodę w ApiService!
      final response = await _api.calculateZusRetirement(data);

      setState(() {
        _zusNominalPension = (response['monthly_pension_nominal'] as num).toDouble();
        _zusRealPension = (response['monthly_pension_real_today_value'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _formatCurrency(double number) {
    String numStr = number.toStringAsFixed(0);
    return numStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Prywatna (4%)'),
              Tab(text: 'ZUS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrivateTab(),
            _buildZusTab(),
          ],
        ),
      ),
    );
  }

  // ─── ZAKŁADKA 1: PRYWATNA ───
  Widget _buildPrivateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultCard(
            title: 'Miesięczna wypłata (Reguła 4%)',
            mainValue: _privateMonthlyIncome,
            subtitle: 'Zebrany kapitał: ${_formatCurrency(_privatePortfolio)} PLN',
            onCalculate: _fetchPrivateCalculation,
          ),
          const SizedBox(height: 32),
          const Text('Parametry', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSliderRow(title: 'Wiek', value: _currentAge, min: 18, max: 64, unit: 'lat', onChanged: (v) => setState(() => _currentAge = v)),
          _buildSliderRow(title: 'Wpłata', value: _monthlyContribution, min: 0, max: 5000, unit: 'PLN', isCurrency: true, onChanged: (v) => setState(() => _monthlyContribution = v)),
          _buildSliderRow(title: 'Zwrot', value: _annualReturnRate, min: 0, max: 15, unit: '%', onChanged: (v) => setState(() => _annualReturnRate = v)),
        ],
      ),
    );
  }

  // ─── ZAKŁADKA 2: ZUS ───
  Widget _buildZusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultCard(
            title: 'Dzisiejsza wartość emerytury',
            mainValue: _zusRealPension,
            subtitle: 'Nominalnie za ${_retirementAge - _currentAge} lat: ${_formatCurrency(_zusNominalPension)} PLN',
            onCalculate: _fetchZusCalculation,
          ),
          const SizedBox(height: 32),
          const Text('Parametry', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSliderRow(title: 'Wiek', value: _currentAge, min: 18, max: 64, unit: 'lat', onChanged: (v) => setState(() => _currentAge = v)),
          _buildSliderRow(title: 'Pensja brutto', value: _grossSalary, min: 3000, max: 30000, unit: 'PLN', isCurrency: true, onChanged: (v) => setState(() => _grossSalary = v)),
          _buildSliderRow(title: 'Dotychczas w ZUS', value: _zusAccumulatedCapital, min: 0, max: 500000, unit: 'PLN', isCurrency: true, onChanged: (v) => setState(() => _zusAccumulatedCapital = v)),
        ],
      ),
    );
  }

  // ─── WIDŻETY POMOCNICZE ───
  Widget _buildResultCard({required String title, required double mainValue, required String subtitle, required VoidCallback onCalculate}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.tealAccent, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.tealAccent)
                : Text(
                    '${_formatCurrency(mainValue)} PLN',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(50)),
              onPressed: _isLoading ? null : onCalculate,
              child: const Text('Oblicz symulację', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({required String title, required double value, required double min, required double max, required String unit, bool isCurrency = false, required ValueChanged<double> onChanged}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text('${isCurrency ? _formatCurrency(value) : value.toStringAsFixed(0)} $unit', style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: value, min: min, max: max, activeColor: Colors.tealAccent, onChanged: onChanged),
        const SizedBox(height: 16),
      ],
    );
  }
}