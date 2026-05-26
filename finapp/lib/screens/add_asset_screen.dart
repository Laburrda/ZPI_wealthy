import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset_model.dart';
import '../providers/savings_provider.dart';
import '../providers/investments_provider.dart'; // Dodajemy import dla inwestycji

class AddAssetScreen extends ConsumerStatefulWidget {
  final AssetModel? assetToEdit;
  final bool
  isInvestment; // NOWOŚĆ: flaga informująca, do której szuflady trafiają dane

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

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      _nameController.text = widget.assetToEdit!.name;
      _amountController.text = widget.assetToEdit!.value.toString();
      _institutionController.text = widget.assetToEdit!.institution;
      _selectedCurrency = widget.assetToEdit!.currency;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final enteredName = _nameController.text.trim();
    final enteredAmount = double.parse(_amountController.text.trim());
    final enteredInstitution = _institutionController.text.trim();

    final newOrUpdatedAsset = AssetModel(
      id:
          widget.assetToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: enteredName,
      // Dynamicznie przypisujemy typ zasobu na podstawie flagi z konstruktora
      type: widget.isInvestment ? 'investment' : 'savings',
      institution: enteredInstitution,
      currency: _selectedCurrency,
      value: enteredAmount,
    );

    // DECYZJA ARCHITEKTONICZNA: Wysyłamy dane do odpowiedniego providera
    if (widget.isInvestment) {
      ref.read(investmentsProvider.notifier).addInvestment(newOrUpdatedAsset);
    } else {
      ref.read(savingsProvider.notifier).addAsset(newOrUpdatedAsset);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInvestment ? 'Dodaj Inwestycję' : 'Dodaj Oszczędności',
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Nazwa aktywa'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Wymagane' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Wartość'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Wymagane';
                  if (double.tryParse(value) == null) return 'Podaj liczbę';
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
                      decoration: _buildInputDecoration('Waluta'),
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
                      decoration: _buildInputDecoration('Instytucja'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Wymagane'
                          : null,
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
                child: const Text(
                  'Zapisz Aktywo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
