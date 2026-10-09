// Universal Inventory Screen router.
// Delegates to polymorphic StoreAdapter inventory views (Sari-Sari, Gulay, Rice, Carinderia).
// Uses high-chroma box-grid with status glow and 16dp StoreScaffold padding.

import 'package:flutter/material.dart';

import 'inventory/inventory_screen.dart';

export 'inventory/inventory_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UniversalInventoryScreen();
  }
}
