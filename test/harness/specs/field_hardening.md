SPEC: Field Hardening & Usability Validation
CHECK: Zero BackdropFilter and zero ImageFilter.blur anywhere in widget tree
CHECK: Strict 16dp page padding and spacing consistency across all screens
CHECK: Scale pricing arithmetic exact cent precision (1.8kg @ 65 = 117.00, 1.25kg @ 140 = 175.00)
CHECK: 100% Offline resilience across all core flows (catalog, POS, ledger, QR generation, export)
CHECK: Low-end memory budget and resource leak prevention (dispose controllers, pure Dart services)
CHECK: End-to-end multi-store persona workflows pass contract checks
