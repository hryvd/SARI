# SPEC: Navigation & Store Persistence Fix (Phase 1)

CHECK: Selecting "Gulay / Palengke" during setup persists 'gulay' to SharedPreferences key 'storeType'
CHECK: After login, MainShell reads 'storeType' and shows 🥬 Gulay badge in AppBar
CHECK: After login with 'rice', MainShell shows 🌾 Rice Store badge in AppBar  
CHECK: After login with 'carinderia', MainShell shows 🍚 Carinderia badge in AppBar
CHECK: After login with 'sari_sari' (default), MainShell shows 🏪 Sari-Sari Store badge
CHECK: Bottom tab selected icon color matches the store's brand accent color
CHECK: Navigation indicator in bottom nav matches store accent color
CHECK: Logging out preserves the storeType (returning user sees correct store)
CHECK: signOut() clears storeType — fresh setup forces re-selection
CHECK: Page padding on all home screens is 16dp (matches Sari-Sari reference)
