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

---

## 8. Technical Specifications & Attributions

### AI Models
SARI uses Google DeepMind Gemma 4 edge models (E2B/E4B) running fully on the device for Taglish voice and text understanding. When a phone cannot run Gemma, a rule-based slot-extraction engine written for SARI takes over. Sales forecasting uses a 30-tree Gradient Boosting Regressor trained on 15,446 Philippine neighborhood retail transactions sourced from real-world collected transaction logs (`sari_sari_dataset.csv`), capturing authentic daily sales volumes, peak-hour surges, and payday (*Kinsenas*) cycles across community sari-sari stores. No cloud AI services or external AI APIs are called at runtime.

### Frameworks and Libraries
- **Core Platform**: Flutter 3.x and Dart with sound null safety.
- **State Management**: `flutter_riverpod: ^2.6.1` (MIT License).
- **On-Device Database**: SQLite through `sqflite: ^2.4.2` and `sqflite_common_ffi: ^2.4.0+3` (BSD-2-Clause License).
- **Barcode & QR Scanning**: `mobile_scanner: ^7.2.0` (BSD-3-Clause License) and `qr_flutter: ^4.1.0` / `qr: ^3.0.2` (BSD-3-Clause License).
- **Speech-to-Text & PTT**: Native Android Speech Recognition platform channel integration with on-device audio waveform visualizer.
- **Bluetooth Thermal Printing & Label PDF Generation**: `printing: ^5.14.2` (Apache-2.0 License) and `pdf: ^3.11.3` (Apache-2.0 License).
- **Local Storage & File Handling**: `path_provider: ^2.1.5` (BSD-3-Clause License) and `open_file: ^3.5.10` (BSD-3-Clause License).
- **Biometrics & Hardware Security**: `local_auth: ^3.0.1` (BSD-3-Clause License) and `crypto: ^3.0.6` (BSD-3-Clause License).
- **Icon Set & Typography**: Google Material Icons (`MaterialIcons-Regular.otf`, Apache-2.0 License) and Google Fonts (`google_fonts: ^6.2.1`, SIL Open Font License 1.1).
- **Charts & Data Visualization**: `fl_chart: ^1.2.0` (MIT License).

### APIs
None required at runtime. The app works with no internet connection. Payment options (GCash, Maya, and bank QR transfers including BDO, BPI, GoTyme, UnionBank, MariBank) display the merchant's stored QR codes locally and do not connect to any external payment gateway or payment provider. No payment API, SMS API, or Messenger API is called at runtime; order receipts, wholesale restock lists, and suki utang reminders are shared strictly through the mobile operating system's native share sheet (`Share` / `ClipboardData`).

### AI Development Tools
Claude (Anthropic) was used to plan the architectural implementation, structure the domain models, and author the master project specification documents. Antigravity / Gemini (Google DeepMind) was used as the pair-programming and coding agent to write the Flutter application code, develop the SQLite schema and DAOs, build the StoreAdapter polymorphic architecture, implement the NLU slot-extraction engine and nightly reorder worker, assemble the 125-test automated test harness, and compile the production Android release APK.

### Existing Code and Assets
- **Gemma 4 Edge Weights**: Google DeepMind Gemma 4 model weights utilized under the official Gemma Terms of Use.
- **Third-Party Libraries**: Open-source Flutter and Dart packages sourced from pub.dev under permissive licenses (MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0).
- **Reused Code & Assets**: Prior Sar-E foundations (database migration schema versions 1–3 and base entity structures), brand assets (`assets/images/sare_logo.png`), and pre-trained GBR decision tree weights (`assets/sales_model.json`).
- **Newly Authored for This Project**: The 125-test verification harness (`test/harness/`), the polymorphic `StoreAdapter` system (Sari-Sari, Gulay, Rice, Carinderia), the `ReorderEngine` and `NightlyReorderWorker`, the cent-exact `ScaleCalculator`, the `ComboEngine`, the `PortionAdvisor`, and the embedded rule-based Taglish NLU engine.

