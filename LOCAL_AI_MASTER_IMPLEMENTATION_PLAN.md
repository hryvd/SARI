# SARI Local AI Engine — Master Architecture & Implementation Plan
> **Document Version**: 5.0-AI-CORE  
> **Status**: Approved Master Specification  
> **Target**: On-Device Gemma 4 E2B/E4B + Deterministic SQLite Tooling Ecosystem  

---

## 1. Vision & Core Philosophy

In SARI v5, **Local AI is not a chatbot gimmick; it is the primary operating modality of the application.** Every critical task—selling, stocking, auditing debts, and purchasing—can be initiated through typed or spoken Taglish sentences without internet access.

### The Five Inviolable AI Principles
1. **Zero Cloud Network Calls**: Model weights, speech recognition, intent parsing, database reads, and draft mutations happen 100% on the local Android hardware. Airplane mode is a first-class supported state.
2. **Zero Hallucinated / Mock Data**: The model **never** generates fake inventory quantities, made-up prices, or synthetic financial summaries. If the store has 0 transactions today, the AI states: *"Walang naitalang transaksyon sa tindahan ngayong araw."*
3. **Model Proposes, Deterministic Tools Execute**: The neural model outputs **strictly structured JSON** specifying an intent and extracted entity slots. It never executes raw SQL or writes directly to tables.
4. **Human-in-the-Loop Confirmation on State Mutation**: Any action that alters financial or inventory records (`place_order`, `log_utang`, `update_stock`, `confirm_restock`) must present a native confirmation bottom sheet before writing to SQLite.
5. **No Emojis & Pure Red/Yellow/White Visuals**: Responses are rendered in crisp plain text with zero emojis. AI UI surfaces utilize Primary Red (`#D62828`), Accent Yellow (`#FFC93C`), Surface White (`#FFFFFF`), and Page Tint (`#FFF8F0`).

---

## 2. End-to-End Pipeline Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        INPUT LAYER (Offline)                           │
│  [ Microphone (Speech-to-Text) ]   OR   [ Typed Taglish Sentence ]     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ UTF-8 Text
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      LOCAL NLU INFERENCE ENGINE                        │
│                                                                        │
│   Primary Tier: Gemma 4 E2B Multimodal Engine (Local Transformer)     │
│   - Context: 128K window, bfloat16/int4 quantized local weights       │
│   - Prompt: System instructions + Turn tokens + Strict JSON Schema    │
│                                                                        │
│   Fail-Safe Tier: Deterministic Taglish Slot Extractor (Regex/Rules)  │
│   - Instant (<5ms), Zero-RAM footprint, active during model load/low-RAM│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Validated JSON
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 SCHEMA VALIDATOR & SECURITY GATEWAY                    │
│   - Validates JSON format: { intent, slots, confidence }               │
│   - Checks Security Policy (Blocks delete, reset, export, settings)   │
│   - Confidence < 0.65 -> Generates single clarifying prompt           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Authorized Intent + Slots
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   DETERMINISTIC TOOL DISPATCHER                        │
│                                                                        │
│  [ find_store ]        ──► StoreProfileDao + Local Geo Index           │
│  [ add_to_cart ]       ──► ProductDao.findByName() + BuyerCartNotifier │
│  [ place_order ]       ──► BuyerOrderService.stageOrder() + QR Confirm │
│  [ restock_report ]    ──► ProductDao.getLowStock()                    │
│  [ resupply_plan ]     ──► ReorderEngine.calculateNeeded()             │
│  [ log_utang ]         ──► CustomerDao + Draft Utang Confirm Sheet     │
│  [ sales_summary ]     ──► TransactionDao.getAggregateByPeriod()       │
│  [ update_stock ]      ──► ProductDao.updateStock() + Confirm Sheet    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Real SQLite Entity Results
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   LOCAL AUDIT LOG & RESPONSE RENDERER                  │
│   - Logs execution to `ai_command_log` table (input, intent, slots)    │
│   - Renders Taglish response string (plain text, zero emoji)          │
│   - Pops confirmation modal if state mutation is requested            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Strict Gemma 4 Turn Prompt & JSON Schema Contract

### Gemma 4 Special Token Framing
```text
<|turn>system
Ikaw ang SARI Assistant, isang maaasahang offline AI para sa mga tindahan at mamimili sa Pilipinas.
Tungkulin mong suriin ang Taglish na utos ng user at maglabas LAMANG ng valid JSON na sumusunod sa schema.
HUWAG maglagay ng markdown formatting, paliwanag, o emoji. Maglabas lamang ng JSON object:
{
  "intent": "find_store" | "add_to_cart" | "place_order" | "restock_report" | "resupply_plan" | "log_utang" | "sales_summary" | "update_stock" | "blocked" | "unknown",
  "slots": {
    "item_name": string | null,
    "quantity": number | null,
    "unit": string | null,
    "customer_name": string | null,
    "amount": number | null,
    "days_cover": number | null,
    "period": "today" | "yesterday" | "week" | "month" | null
  },
  "confidence": number
}
<turn|>
<|turn>user
{USER_TAGLISH_QUERY}
<turn|>
<|turn>model
```

---

## 4. Intent Catalog & Deterministic Tool Specifications

