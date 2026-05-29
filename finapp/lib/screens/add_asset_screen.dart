import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import '../providers/savings_provider.dart';
import '../providers/investments_provider.dart';

// Typy oszczędności
const _savingsTypes = ['savings', 'ppk', 'ike', 'ikze'];
const _savingsTypeLabels = {
  'savings': 'Konto oszczędnościowe',
  'ppk': 'PPK',
  'ike': 'IKE',
  'ikze': 'IKZE',
};

const _investmentTypes = [
  'investment',
  'stock',
  'etf',
  'bond',
  'cfd',
  'crypto',
];
const _investmentTypeLabels = {
  'investment': 'Inne',
  'stock': 'Akcje',
  'etf': 'ETF',
  'bond': 'Obligacje',
  'cfd': 'CFD',
  'crypto': 'Kryptowaluty',
};

class AddAssetScreen extends ConsumerStatefulWidget {
  final AssetModel? assetToEdit;
  final bool isInvestment;

  const AddAssetScreen({
    super.key,
    this.assetToEdit,
    this.isInvestment = false,
  });

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _institutionController = TextEditingController();

  String _selectedCurrency = 'PLN';
  String _selectedSavingsType = 'savings';
  String _selectedInvestmentType = 'investment';

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      final a = widget.assetToEdit!;
      _nameController.text = a.name;
      _amountController.text = a.value.toString();
      _institutionController.text = a.institution;
      _selectedCurrency = a.currency;
      if (!widget.isInvestment && _savingsTypes.contains(a.type)) {
        _selectedSavingsType = a.type;
      } else if (widget.isInvestment && _investmentTypes.contains(a.type)) {
        _selectedInvestmentType = a.type;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;

    final asset = AssetModel(
      id:
          widget.assetToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: widget.isInvestment
          ? _selectedInvestmentType
          : _selectedSavingsType,
      institution: _institutionController.text.trim(),
      currency: _selectedCurrency,
      value: double.parse(_amountController.text.trim()),
    );

    if (widget.isInvestment) {
      if (widget.assetToEdit != null) {
        // edycja inwestycji — można rozszerzyć gdy investments_provider będzie miał updateInvestment
        ref.read(investmentsProvider.notifier).addInvestment(asset);
      } else {
        ref.read(investmentsProvider.notifier).addInvestment(asset);
      }
    } else {
      if (widget.assetToEdit != null) {
        ref.read(savingsProvider.notifier).updateAsset(asset);
      } else {
        ref.read(savingsProvider.notifier).addAsset(asset);
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.assetToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (widget.isInvestment
                    ? 'Edytuj inwestycję'
                    : 'Edytuj oszczędności')
              : (widget.isInvestment
                    ? 'Dodaj inwestycję'
                    : 'Dodaj oszczędności'),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Typ oszczędności — tylko dla savings
              if (!widget.isInvestment) ...[
                DropdownButtonFormField<String>(
                  value: _selectedSavingsType,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    'Typ oszczędności',
                    Icons.category_outlined,
                  ),
                  items: _savingsTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_savingsTypeLabels[t] ?? t),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedSavingsType = val!),
                ),
                const SizedBox(height: 16),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _selectedInvestmentType,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    'Typ inwestycji',
                    Icons.trending_up_outlined,
                  ),
                  items: _investmentTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_investmentTypeLabels[t] ?? t),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedInvestmentType = val!),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  'Nazwa aktywa',
                  Icons.label_outline,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wymagane' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  'Wartość',
                  Icons.payments_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wymagane';
                  if (double.tryParse(v) == null) return 'Podaj liczbę';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        'Waluta',
                        Icons.currency_exchange,
                      ),
                      items: ['PLN', 'USD', 'EUR', 'GBP']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCurrency = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _institutionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration(
                        'Instytucja',
                        Icons.account_balance_outlined,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wymagane' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEdit ? 'Zapisz zmiany' : 'Zapisz aktywo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
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
