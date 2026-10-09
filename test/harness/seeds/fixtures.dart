// Fixture seed data for all store types.
// Run: dart test/harness/seeds/seed_all.dart (manual dev reset)
// Or call in tests via SeedFixtures.seedAll().

// This file defines the seed DATA only — no Flutter imports needed.

// ─── Sari-Sari Store Seed Data ──────────────────────────────────────────────

const List<Map<String, dynamic>> sariSariItems = <Map<String, dynamic>>[
  {'name': 'Regent Piattos Cheese', 'barcode': '4800016004309', 'unit_price': 14.0, 'cost_price': 10.0, 'stock_qty': 48, 'threshold': 10, 'category': 'Snacks'},
  {'name': 'Lucky Me Pancit Canton', 'barcode': '4800016004310', 'unit_price': 13.0, 'cost_price': 9.0, 'stock_qty': 60, 'threshold': 12, 'category': 'Instant Noodles'},
  {'name': 'San Miguel Beer Pale Pilsen', 'barcode': '4800016004311', 'unit_price': 55.0, 'cost_price': 44.0, 'stock_qty': 24, 'threshold': 6, 'category': 'Alcohol'},
  {'name': 'Marlboro Red 20s', 'barcode': '4800016004312', 'unit_price': 175.0, 'cost_price': 160.0, 'stock_qty': 10, 'threshold': 3, 'category': 'Tobacco'},
  {'name': 'Dutchess Margarine 250g', 'barcode': '4800016004313', 'unit_price': 39.0, 'cost_price': 32.0, 'stock_qty': 18, 'threshold': 5, 'category': 'Dairy & Eggs'},
  {'name': 'Milo 3-in-1 Twin Pack', 'barcode': '4800016004314', 'unit_price': 16.0, 'cost_price': 12.0, 'stock_qty': 36, 'threshold': 8, 'category': 'Beverages'},
  {'name': 'Century Tuna Flakes in Oil', 'barcode': '4800016004315', 'unit_price': 38.0, 'cost_price': 30.0, 'stock_qty': 30, 'threshold': 6, 'category': 'Canned Goods'},
  {'name': 'Silver Swan Soy Sauce 200ml', 'barcode': '4800016004316', 'unit_price': 22.0, 'cost_price': 17.0, 'stock_qty': 22, 'threshold': 5, 'category': 'Condiments'},
  // Low stock items (for testing glow states)
  {'name': 'Del Monte Tomato Sauce', 'barcode': '4800016004317', 'unit_price': 25.0, 'cost_price': 19.0, 'stock_qty': 3, 'threshold': 6, 'category': 'Canned Goods'},
  {'name': 'Hope Cigarettes', 'barcode': '4800016004318', 'unit_price': 90.0, 'cost_price': 80.0, 'stock_qty': 0, 'threshold': 2, 'category': 'Tobacco'},
];

// ─── Gulay (Vegetable) Store Seed Data ──────────────────────────────────────

const List<Map<String, dynamic>> gulayItems = <Map<String, dynamic>>[
  {'name': 'Talong (Long Purple)', 'price_per_kg': 75.0, 'stock_kg': 14.5, 'low_stock_kg': 3.0, 'category': 'Gulay', 'portion_servings_per_kg': 4.0},
  {'name': 'Kalabasa (Suprema)', 'price_per_kg': 45.0, 'stock_kg': 22.0, 'low_stock_kg': 4.0, 'category': 'Gulay', 'portion_servings_per_kg': 5.0},
  {'name': 'Sitaw (Stringbeans)', 'price_per_kg': 90.0, 'stock_kg': 8.0, 'low_stock_kg': 2.5, 'category': 'Gulay', 'portion_servings_per_kg': 4.0},
  {'name': 'Kamatis (Native)', 'price_per_kg': 90.0, 'stock_kg': 1.2, 'low_stock_kg': 3.0, 'category': 'Prutas', 'portion_servings_per_kg': 6.0},
  {'name': 'Sibuyas Pula', 'price_per_kg': 140.0, 'stock_kg': 5.0, 'low_stock_kg': 2.0, 'category': 'Pampalasa', 'portion_servings_per_kg': 10.0},
  {'name': 'Bawang (Garlic)', 'price_per_kg': 220.0, 'stock_kg': 3.5, 'low_stock_kg': 1.5, 'category': 'Pampalasa', 'portion_servings_per_kg': 14.0},
  // Out of stock item for testing
  {'name': 'Siling Labuyo', 'price_per_kg': 250.0, 'stock_kg': 0.0, 'low_stock_kg': 0.5, 'category': 'Pampalasa', 'portion_servings_per_kg': 20.0},
];