| Intent | Target Role | Taglish Example Query | Deterministic Local Action | Mutation Risk |
|---|---|---|---|---|
| `find_store` | Buyer | *"May tindahan bang may itlog malapit sa akin?"* | Queries `StoreProfileDao` and product catalog for `itlog`. Returns store name, item stock status, and distance. | Read (Safe) |
| `add_to_cart` | Buyer | *"Dagdag ka ng 2 kilong bigas"* | Queries `ProductDao` for `bigas`, calculates line price, and adds 2 units to `BuyerCartNotifier`. | Draft (Safe) |
| `place_order` | Buyer | *"I-order mo na yung cart ko"* | Stages order in `BuyerOrderService`, calculates grand total, and displays QR confirmation dialog. | Write (**Requires Confirm**) |
| `restock_report` | Seller | *"Ano ang kailangan kong i-restock?"* | Queries `ProductDao.getLowStock()`. If none: *"Sapat pa ang lahat ng paninda."* If found, lists exact item names and remaining stocks. | Read (Safe) |
| `resupply_plan` | Seller | *"Gawa ka ng listahan para sa supplier, good for 3 days"* | Runs `ReorderEngine.calculateNeeded(products, days: 3)`, groups items by supplier, calculates pack rounding and cost. | Draft (Safe) |
| `log_utang` | Seller | *"Utang ni Aling Nena, 150 pesos"* | Finds or creates customer `Aling Nena` in `CustomerDao`. Pops native confirmation sheet showing ₱150 and customer name before writing to `credit_entries`. | Write (**Requires Confirm**) |
| `sales_summary` | Seller | *"Magkano benta ko kahapon?"* | Queries `transactions` table between start and end timestamps. Computes real `SUM(total_amount)` and `COUNT(*)`. | Read (Safe) |
| `update_stock` | Seller | *"Dagdag 20 na Lucky Me"* | Matches product `Lucky Me` in `ProductDao`. Pops modal with "+20 stock (New Total: X)" confirmation button. | Write (**Requires Confirm**) |
| `blocked` | Both | *"Burahin ang database / I-delete ang lahat"* | Triggered by security gate. Replies: *"Hindi ito maaaring gawin ng AI. Pumunta sa Settings > Privacy gamit ang PIN."* | Blocked |

---

## 5. Offline Data Modeling & Persistence

### 1. `ai_command_log` Table (SQLite)
Every prompt and parsed intent is recorded locally to evaluate accuracy and improve local routing:
```sql
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

### 2. `restock_drafts` Table (SQLite)
Generated by `resupply_plan` or nightly reorder evaluations:
```sql
CREATE TABLE IF NOT EXISTS restock_drafts (
  id              TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  lines_json      TEXT NOT NULL,
  total_cost      REAL NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open', -- 'open', 'confirmed', 'cancelled'
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);
```

---

## 6. Real Gemma 4 Model Integration vs. Deterministic Fallback

### Model Tier Strategy
- **Tier 1 (High Performance)**: When local server or ONNX runtime is detected on `http://127.0.0.1:8765`, requests are sent directly to the local Gemma 4 transformer for zero-latency, high-accuracy conversational extraction.
- **Tier 2 (On-Device Embedded Fallback)**: If the device is constrained on RAM (<4GB) or the weights are initializing, the system falls back seamlessly to the **SARI Embedded NLU Engine**. This regex and slot-extraction engine evaluates Taglish syntax, ensures zero crashes, zero waiting, and immediate answers.

### Security Gate: Anti-Destruction Guarantee
The local AI cannot:
- Delete records, truncate tables, or wipe local database.
- Export or leak store credentials.
- Change owner PIN or biometrics.
- Overwrite existing customer loans without confirmation.

---

## 7. Step-by-Step Implementation Roadmap

```
PHASE AI-1: Local Schema & Log Foundation
  ├─ Add `ai_command_log` and `restock_drafts` to SQLite schema (`database.dart`).
  └─ Implement `AiLogDao` for offline telemetry and correction tracking.

PHASE AI-2: Hardened NLU Parser & Dispatcher
  ├─ Refactor `GemmaLocalService`:
  │   ├─ Implement strict JSON response validator.
  │   ├─ Integrate Taglish slot extractors (item, quantity, pesos, customer, period).
  │   └─ Connect Security Policy Gate.
  └─ Implement `AiToolDispatcher`:
      ├─ Wire `find_store`, `add_to_cart`, `place_order` for Buyers.
      └─ Wire `restock_report`, `resupply_plan`, `log_utang`, `sales_summary`, `update_stock` for Sellers.

PHASE AI-3: Interactive Confirmation Modals
  ├─ Build `AiConfirmSheet` widget (Clean white container, red/yellow action buttons, zero green).
  ├─ Wire confirmation for `log_utang` (creates `CreditEntry` in SQLite upon tap).
  ├─ Wire confirmation for `update_stock` (updates `stock_qty` in SQLite upon tap).
  └─ Wire confirmation for `place_order` (generates persistent QR code).

PHASE AI-4: AI Screen Visual & Audio Polishing
  ├─ Update `AiAgentScreen`:
  │   ├─ Live suggestion chips based on real database state (e.g., low stock items, today's sales).
  │   ├─ Red circular mic button (`#D62828`) with white icon, pulsating wave.
  │   ├─ Remove all emojis from chat bubbles and persona titles.
  │   └─ Add "Bakit ito ang sagot?" transparency drawer reading from `ai_command_log`.

PHASE AI-5: Nightly Background Reorder Engine
  ├─ Implement `NightlyReorderWorker`: runs sales velocity calculations and writes drafts to `restock_drafts`.
  └─ Sync assistant and Data Summary screens to read the same saved drafts.

PHASE AI-6: Automated Verification & Test Harness
  ├─ Create `test/harness/local_ai_nlu_test.dart`:
  │   ├─ 100-sentence Taglish test suite for all 8 intents.
  │   ├─ Verification of zero emoji in model outputs.
  │   ├─ Security gate unit tests (blocks destructive prompts).
  │   └─ Database confirmation flow tests.
```
