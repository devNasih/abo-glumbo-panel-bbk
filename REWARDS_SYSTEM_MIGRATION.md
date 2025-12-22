# Rewards System Complete Migration - Category-Independent

## Overview

Completely removed per-category dependency from the rewards system. The system now tracks only **total jobs completed** and **overall rating** at the user level, eliminating the need for category-specific tier tracking.

## Major Changes

### 1. Cloud Functions (`functions/index.js`)

#### `resetMonthlyTiers` Function

- **Removed**: Tier subcollection queries and updates
- **Added**: Direct user document updates for tier reset
- **Changes**:
  - Resets `tier` to "Bronze" in user document
  - Stores `previousMonthTier`, `previousMonthJobs`, `previousMonthRating` in user document
  - Resets `currentMonthJobs` to 0 in user document
  - Uses batch operations for efficiency (500 users per batch)

#### `applyMonthlyBonus` Function

- **Removed**: Tier subcollection loop and per-category bonus calculation
- **Added**: Single bonus calculation per user based on total earnings
- **Changes**:
  - Uses `userData.previousMonthJobs` and `userData.previousMonthRating` for tier calculation
  - Calculates bonus on **all transactions** (not filtered by category)
  - Stores `bonusAmount` and `lastBonusMonth` in user document
  - Single notification per user (not per category)

#### `updateTierStatsOnJobComplete` Function

- **Removed**: Tier subcollection creation and updates
- **Removed**: Category ID requirement
- **Added**: Direct user document updates
- **Changes**:
  - Increments `currentMonthJobs` in user document
  - Updates `rating` with new average (overall, not per-category)
  - Updates `tier` based on total jobs and overall rating
  - Tier upgrade notifications based on user-level tier changes

### 2. Rewards Page UI (`lib/pages/home/worker/rewards_page.dart`)

#### Complete Rewrite

- **Removed**: All category-based logic and loops
- **Removed**: Tier subcollection queries
- **Removed**: Per-category tier cards
- **Added**: Single tier card showing overall progress
- **Changes**:
  - Fetches data from user document only
  - Displays total jobs, overall rating, current tier, and bonus amount
  - Single progress bar for next tier
  - Pull-to-refresh functionality
  - Simplified state management (no category caching)

### 3. User Model (`lib/models/user.dart`)

#### New Fields Added

```dart
String? tier;                    // Current tier
double? bonusAmount;             // Current month bonus amount
String? previousMonthTier;       // Previous month's tier
double? previousMonthRating;     // Previous month's overall rating
String? lastBonusMonth;          // Last month bonus was applied
int? currentMonthJobs;           // Total jobs this month
int? previousMonthJobs;          // Total jobs last month
```

#### Updated Methods

- `constructor` - Added all new fields
- `copyWith()` - Added all new fields
- `fromJson()` - Parse all new fields
- `toJson()` - Serialize all new fields
- `toFirestore()` - Include all new fields
- `toEditJson()` - Track changes to all new fields (partial - needs completion)

## Data Structure

### Before (Category-Based)

```
users/{userId}
  - rating: number (overall)
  - currentMonthJobs: number (total)
  - previousMonthJobs: number (total)

users/{userId}/tiers/{categoryId}
  - tier: "Bronze" | "Silver" | "Gold" | "Platinum"
  - currentMonthRating: number
  - previousMonthRating: number
  - bonusAmount: number
  - lastBonusMonth: string
```

### After (Category-Independent)

```
users/{userId}
  - rating: number (overall)
  - tier: "Bronze" | "Silver" | "Gold" | "Platinum"
  - currentMonthJobs: number (total)
  - previousMonthJobs: number (total)
  - previousMonthRating: number (overall)
  - previousMonthTier: string
  - bonusAmount: number
  - lastBonusMonth: string
```

**Note**: The `tiers` subcollection is now completely unused and can be deleted.

## Tier Calculation Logic

### Tier Requirements (Unchanged)

- **Bronze**: Rating >= 3.5, No job requirement, 0% bonus
- **Silver**: Rating >= 4.0, **20+ total jobs**, 5% bonus
- **Gold**: Rating >= 4.5, **40+ total jobs**, 10% bonus
- **Platinum**: Rating >= 4.8, **60+ total jobs**, 15% bonus

### Bonus Calculation

- Calculated on **total earnings** from all transactions
- No category filtering
- Applied once per month per user
- Stored in `bonusAmount` field in user document

### Rating Calculation

- **Overall average** across all completed jobs
- Updated with each job completion
- Formula: `(currentRating * currentJobs + newRating) / (currentJobs + 1)`

## Migration Notes

### Breaking Changes

1. **Tier subcollection is obsolete** - All tier data now in user document
2. **Category-specific tiers removed** - Single tier per technician
3. **Bonus per category removed** - Single bonus based on total earnings

### Backward Compatibility

- Existing tier subcollections will not be read or updated
- Old data remains in database but is unused
- New system initializes fields on first job completion after deployment

### Data Cleanup (Optional)

After confirming the new system works correctly, you can:

1. Delete all `tiers` subcollections from user documents
2. Remove unused indexes on tier subcollection queries

## UI Changes

### Rewards Page

- **Before**: Multiple cards (one per category) showing category-specific progress
- **After**: Single card showing overall progress across all categories
- **Benefits**:
  - Simpler, cleaner UI
  - Faster loading (no subcollection queries)
  - Easier to understand for technicians

## Testing Checklist

- [ ] Job completion increments `currentMonthJobs` in user document
- [ ] Job completion updates overall `rating` correctly
- [ ] Tier upgrades trigger when thresholds are met
- [ ] Tier upgrade notifications sent correctly
- [ ] Monthly reset (1st of month) resets tier and jobs correctly
- [ ] Bonus calculation (1st of month) uses total earnings
- [ ] Bonus notification sent with correct amount
- [ ] Rewards page displays correct data
- [ ] Pull-to-refresh updates data correctly
- [ ] No errors in cloud function logs

## Performance Improvements

1. **Fewer Firestore Reads**: No subcollection queries needed
2. **Fewer Firestore Writes**: Single document update instead of multiple
3. **Faster UI Loading**: Direct user document read instead of multiple subcollection reads
4. **Simpler Cloud Functions**: No nested loops or category filtering

## Known Issues

- `toEditJson` method in UserModel needs completion for new tier fields (currently not critical as these fields are updated by cloud functions, not user edits)

## Deployment Steps

1. Deploy cloud functions first
2. Deploy app update
3. Monitor logs for any errors
4. Verify first job completion after deployment works correctly
5. Wait for month-end to verify reset and bonus calculation
