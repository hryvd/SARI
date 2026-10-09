# SPEC: Carinderia Kiosk & Combo Engine (Phase 6)

CHECK: Combo A (1 Ulam + 1 Kanin) requires exactly 1 ulam tap to complete
CHECK: Combo B (2 Ulam + 1 Kanin) requires exactly 2 ulam taps to complete
CHECK: After selecting combo, tapping a sold-out ulam dish is disabled (greyed out)
CHECK: Silog meal shows modifier group for egg style (Sunny/Scrambled)
CHECK: Silog add-on "Extra Rice" increases order total by correct amount
CHECK: Cancelling an add-on group mid-selection returns to dish selection
CHECK: Daily portions count correctly decrements when a dish is ordered
CHECK: When portions_left = 0, dish tile shows "UBOS NA" and is un-tappable
CHECK: Full combo + silog + drink order completes in <= 10 taps
CHECK: Order total is correctly summed (combo base + all add-on prices)
CHECK: Carinderia inventory form has NO barcode field
CHECK: Carinderia inventory form has "Daily Portions" field (integer)
CHECK: Carinderia inventory form has "Combo Eligible" toggle
CHECK: POS interface is tap-only (no barcode scanner shown)
