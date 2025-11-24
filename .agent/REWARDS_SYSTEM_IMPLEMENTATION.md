# Rewards System Implementation Summary

## Overview

The rewards system has been successfully implemented with monthly tier-based bonuses for workers. The system tracks worker performance per category and rewards them based on their achievements.

## Tier System

### Tier Levels and Requirements

| Tier         | Requirements                    | Monthly Bonus           |
| ------------ | ------------------------------- | ----------------------- |
| **Bronze**   | Rating ≥ 3.5                    | No bonus                |
| **Silver**   | ≥20 jobs/month AND Rating ≥ 4.0 | 5% of monthly earnings  |
| **Gold**     | ≥40 jobs/month AND Rating ≥ 4.5 | 10% of monthly earnings |
| **Platinum** | ≥60 jobs/month AND Rating ≥ 4.8 | 15% of monthly earnings |

## Key Features

### 1. **Monthly Progress Tracking**

- Each worker has a `tiers` subcollection under their user document
- Each tier document (per category) tracks:
  - `tier`: Current tier level (Bronze/Silver/Gold/Platinum)
  - `currentMonthJobs`: Number of completed jobs this month
  - `currentMonthRating`: Average rating for this month
  - `bonusAmount`: Bonus amount earned (calculated at month end)
  - `lastResetDate`: Last time the progress was reset
  - `lastBonusDate`: Last time bonus was applied
  - `lastBonusMonth`: Month when last bonus was applied

### 2. **Automatic Monthly Reset**

- **Schedule**: 1st of every month at 00:00 Saudi Arabia Time
- **Function**: `resetMonthlyTiers`
- **Actions**:
  - Resets all workers' tier progress to Bronze
  - Resets `currentMonthJobs` to 0
  - Resets `currentMonthRating` to 0.0
  - Updates `lastResetDate`
  - Stores previous tier in `previousMonthTier`

### 3. **Monthly Bonus Calculation**

- **Schedule**: Last day of every month at 23:00 Saudi Arabia Time
- **Function**: `applyMonthlyBonus`
- **Process**:
  1. Checks if worker qualifies for a bonus tier
  2. Calculates total earnings from completed transactions for the month
  3. Applies bonus percentage based on tier
  4. Adds bonus to worker's `availableBalance`
  5. Creates a bonus transaction record
  6. Sends notification to worker
  7. Updates tier document with bonus information

### 4. **Real-time Tier Updates**

- **Trigger**: When a booking is completed (status changes to 'C')
- **Function**: `updateTierStatsOnJobComplete`
- **Actions**:
  1. Increments `currentMonthJobs` by 1
  2. Updates `currentMonthRating` with new average
  3. Calculates new tier based on updated stats
  4. Updates tier if changed
  5. Sends congratulatory notification if tier upgraded

### 5. **Rewards Page Display**

- Shows worker's current tier and progress for each job category
- Displays:
  - Current month's completed jobs
  - Current month's average rating
  - Current tier badge
  - Bonus amount earned (if any)
  - Progress bar to next tier
  - Tier benefits information

## Cloud Functions

### Function 1: `resetMonthlyTiers`

```javascript
Schedule: "0 0 1 * *" (1st of month at 00:00 Saudi Arabia Time)
Purpose: Reset all tier progress monthly
```

### Function 2: `applyMonthlyBonus`

```javascript
Schedule: "0 23 * * *" (Daily at 23:00, only runs on last day of month)
Purpose: Calculate and apply monthly bonuses
```

### Function 3: `updateTierStatsOnJobComplete`

```javascript
Trigger: onDocumentUpdated("bookings/{jobId}")
Purpose: Update tier stats when job is completed
```

## Notifications

### 1. **Tier Upgrade Notification**

Sent when a worker reaches a new tier level:

- **Title**: "🎊 Tier Upgraded to [Tier]!"
- **Body**: Congratulatory message with new bonus percentage
- **Data**: Old tier, new tier, jobs count, rating

### 2. **Monthly Bonus Notification**

Sent when monthly bonus is applied:

- **Title**: "🎉 Monthly Bonus Received!"
- **Body**: Tier achievement and bonus amount details
- **Data**: Tier, bonus amount, bonus percentage

## Transaction Records

Bonus transactions are created with:

- `transactionType`: "bonus"
- `paymentMethod`: "bonus"
- `paymentStatus`: "completed"
- `orderId`: Format: `BONUS-YYYYMM-{userId}-{categoryId}`
- Additional metadata: tier, categoryId, bonusPercentage, totalEarnings, jobs, rating, month

## Data Flow

1. **Job Completion**:

   - Worker completes a job → `updateTierStatsOnJobComplete` triggered
   - Stats updated in tier document
   - Tier recalculated and updated if changed
   - Notification sent if tier upgraded

2. **Month End**:

   - Last day at 23:00 → `applyMonthlyBonus` runs
   - Calculates bonuses for eligible workers
   - Updates balances and creates transactions
   - Sends bonus notifications

3. **Month Start**:
   - 1st day at 00:00 → `resetMonthlyTiers` runs
   - All progress reset to Bronze/0 jobs/0 rating
   - Fresh start for new month

## Fixed Issues

1. **Null Pointer Exception**: Fixed line 416 in rewards_page.dart where `tierData!['tier']` was causing crashes
2. **Stats Source**: Changed from all-time stats to current month's data from tier document
3. **Bonus Calculation**: Fixed to use `currentMonthJobs` and `currentMonthRating` from tier document instead of non-existent stats collection
4. **Tier Display**: Now correctly shows current tier from Firestore instead of calculating locally

## Testing Recommendations

1. **Test Job Completion**: Complete a job and verify tier stats update
2. **Test Tier Upgrade**: Complete enough jobs to trigger tier upgrade and verify notification
3. **Test Monthly Reset**: Wait for or manually trigger reset function
4. **Test Bonus Calculation**: Wait for or manually trigger bonus function on last day of month
5. **Verify Transactions**: Check that bonus transactions are created correctly
6. **Verify Notifications**: Ensure workers receive tier upgrade and bonus notifications

## Deployment

To deploy the cloud functions:

```bash
cd functions
npm install
firebase deploy --only functions
```

## Notes

- All times are in Saudi Arabia timezone (Asia/Riyadh)
- Progress resets on the 1st of each month
- Bonuses are calculated on the last day of each month
- Workers can track their progress in real-time on the Rewards page
- Each category is tracked independently
