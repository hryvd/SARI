# SPEC: Store Adapters & Local Database Migration (Phase 2)

CHECK: Database upgraded to version 4 with tables store_profile, item_gulay, item_rice, item_dish, ledger_entries
CHECK: StoreAdapter polymorphism delegates storeType, storeTitle, brandColor, csvHeaders, defaultCategories
CHECK: SariSariAdapter requires barcode, does NOT require weight input, NO combo engine
CHECK: GulayAdapter requires weight input (scale pricing), does NOT require barcode
CHECK: RiceAdapter requires weight input and barcode (QR bin stickers)
CHECK: CarinderiaAdapter activates combo engine, does NOT require barcode
CHECK: storeAdapterProvider cleanly reacts to active storeType from authProvider
CHECK: ItemBox renders with correct per-store accent colors and status badges (MABABA, UBOS)
