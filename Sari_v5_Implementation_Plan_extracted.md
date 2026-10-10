
SARI v5 Implementation Plan
SARI (formerly Sar-E) becomes one local-first, AI-first app for sellers and buyers. v5 renames the whole UI, fixes the data bugs, restyles everything in red, yellow and white, and makes on-device Gemma do real work. Phases 0 to 2 gate everything after them.
1. Product rules (every screen obeys these)
Rule
What it means in practice
Name is SARI
Every user-visible string, icon label, receipt, file name and AI persona says SARI. No "Sar-E" anywhere
Local AI is the center
Every main flow (order, restock, utang, search) can be done by voice or typed sentence, offline
Local-first data
The phone is the source of truth. Cloud is optional sync, never required
Real data only
No mock text, preset replies, or fake numbers. Empty states say so plainly
Fixed roles
A user is a buyer or a seller from login. No mode switcher inside the app
One visual language
Red, yellow, white. Plain 2D icons. No emoji. No green
Low-end friendly
Solid fills and simple animations, no blur or glass effects
2. Request-to-phase map
Request from the review
Phase
Rename app to SARI everywhere
0
Red/yellow/white scheme, no green, no emoji or colored icons
1
Phone storage, CSV export, optional cloud
1
Store name overwritten, QR/reference changing, location mismatch, wrong buyer UI on reopen
2
Buyer UI from the first page, no mode switch, bottom bar
3
Landing page, header, search, Scan blocks, product boxes, payment buttons, summary cards, transactions
4
Gemma E2B/E4B voice, Taglish, restock, utang, buyer store search
5
Settings: no Tagalog toggle, PIN default on, more payment methods
6
Phase 0: Branding (SARI)
Surface
Change
App label and launcher icon
Display name SARI, new red/yellow icon
Splash and landing
SARI wordmark, no old name
Header and About
Wordmark in header, version footer in Settings reads SARI
AI agent
Named SARI Assistant in chat title, voice prompt, and empty state
Receipts and transaction QR slips
Footer reads SARI, QR label shows the reference code
Files
CSV and backups named sari_<type>_<date>.csv
Notifications and nearby sharing
Titles and broadcast names use SARI
Code
All user-facing text lives in one strings file. Search the repo for "Sar-E" and "Sari-E" until zero hits
Keep the internal package ID unchanged for now. Renaming it would break existing installs and local databases. Decide that separately at release.
Phase 1: Foundation
Design tokens (proposed, adjust after a visual check)
Token
Value
Use
Primary red
#D62828
Filled buttons, selected states, headers
Deep red
#A4161A
Pressed state, shadows tinted red
Accent yellow
#FFC93C
Highlights, low-stock warning, badges
Surface
#FFFFFF
Cards, sheets
Page tint
#FFF8F0
App background (warm white)
Ink
#1B1B1B
Text on white and yellow
Muted
#6B6B6B
Secondary text
Status without green: in stock = neutral, low stock = yellow, out of stock = red, success = white check on red or yellow. One radius, three elevation levels, one spacing scale.
Icons: one outline icon family only. White on filled buttons, ink or red elsewhere. No emoji in any string, including AI suggestions. Add a lint check that fails on emoji characters.
Data layer: one local database (products, categories, transactions, transaction items, utang ledger, suppliers, store profile, payment methods, restock drafts, AI command log). Every record has id, created_at, updated_at. Optional cloud sync is a separate, opt-in module using last-write-wins on updated_at.
Backup and CSV: export products, transactions, utang, and suppliers as CSV to phone storage through the system file picker. Import reads the same files, so export then import round-trips with no data loss. Add a full-backup file for restore on a new phone.
Phase 2: Bug fixes
Bug
Cause to check
Fix
Test
Store name changes to "Tindahan" when tapping the shop button
A default label overwrites the saved name
Read the name from the store profile only. Defaults apply at creation only
Create store "X", visit every tab, name stays "X"
Transaction QR and reference code change
Reference built from UI state at display time
Generate once at checkout, save it, render the QR from the saved value. Each transaction shows its QR or reveals it on tap
Same code before and after app restart and export
Location inconsistent
Several sources for location
Single store-profile location set at account creation, editable only in Settings
All screens show one location
Reopen as Buyer shows the kiosk
Role not persisted or wrong route
Save role at login, route on launch by role
Reopen as buyer lands on buyer home
Phase 3: Roles and navigation
Buyer accounts open straight into the buyer UI (store search, cart, orders, profile). The separate kiosk page is removed.
Seller accounts keep POS, inventory, and summary.
No "Switch to seller" on Orders or Profile. Role changes only by logging in with another account.
Bottom bar keeps three buttons: AI agent on the left, home (POS for sellers) in the center, inbox for buyers or data summary for sellers on the right.
Buyer cart sends the order to the chosen store's POS as an incoming order the seller confirms.
Phase 4: UI overhaul by screen
Screen
Changes
Landing
Replace with the signed-in landing layout from the reference recording
Header
No emoji. Filled red buttons with white icons. Search is one seamless bar inside the header, no second circular field. Remove the QR icon from search
POS and Inventory
Scan and AI Scan are two standalone blocks above the list, not part of the inventory field. Below them, product boxes with soft shadow and full-color fill. Swipe right to move between categories. Low and out-of-stock boxes use yellow and red
Payment
Cash, GCash, Utang fill fully with red when picked. No pale tint. Add the other enabled methods from Settings
Summary
Keep the layout. Upgrade cards: larger figures, small trend lines, red and yellow bars, subtle count-up animation, consistent card height
Transactions
Each row shows its saved reference. Tap to open the stored QR. Search and filter by date, method, utang
AI agent screen
No sample data, no emoji. Suggestion chips come from live state, such as low stock or due utang. Mic button is a filled red circle with a white icon
Buyer screens
Same tokens and components as seller screens. Store results show product match, distance if known, and stock status
Polish pass: same corner radius, same shadow levels, 8 pt spacing grid, large tap targets (48 dp minimum), simple fade and slide transitions only, and a skeleton state instead of spinners.
Phase 5: Local AI (SARI Assistant on Gemma 4 E2B/E4B)
Pipeline
Input: typed text or mic press.
Speech to text on the phone. Use Gemma's native audio input if the build supports it. Otherwise use the on-device recognizer, then pass text to Gemma.
Gemma returns JSON only: intent, slots, confidence.
A validator checks the JSON against a fixed schema. Bad or low-confidence output triggers one short clarifying question.
The app runs a deterministic tool (a database query or a draft action). The model never writes to the database directly.
The reply is composed from the real result in plain text, no emoji.
Any write (order, utang entry, stock change) shows a confirm sheet first.
Intents
Intent
Role
Example (Taglish)
Writes
find_store
Buyer
"May bukas bang tindahan na may itlog malapit sa akin?"
No
add_to_cart
Buyer
"Dagdag ka ng 2 kilong bigas"
Draft
place_order
Buyer
"I-order mo na yung cart ko"
Yes, confirm
restock_report
Seller
"Ano ang kailangan kong i-restock?"
No
resupply_plan
Seller
"Gawa ka ng listahan para sa supplier"
Draft
log_utang
Seller
"Utang ni Aling Nena, 150 pesos"
Yes, confirm
sales_summary
Seller
"Magkano benta ko ngayon?"
No
update_stock
Seller
"Dagdag 20 na Lucky Me"
Yes, confirm
Background restock engine: a nightly job reads sales history and current stock, then saves restock drafts. The assistant and summary page read the same drafts.
Model tiers: E2B is the default. Offer E4B only on phones with enough free RAM, checked at first launch. If the model fails to load, show a clear message and keep typed commands working through the validator with basic keyword rules.
Quality gates (proposed targets)
Gate
Target
Intent accuracy on a 100-sentence Taglish test set
90% or higher
Time to first response on a mid-range phone
Under 3 seconds
Hardcoded replies in the code
Zero
Works in airplane mode
Yes
Learning data: log each command, parsed intent, and whether the user corrected it. Store locally only. Use the log to grow the test set and improve prompts.
Phase 6: Settings and security
Remove the Tagalog toggle for sellers and buyers.
PIN and biometrics are on by default. A seller can turn them off. The PIN is stored hashed in the device keystore, and the app locks after it has been in the background for 60 seconds.
Keep store type, supplier directory, and thermal printer as they are.
Accepted payments: keep the current list and add more banks and QR e-wallets (BPI, BDO, UnionBank, Maya, and others). Each entry has an on/off switch and an optional QR image upload.
Add a Data section: export CSV, backup, restore, and an optional cloud sync switch that is off by default.
Location stays editable here only, as the one source of truth.
Phase 7: QA and release
☐ Zero hits for "Sar-E" in the repo and UI
☐ No green, emoji, or colored icons (lint plus a visual sweep of every screen)
☐ Store name unchanged after visiting every tab
☐ Transaction reference and QR identical before restart, after restart, and after export
☐ Buyer reopen lands on the buyer UI, with no switch to seller anywhere
☐ Airplane mode: POS, AI commands, and CSV export all work
☐ Gemma passes the quality gates in Phase 5
☐ Tested on one low-end and one mid-range phone, with no dropped frames on scroll
☐ Existing Sar-E data migrates to SARI without loss
Risks
Risk
Mitigation
Gemma is slow or too large on low-end phones
E2B default, RAM check at first launch, keyword fallback
Taglish speech recognition errors
Show the transcript for correction before acting, log corrections
Rename or migration breaks saved data
Keep the internal package ID, run a migration test with real exports
Restyle regressions across screens
Single token file, shared components, visual sweep in QA
Scope too large for the time left
Follow the build order. Phases 0 to 3 and 5 are the core. Phase 4 polish can ship in passes
Build order
Phase 2 data bug fixes and role routing, since they affect real data.
Phase 0 branding strings and Phase 1 tokens, icons, storage, CSV.
Phase 3 roles and navigation.
Phase 5 Local AI, built on the real database and tools.
Phase 4 screen overhaul, using the new tokens and AI hooks.
Phase 6 settings and security.
Phase 7 QA and release.
Assumptions to confirm
Android first. iOS follows if needed.
Buyer store search works from stores nearby (phone-to-phone sharing) first, with cloud lookup only when sync is on.
Color values above are a starting point for your review.