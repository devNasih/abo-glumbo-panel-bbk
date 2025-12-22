# Payment Workflow Changes - Complete Implementation Plan

## Understanding the New Workflow

### OLD Workflow:

1. Customer books service (no upfront payment)
2. Technician completes work
3. Customer pays via Telr/Cash through app
4. Payment goes to technician's wallet
5. Technician requests payout (earnings + tips + bonus)

### NEW Workflow:

1. **Service Fee Payment** (BEFORE booking creation):

   - Customer pays service fee via Telr card OR selects cash
   - If card: Payment processed, `paymentCompleted = true`
   - If cash: No payment processed, `paymentCompleted = false`, `paymentModeCode = 'H'`
   - Booking created with payment status

2. **Service Completion Payment** (AFTER job done):

   - Customer uploads payment proof (image/document) + amount
   - This amount is for **bonus calculation only**
   - NOT added to technician's payout wallet
   - Stored in `paidAmount` and `paymentProof` fields

3. **Technician Earnings**:

   - **Card Tips**: From customer reviews (via Telr)
   - **Cash Tips**: From customer reviews (info only, not for payout)
   - **Bonus**: Calculated from `paidAmount` (completion payment)
   - **NO service earnings** in wallet

4. **Payout Requests**:
   - Only **Card Tips + Bonus** can be requested
   - NO earnings, NO cash tips

## Database Schema Changes

### Booking Model

```dart
class BookingModel {
  // Existing fields...
  bool paymentCompleted;
  String paymentModeCode; // 'C' = Card, 'H' = Cash, 'U' = Unpaid
  String? orderId; // Telr order ID for card payments
  Timestamp? paymentCompletedAt;

  // NEW fields for completion payment proof
  List<String>? paymentProof; // URLs of uploaded proof files
  double? paidAmount; // Amount paid for job completion (for bonus calc)
}
```

### UnifiedWalletModel

```dart
class UnifiedWalletModel {
  // REMOVE these fields (no longer needed):
  // double? totalEarnings;
  // double? cashEarnings;
  // double? paidEarnings;
  // double? availableEarnings;

  // KEEP these fields:
  double? totalTips; // Lifetime tips (card + cash)
  double? cardTips; // Available card tips for payout
  double? cashTips; // Cash tips (info only)
  double? paidTips; // Already paid out tips

  double? totalBonus; // Total bonus amount
  double? paidBonus; // Already paid out bonus
  double? availableBonus; // Available bonus for payout

  // NEW field for tracking completion amounts (for bonus calculation)
  double? totalCompletionAmount; // Sum of all paidAmount from bookings

  double? totalAvailableBalance; // cardTips + availableBonus only
}
```

### UnifiedPayoutRequestModel

```dart
class UnifiedPayoutRequestModel {
  // REMOVE:
  // double? earningsAmount;

  // KEEP:
  double? tipsAmount; // Card tips only
  double? bonusAmount;
  double? totalAmount; // tipsAmount + bonusAmount
}
```

## Implementation Steps

### Phase 1: Update Models ✅ (Already Done)

- [x] Add `paymentProof` and `paidAmount` to BookingModel
- [x] Create upload payment proof sheet
- [x] Update service booking tile to show upload button

### Phase 2: Update Wallet System (Current Task)

- [ ] Remove earnings-related fields from UnifiedWalletModel
- [ ] Add `totalCompletionAmount` field
- [ ] Update `updateWalletAmounts` to NOT accept earnings
- [ ] Update bonus calculation to use `totalCompletionAmount`
- [ ] Update payout request to only allow card tips + bonus

### Phase 3: Update Booking Details Display

- [ ] Show `paymentProof` files in booking details (admin/technician side)
- [ ] Show `paidAmount` in booking details
- [ ] Ensure service fee payment status is displayed correctly

### Phase 4: Update Cloud Functions (if any)

- [ ] Check if bonus calculation is done in cloud functions
- [ ] Update to use `paidAmount` instead of service earnings

## Key Points to Remember

1. **Service fee payment** (before booking) is NOT added to wallet
2. **Completion payment** (`paidAmount`) is ONLY for bonus calculation
3. **Only card tips and bonus** go to wallet for payout
4. **Cash tips** are tracked but NOT available for payout
5. **Existing Telr integration** must be preserved and used
6. **saveTransaction** must be called for card payments

## Files to Modify

### Customer App (abo-glumbo-bbk)

1. `lib/models/booking.dart` ✅
2. `lib/sheets/upload_payment_proof_sheet.dart` ✅
3. `lib/common_widgets/service_booking_tile.dart` ✅
4. `lib/l10n/app_en.arb` ✅
5. `lib/l10n/app_ar.arb` ✅

### Technician App (abo-glumbo-panel-bbk)

1. `lib/models/unified_payout.dart` - Remove earnings fields
2. `lib/services/unified_payout_services.dart` - Update wallet logic
3. `lib/pages/home/admin/manage/payouts/manage_unified_payouts.dart` - Update UI
4. Booking details pages - Show payment proof and amount

### Cloud Functions (if applicable)

1. Check bonus calculation logic
2. Update to use `paidAmount`
