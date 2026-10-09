# SPEC: Gulay Scale Pricing (Phase 4)
# These checks define "done" for Gulay kilo-based scale pricing.
# Run as: flutter test test/harness/gulay_scale_test.dart

CHECK: 1.8 kg × ₱65.00/kg = ₱117.00 (exact, no floating-point error)
CHECK: 1.25 kg × ₱140.00/kg = ₱175.00 (exact)
CHECK: 0.25 kg × ₱80.00/kg = ₱20.00 (exact)
CHECK: 1.0 kg × ₱90.00/kg = ₱90.00 (exact)
CHECK: Weight of 0.0 kg returns ₱0.00
CHECK: Negative weight is rejected
CHECK: Price generator shows presets: 0.25 kg, 0.5 kg, 1 kg, 1.2 kg, 1.8 kg
CHECK: Custom weight entry (free text) updates computed price in real time
CHECK: Portion hint chip appears when weight > 0 and produce has a portion profile
CHECK: Portion hint for 1.8 kg sitaw reads "Pang 6-8 katao" (approximate)
CHECK: No barcode field visible in gulay inventory form
CHECK: No QR code field visible in gulay inventory form
CHECK: "Price per kg" field is required in gulay add-item form
CHECK: "Stock (kg)" field is required in gulay add-item form