// ─── Rice Store Seed Data ────────────────────────────────────────────────────

const List<Map<String, dynamic>> riceItems = <Map<String, dynamic>>[
  {'variety': 'Dinorado Special', 'milling_grade': 'Well-Milled', 'price_per_kg': 56.0, 'sack_price_25kg': 1350.0, 'sack_price_50kg': 2650.0, 'stock_kg': 120.0, 'low_stock_kg': 25.0},
  {'variety': 'Sinandomeng', 'milling_grade': 'Well-Milled', 'price_per_kg': 48.0, 'sack_price_25kg': 1150.0, 'sack_price_50kg': 2250.0, 'stock_kg': 80.0, 'low_stock_kg': 25.0},
  {'variety': 'Jasmine Fragrant', 'milling_grade': 'Premium', 'price_per_kg': 62.0, 'sack_price_25kg': 1500.0, 'sack_price_50kg': 2950.0, 'stock_kg': 18.0, 'low_stock_kg': 25.0},
  {'variety': 'NFA Regular', 'milling_grade': 'Regular', 'price_per_kg': 37.0, 'sack_price_25kg': 875.0, 'sack_price_50kg': 1700.0, 'stock_kg': 200.0, 'low_stock_kg': 50.0},
];

// ─── Carinderia Seed Data ────────────────────────────────────────────────────

const List<Map<String, dynamic>> carinderiaDishes = <Map<String, dynamic>>[
  {'name': 'Pork Adobo', 'category': 'Ulam', 'price': 55.0, 'daily_portions': 30, 'portions_left': 22, 'is_combo_eligible': true},
  {'name': 'Ginisang Sayote', 'category': 'Gulay', 'price': 35.0, 'daily_portions': 25, 'portions_left': 18, 'is_combo_eligible': true},
  {'name': 'Steamed Rice (1 cup)', 'category': 'Kanin', 'price': 20.0, 'daily_portions': 80, 'portions_left': 55, 'is_combo_eligible': false},
  {'name': 'Tapsilog', 'category': 'Silog', 'price': 85.0, 'daily_portions': 20, 'portions_left': 14, 'is_combo_eligible': false},
  {'name': 'Longsilog', 'category': 'Silog', 'price': 80.0, 'daily_portions': 15, 'portions_left': 0, 'is_combo_eligible': false},  // out of stock
  {'name': "Sago't Gulaman", 'category': 'Inumin', 'price': 15.0, 'daily_portions': 40, 'portions_left': 28, 'is_combo_eligible': false},
];

const List<Map<String, dynamic>> carinderiaCombos = <Map<String, dynamic>>[
  {'name': '1 Ulam + 1 Kanin', 'price': 65.0, 'ulam_slots': 1, 'kanin_slots': 1},
  {'name': '2 Ulam + 1 Kanin', 'price': 95.0, 'ulam_slots': 2, 'kanin_slots': 1},
  {'name': '2 Half-Ulam + 1 Kanin', 'price': 75.0, 'ulam_slots': 2, 'kanin_slots': 1},
];

// ─── Shared Customers for Utang Tests ───────────────────────────────────────

const List<Map<String, dynamic>> seedCustomers = <Map<String, dynamic>>[
  {'name': 'Aling Nena Santos', 'mobile_number': '09171234567', 'credit_balance': 420.0},
  {'name': 'Mang Tomas Reyes', 'mobile_number': '09181234568', 'credit_balance': 50.0},
  {'name': 'Ate Celia', 'mobile_number': null, 'credit_balance': 0.0},
];
