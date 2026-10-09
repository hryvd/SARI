# SPEC: Unified Kasaysayan Ledger (Phase 7)

CHECK: Kasaysayan displays unified timeline containing cash sales, credit issues, and payments
CHECK: Timeline filter chips switch between Lahat (all), Benta (cash), Utang (credit), and Bayad (payments)
CHECK: Cash sale card shows [BENTA] badge, amount formatted as +₱X, and items note
CHECK: Utang card shows [UTANG] badge, customer name, customer balance, and due date
CHECK: Bayad card shows [BAYAD] badge, customer name, and payment amount as -₱X
CHECK: Tapping customer statement shows running balance and history of transactions
CHECK: Magbayad button records repayment and updates customer balance and ledger
CHECK: CSV export follows format: entry_id,timestamp,entry_type,customer_name,amount_php,customer_remaining_balance,payment_ref
CHECK: Main navigation tab 1 mounts KasaysayanScreen
CHECK: Screen uses ZERO BackdropFilter and adheres to 16dp page padding
