# SARI v5 Master Implementation Plan & Architecture Specification
> **Enhanced from `Sari v5 Implementation Plan.docx`**
> Author: Antigravity AI Engineering
> Target: SARI Offline-First POS & Commerce Ecosystem (Flutter & SQLite)

---

## 1. Executive Summary & Core Product Rules
SARI (formerly Sar-E) is unified into a single offline-first, local AI-driven mobile operating system for micro-retail in the Philippines (Sari-Sari, Gulay, Rice / Bigasan, Carinderia). v5 eliminates legacy naming, resolves all persistent data synchronization bugs, enforces a crisp Red/Yellow/White design language with zero green and zero emojis, and bridges on-device Gemma 4 E2B/E4B to execute real local database actions.

### Non-Negotiable Core Product Rules
1. **Identity & Naming**: Every user-visible string, receipt, QR title, AI assistant persona, and export is **SARI**. Zero hits for "Sar-E" or "Sari-E" across the repository.
2. **Local AI Centricity**: On-device Gemma 4 E2B/E4B (with local keyword-regex fallback) operates offline. AI returns strict JSON intents and slots; deterministic local tools query and update SQLite. The AI **never writes directly** to SQLite without an explicit user confirmation sheet. Zero mock text or preset fake data.
3. **Local-First Data Ownership**: The Android device SQLite database (`sare.db`) is the single source of truth. Optional cloud sync is strictly secondary.
4. **Permanent Fixed Roles**: Role (`buyer` or `seller`) is selected at authentication and persisted in `SharedPreferences` and SQLite. No in-app mode switching. Role change requires logging out and logging in.
5. **Color & Icon Palette**:
   - **Primary Red**: `#D62828` (Buttons, selected states, headers)
   - **Deep Red**: `#A4161A` (Pressed states, dark surfaces)
   - **Accent Yellow**: `#FFC93C` (Highlights, low-stock warnings, badges)
   - **Surface**: `#FFFFFF` (Cards, dialogs, bottom sheets)
   - **Page Tint**: `#FFF8F0` (Warm canvas background)
   - **Ink**: `#1B1B1B` (Primary text, high-contrast typography)
   - **Muted**: `#6B6B6B` (Subtitles, borders, secondary text)
   - **ZERO Green**: In-stock is neutral/ink/white; low stock is yellow (`#FFC93C`); out-of-stock is red (`#D62828`); success states are white checks on red or yellow.
   - **ZERO Emojis**: Replaced with crisp 2D Material outline icons.
6. **Low-End Hardware Friendly**: Zero `BackdropFilter` or `ImageFilter.blur`. Lightweight `BoxShadow` and solid fills only.

---

## 2. Database v6 Schema & Migration Architecture

### Migration Step (`oldVersion < 6`):
```sql
-- 1. Transactions: Persisted Reference & QR
ALTER TABLE transactions ADD COLUMN reference_code TEXT;
ALTER TABLE transactions ADD COLUMN qr_payload TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_txn_ref ON transactions(reference_code);

-- 2. Suppliers Directory
CREATE TABLE IF NOT EXISTS suppliers (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  contact_person  TEXT,
  phone           TEXT,
  items_supplied  TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

-- 3. Restock Drafts (AI & Nightly Reorder Engine)
CREATE TABLE IF NOT EXISTS restock_drafts (
  id              TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  lines_json      TEXT NOT NULL,
  total_cost      REAL NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open',
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

-- 4. Payment Methods Configuration
CREATE TABLE IF NOT EXISTS payment_methods (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  code            TEXT NOT NULL UNIQUE,
  is_enabled      INTEGER NOT NULL DEFAULT 1,
  qr_data         TEXT,
  account_details TEXT,
  updated_at      TEXT NOT NULL
);

-- 5. AI Command & Learning Log
CREATE TABLE IF NOT EXISTS ai_command_log (
  id              TEXT PRIMARY KEY,
  user_id         TEXT,
  input_text      TEXT NOT NULL,
  intent          TEXT NOT NULL,
  slots_json      TEXT NOT NULL,
  confidence      REAL NOT NULL,
  was_corrected   INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_ai_log_time ON ai_command_log(created_at);
```

---

## 3. Request-to-Phase Implementation Roadmap

### Phase 2: High-Priority Data Bug Fixes
- **Bug 2.1 (Store Name)**: Single source of truth loaded from `store_profile` via `StoreProfileDao`. Zero fallback to "Tindahan" or "Tindahan ni Aling Rosa".
- **Bug 2.2 (Transaction QR & Reference)**: Generated once at POS checkout (`SARI-YYYYMMDD-XXXX`), persisted in `transactions.reference_code` and `transactions.qr_payload`. QR dialogs always render the saved payload.
- **Bug 2.3 (Location Mismatch)**: Single store location in `store_profile`, edited only in Settings.
- **Bug 2.4 (Buyer Kiosk Reopen)**: `user.role = 'buyer'` saved in `SharedPreferences` and `UserCredential`. App boot routes directly to Buyer Home.

### Phase 0 & 1: SARI Branding & Foundation
- Full sweep renaming "Sar-E" -> "SARI" across Dart, AndroidManifest, assets, and documentation.
- Implement design tokens in `AppColors`, `AppTheme`, and `StoreColors`. Remove all greens and emojis.
- Build CSV Export/Import service for Products, Transactions, Utang, and Suppliers.

### Phase 3: Roles & Navigation
- **Seller Shell**: [0] AI Agent, [1] Store POS, [2] Data Summary. Header contains store title, status, and avatar.
- **Buyer Shell**: [0] AI Agent, [1] Mamili (Store Search, Catalog & Live Cart), [2] Inbox & Orders.
- Remove internal mode switchers. Provide clean sign-out/switch account flow.

### Phase 4: Screen UI Overhaul
- **Landing / Auth**: Red & warm-tint layout, 2D outline feature badges, clear Owner PIN / Mamili buttons.
- **Header**: Seamless search bar integrated into the header.
- **POS / Inventory**: Scan and AI Scan blocks cleanly positioned above product box cards.
- **Payment Dock**: Solid red active pills (`Cash`, `GCash`, `Utang`, `Maya`, `Banks`).
- **Summary & Kasaysayan**: Real analytics, red/yellow metrics, tap-to-reveal transaction QRs.

### Phase 5: On-Device AI Engine (Gemma 4 E2B/E4B)
- Local NLU pipeline: Speech/text input -> Gemma prompt -> Strict JSON intent extraction (`find_store`, `add_to_cart`, `place_order`, `restock_report`, `resupply_plan`, `log_utang`, `sales_summary`, `update_stock`) -> Local DB executor -> Clean Taglish reply without emoji -> Confirmation modal on write.

### Phase 6: Settings & Security
- Remove Tagalog language toggle (default Taglish / English).
- Default PIN & Biometric protection with 60-second background lock.
- Expanded payment methods (Cash, GCash, Maya, BPI, BDO, UnionBank).
- CSV export/import and backup management.

### Phase 7: Verification & Testing
- Zero lint/static analysis issues.
- Contract harness tests covering store adapters, POS calculations, and role routing.
