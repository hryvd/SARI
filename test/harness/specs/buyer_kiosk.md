SPEC: Buyer Kiosk Mode & Zero-Cloud Offline Ordering
CHECK: Catalog loads in buyer mode without authentication (Zero-Cloud Dual-Persona)
CHECK: Visual box menu supports browsing, categories, and stock availability indicator
CHECK: Cart handles items, quantities, and addon modifiers (e.g. Extra Rice, Sago)
CHECK: Offline order payload serializes into compact JSON format with store_id, items, total, and timestamp
CHECK: Offline order payload deserializes cleanly and passes integrity validation
CHECK: High-density QR code is rendered on screen with zero network overhead
CHECK: Seller POS scanner parses buyer order QR and stages items directly into cart in <500ms
CHECK: Store credibility profile badge renders "Dokumento ay Nakakabit sa Telepono"
CHECK: Switch between Seller Mode and Buyer Mode is accessible without login barriers
