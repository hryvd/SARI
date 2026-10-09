# SPEC: Universal Box-Grid Inventory (Phase 3)

CHECK: Inventory screen renders a 2-column grid for all store types (not a list)
CHECK: Each card shows: image/icon, name, price, stock badge — nothing else
CHECK: Search box filters cards instantly (no network call, no debounce lag)
CHECK: Category chip "Low Stock" shows ONLY items below threshold
CHECK: Low-stock card has amber border and glow (no blur)
CHECK: Out-of-stock card has crimson border + glow, 50% opacity, "UBOS" badge
CHECK: Normal card has no glow
CHECK: Long-press on a card opens "Quick Restock" bottom sheet
CHECK: Tap on a card opens item detail/edit sheet
CHECK: Grid scrolls at >= 55 fps (flutter profile mode, 2GB RAM device)
CHECK: Page horizontal padding is exactly 16dp
CHECK: Gap between cards is exactly 12dp
CHECK: Grid still renders correctly with 0 items (shows empty state message)
CHECK: Grid still renders correctly with 100+ items
