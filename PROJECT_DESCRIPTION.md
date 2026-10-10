# Sar-E (SARI) — Project Description & Product Specification

> **Local-First, Offline AI-Powered POS & Inventory Management System for Philippine Micro-Retail**

---

## 1. Executive Summary

**Sar-E** is a local-first, zero-cloud-dependent Flutter point-of-sale (POS), smart inventory, and AI-assisted ledger application engineered specifically for the Philippine micro-retail economy. Designed to run smoothly on low-spec Android devices without an internet connection, Sar-E modernizes the four primary micro-store formats in the Philippines:
1. **Sari-Sari Stores** (convenience retail, barcode scanning, suki credit)
2. **Gulay Stalls** (fresh produce, digital per-kilo scale pricing)
3. **Rice / Bigasan** (bulk grain bins, printable thermal QR bin labels, per-kilo/sack pricing)
4. **Carinderias** (cooked meal eateries, rapid tap POS, combo meal engines, batch portioning)

Powered by an **on-device SQLite database (`sare.db`)** and an embedded **Taglish-native Local AI Engine** (incorporating Google DeepMind Gemma 4 edge architectures and a 30-tree Gradient Boosting Regressor sales forecaster), Sar-E gives neighborhood micro-entrepreneurs (*nanay* and *tatay* store owners) the analytical power of modern enterprise software—with 100% offline resilience, instant execution latency (<2ms), zero monthly server fees, and complete data sovereignty.

---

## 2. Problem Statement & Context

Over 1.3 million sari-sari stores, market stalls, and carinderias account for more than 60% of daily fast-moving consumer goods (FMCG) distribution in the Philippines. Despite their critical economic role, micro-retailers face chronic hurdles:
- **Unreliable Connectivity**: Remote barangays and crowded public markets (*palengke*) suffer from intermittent cellular data and high connectivity costs. Cloud-dependent POS systems regularly crash or freeze during peak hours.
- **Hardware Limitations**: Most vendors use budget Android smartphones (2GB–4GB RAM) with entry-level GPUs that struggle with modern graphic-intensive software.
- **Informal Credit Loss (*Utang*)**: Store owners maintain paper notebooks (*kuwaderno*) to track customer utang. Uncollected loans, lost records, and arithmetic disputes frequently erode working capital.
- **Inventory Stockouts & Guesswork**: Vendors order restocking supplies based on gut feel rather than empirical sales velocity, leading to either expired perishables or lost revenue from high-demand items.
- **One-Size-Fits-All POS Failure**: Standard POS systems assume packaged goods with pre-printed barcodes, completely failing vegetable vendors selling irregular weights or carinderia owners serving batch-cooked lunch combos.

---

## 3. Supported Store Archetypes (StoreAdapter Architecture)

Sar-E replaces rigid POS screens with a polymorphic **StoreAdapter design pattern**, instantly tailoring workflows, data schemas, and keypad interfaces to the active store type:

| Store Type | Core Hardware & Interface Workflow | Unique Domain Engine |
|---|---|---|
| **Sari-Sari Store** | Camera/hardware barcode scanner, rapid multi-item cart, quick suki debtor assignment. | Fast barcode catalog, wholesale pack unbundling, customer credit tracking. |
| **Gulay Stall** | 10-key numeric scale pricing pad with weight presets (0.25kg, 0.5kg, 1kg, 1.2kg, 1.8kg). Zero barcode requirement. | Zero-drift integer cent arithmetic (`ScaleCalculator`), seasonal portion advisor. |
| **Rice / Bigasan** | Printable QR-coded grain bin labels, per-kilo scale calculation, sack wholesale conversion. | Bluetooth/thermal PDF label printer (`LabelPrinter`), moisture and bin batch tracking. |
| **Carinderia** | Visual food tap kiosk, meal combo builder (Ulam + Kanin + Inumin). | Automated combo discounting engine (`ComboEngine`), batch pot portion advisor (`PortionAdvisor`). |

---

## 4. Key Product Features

### 4.1. Rapid Offline Point-of-Sale (POS)
- **Zero-Latency Checkout**: Instant transaction recording directly to local SQLite.
- **Multi-Payment Settlement**: Full support for Cash, Suki Utang (Credit), GCash, Maya, and Philippine bank QR transfers (BDO, BPI, GoTyme, UnionBank, MariBank) with customer-facing verification modals.
- **Immutable Audit Codes**: Every receipt generates a persistent, tamper-proof reference code (`REF-YYYYMMDD-XXXXXX`).
- **Bluetooth Thermal Printing & SMS Receipts**: Direct one-tap receipt sharing via SMS, Messenger, or standard 58mm/80mm Bluetooth ESC/POS thermal printers.

### 4.2. Embedded Local AI & Taglish Voice Assistant
- **Dual-Tier NLU Processing**:
  - *Tier 1*: High-throughput integration with local DeepMind Gemma 4 transformer instances (`128K context window`) when available.
  - *Tier 2*: Zero-crash, on-device regex and slot-extraction NLU engine executing in under 5ms without cloud connectivity.
- **Hands-Free Push-to-Talk (PTT)**: Natural Taglish voice and text commands:
  - *"Ilista kay Aling Nena ang 120 pesos na utang"* -> Automatically drafts a ledger credit entry.
  - *"Dagdag 20 na Lucky Me"* -> Drafts inventory restock.
  - *"Ilan ang naibenta ko ngayong araw?"* -> Queries SQLite sales aggregates in real-time.
  - *"Mag-restock para sa 3 araw"* -> Calculates needed wholesale packs.
