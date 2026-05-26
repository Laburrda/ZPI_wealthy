import 'package:flutter/material.dart';
import '../models/asset_model.dart'; // Importujemy nasz model z Kroku 1

class AssetCard extends StatelessWidget {
  final AssetModel asset; // Każdy kafelek musi otrzymać dane o jednym aktywie

  const AssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(
        0xFF1E1E1E,
      ), // Ciemne tło karty (lekko jaśniejsze od czarnego ekranu)
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Neonowa ramka wokół kafelka
        side: const BorderSide(color: Colors.tealAccent, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ikona po lewej stronie
            CircleAvatar(
              backgroundColor: Colors.tealAccent.withOpacity(0.1),
              radius: 24,
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 16),
            // Środkowa sekcja (Nazwa i Instytucja)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.institution,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Prawa sekcja (Wartość i Waluta)
            Text(
              '${asset.value.toStringAsFixed(2)} ${asset.currency}',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
