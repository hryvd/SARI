# Sar-E — Repository Architecture Guide
> This file is for coding agents and new contributors.
> Read this before writing any code. It is the source of truth for conventions.

---

## Project Overview
Sar-E is a local-first, offline Flutter POS and inventory app for four Philippine micro-store types:
- **Sari-Sari** (convenience store, barcode scan)
- **Gulay** (vegetable stall, per-kilo scale pricing)
- **Rice / Bigasan** (grain bins, printable QR labels, per-kilo)
- **Carinderia** (cooked food eatery, tap-kiosk POS, combo meals)

All data lives in an on-device SQLite database (`sare.db`). No cloud database is used.
Firebase is used ONLY for Google Sign-In identity.

---

## Architecture Layers

```
lib/
  theme/          Design tokens. Never add BackdropFilter or blur here.
  widgets/        Shared UI components. Must be const-friendly.
  application/    Riverpod AsyncNotifier providers. One file per domain.
  domain/
    entities/     Pure Dart data classes. No Flutter imports.
    adapters/     StoreAdapter interface + 4 implementations (one per store type).
    services/     Pure business logic (scale calc, portion advisor, combo engine, etc.)
  data/
    local/        SQLite via sqflite. database.dart owns schema + migrations.
      daos/       One DAO per table group.
  screens/        UI screens, one sub-folder per store type where needed.
    inventory/    Per-store inventory screens
    ledger/       Unified Kasaysayan (history + utang)
    buyer/        Buyer kiosk mode
```

---

## Critical Design Rules (DO NOT VIOLATE)
1. **ZERO BackdropFilter / ImageFilter.blur** anywhere in the widget tree. Use BoxShadow only.
2. **16dp page padding** everywhere. Use `StoreScaffold` which enforces this.
3. **const constructors** on all stateless widgets and spacing SizedBoxes.
4. **StoreAdapter delegates** all per-store logic (fields, validation, CSV export). Never hard-code store-type checks in shared screens.
5. **SharedPreferences key `storeType`** — always read this to know which store is active.

---

## Store Adapter Contract
Every adapter must implement:
```dart
abstract class StoreAdapter {
  StoreType get storeType;
  String get storeTitle;
  Color get brandColor;
  bool get requiresBarcode;       // false for gulay, carinderia
  bool get requiresWeightInput;   // true for gulay, rice
  bool get hasComboEngine;        // true for carinderia only
  List<String> get csvHeaders;
  Widget buildInventoryBox(dynamic item, VoidCallback onTap, BuildContext context);
  Widget buildAddForm(BuildContext context);
  Widget buildPosInterface(BuildContext context);
}
```

---

## Test Commands
```powershell
# Static analysis
flutter analyze

# Unit + widget tests
flutter test

# Golden tests only
flutter test test/golden/

# Harness contract suite
flutter test test/harness/

# Profile-mode perf (requires connected device)
flutter run --profile
```

---

## Fixture Seeds (for tests)
```powershell
# Run from repo root
dart run test/harness/seeds/seed_all.dart
```

---

## Database Version History
| Version | Changes |
|---|---|
| 1 | Initial schema |
| 2 | Added barcode column to products |
| 3 | Added sync_queue, price_suggestions benchmark_source |
| 4 | Added store_profile, item_gulay, item_rice, item_dish, ledger_entries |

---

## Acceptance Criteria Format
Each feature has a spec file at `test/harness/specs/<feature>.md`:
```
SPEC: Gulay Scale Pricing
CHECK: 1.8 kg × ₱65.00/kg = ₱117.00 (no floating point error)
CHECK: 0.25 kg × ₱140.00/kg = ₱35.00
CHECK: POS keypad presets show 0.25, 0.5, 1, 1.2, 1.8 kg
CHECK: Portion hint appears as non-blocking chip when weight > 0
CHECK: No barcode field visible in gulay inventory form
```
A feature is DONE when its spec checks all pass as tests.