- **"Bakit ito ang sagot?" (AI Transparency Drawer)**: Owners can tap any AI response to inspect the exact parsed intent, tool executed, confidence score, and privacy badge.
- **Anti-Destruction Security Policy Gate**: The AI assistant is strictly sandboxed—incapable of dropping tables, truncating databases, modifying PINs, or overwriting records without explicit owner confirmation.

### 4.3. Predictive Sales & Automated Restocking
- **GBR Forecaster**: Embedded 30-tree Gradient Boosting Regressor trained on 15,446 real Philippine neighborhood retail transactions. Predicts 7-day revenue curves, identifies upcoming weekend/payday rushes (*Kinsenas*), and highlights peak hours.
- **Nightly Reorder Worker**: Automated background worker that runs sales velocity calculations and populates `restock_drafts` with supplier-grouped wholesale orders, rounding up to whole vendor packs.

### 4.4. Unified Kasaysayan Ledger (History + Utang)
- **Consolidated Audit Trail**: Integrates cash sales, utang borrowings, and debt repayments into a single chronological timeline.
- **Suki Credit Risk Protection**: Configurable double-confirmation thresholds (default ₱500) and automatic due-date tracking.
- **Zero-Internet Data Export**: Direct export of transaction and ledger records to CSV and local SQLite database backups stored in accessible device storage.

### 4.5. Dual-Persona Shell (Tindahan vs. Mamimili)
- **Owner Mode**: Full access to POS, inventory management, margin analytics, customer debt lists, and AI intelligence. Protected by local PIN and biometric authentication.
- **Buyer Kiosk Mode**: Clean, customer-facing catalog browsing mode where neighborhood buyers can check stock, verify prices, add items to a digital cart, and generate pickup QR codes.

---

## 5. Technical Architecture & Tech Stack

```
               ┌─────────────────────────────────────────────────────┐
               │                     FLUTTER UI                      │
               │  StoreScaffold (16dp Padding · BoxShadows · No-Blur)│
               └───────────┬─────────────────────────────┬───────────┘
                           │                             │
               ┌───────────▼─────────────┐   ┌───────────▼───────────┐
               │    RIVERPOD PROVIDERS   │   │     STORE ADAPTERS    │
               │ (Auth, Inv, Cart, Agent)│   │ (Sari, Gulay, Bigas,  │
               └───────────┬─────────────┘   │      Carinderia)      │
                           │                 └───────────┬───────────┘
               ┌───────────▼─────────────────────────────▼───────────┐
               │                  DOMAIN SERVICES                    │
               │  • ReorderEngine     • ScaleCalculator (Cent-exact) │
               │  • ComboEngine       • SalesPredictionService (GBR) │
               │  • PortionAdvisor    • GemmaLocalService (NLU)      │
               └───────────────────────────┬─────────────────────────┘
                                           │
               ┌───────────────────────────▼─────────────────────────┐
               │                LOCAL DATA LAYER                     │
               │  SQLite (sare.db) · DAOs (Product, Trans, Customer, │
               │  Credit, Ledger, AiLog, RestockDraft)               │
               └─────────────────────────────────────────────────────┘
```

- **Frontend & Framework**: Flutter 3.x / Dart (100% sound null safety).
- **State Management**: Riverpod (`AsyncNotifier` and `StateNotifier`).
- **Local Persistence**: SQLite via `sqflite` and `sqflite_common_ffi`.
- **Local AI & Forecasting**:
  - Google DeepMind Gemma 4 Edge (128K context window).
  - 30-Tree Gradient Boosting Regressor (GBR) runtime.
  - SARI On-Device Rule & Slot Extraction Engine.
- **Styling & Theme Guidelines**:
  - Strict Filipino Crimson & Amber Palette: `#D62828` (Primary Red), `#FFC93C` / `#B45309` (Amber/Gold), `#FFFFFF` (Surface/Cards). Zero UI green.
  - **Zero BackdropFilter / ImageFilter.blur**: All depth is rendered using high-efficiency CSS-style `BoxShadow` tokens to guarantee a rock-solid 60 FPS on budget devices.
  - Clean, high-legibility 2D vector icons (zero decorative emojis).

---

## 6. Testing & Quality Assurance

The codebase is hardened by a 125-test automated harness:
- **Contract Verification (`test/harness/store_adapter_test.dart`)**: Enforces StoreAdapter contracts across all 4 store formats.
- **Arithmetic Precision (`test/harness/rice_label_test.dart`, `sari_v4_test.dart`)**: Verifies exact-cent integer pricing without floating-point inaccuracies.
- **Local AI & NLU Integrity (`test/harness/local_ai_nlu_test.dart`)**: Validates Taglish intent extraction, slot binding, zero emoji generation, and security gate blocks.
- **Golden Bounds & Layout Tests**: Validates 16dp spacing, contrast tokens, and responsive mobile rendering.
- **Static Analysis**: Enforces clean `flutter analyze` with 0 warnings or errors.

---

## 7. Build & Deployment Artifacts

The application builds into a production-ready Android package:
- **APK Target**: `build/app/outputs/flutter-apk/app-release.apk`
- **Release Mirror**: `apk/app-release.apk`
- **Target OS**: Android 5.0 (API level 21) and above.
- **Network Requirement**: 0 kbps (100% offline operational requirement).
