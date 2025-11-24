# Rewards System - Quick Reference

## ✅ Implementation Complete

### What Was Fixed

1. **Null Pointer Exception** - Fixed crash when opening rewards page (line 416)
2. **Current Month Tracking** - Changed to display current month's stats instead of all-time
3. **Bonus Calculation** - Fixed to use tier document data instead of non-existent stats collection
4. **Tier Updates** - Added real-time tier calculation and upgrade notifications

### How It Works

#### For Workers:

- Complete jobs to earn points toward tier upgrades
- Progress tracked per category (e.g., Plumbing, Electrical, etc.)
- View progress on Rewards page
- Receive notifications when tier upgrades
- Get monthly bonus based on tier at end of month

#### Bonus Calculation Formula:

```
Bonus Amount = Total Monthly Earnings × Tier Percentage

Where:
- Total Monthly Earnings = Sum of all completed transaction amounts for that category
- Tier Percentage = 5% (Silver), 10% (Gold), or 15% (Platinum)
```

#### Example:

If a worker:

- Completes 45 jobs in Plumbing category
- Has 4.6 average rating
- Earns ₹50,000 total from those jobs
- Achieves **Gold tier** (≥40 jobs, ≥4.5 rating)

**Bonus = ₹50,000 × 10% = ₹5,000**

### Monthly Timeline

| Date         | Time  | Event                                    | Function            |
| ------------ | ----- | ---------------------------------------- | ------------------- |
| 1st of month | 00:00 | Reset all progress to Bronze             | `resetMonthlyTiers` |
| 1st of month | 01:00 | Calculate & add previous month's bonuses | `applyMonthlyBonus` |

**Example:** January's bonus is calculated and added on February 1st at 01:00

### Data Structure

```
users/{userId}/tiers/{categoryId}
├── tier: "Bronze" | "Silver" | "Gold" | "Platinum"
├── currentMonthJobs: 0
├── currentMonthRating: 0.0
├── bonusAmount: 0.0
├── lastResetDate: Timestamp
├── lastBonusDate: Timestamp
└── lastBonusMonth: "2025-11"
```

### Deployment

To deploy the cloud functions:

```bash
cd functions
firebase deploy --only functions
```

Or deploy specific functions:

```bash
firebase deploy --only functions:resetMonthlyTiers
firebase deploy --only functions:applyMonthlyBonus
firebase deploy --only functions:updateTierStatsOnJobComplete
```

### Testing

1. **Test Rewards Page**: Navigate to rewards page - should open without crashes
2. **Test Job Completion**: Complete a job and check tier stats update
3. **Test Tier Upgrade**: Complete enough jobs to trigger upgrade notification
4. **Test Monthly Functions**: Use Firebase console to manually trigger functions

### Files Modified

1. **lib/pages/home/worker/rewards_page.dart**

   - Fixed null pointer exception
   - Changed to use current month's data from tier document

2. **functions/index.js**
   - Fixed bonus calculation to use tier document data
   - Added tier upgrade notifications
   - Added monthly bonus notifications
   - Updated tier calculation on job completion

### Important Notes

- ✅ Bonus is calculated from **total earnings only** (sum of transaction amounts)
- ✅ Progress resets **every month** on the 1st
- ✅ Bonuses are applied on the **last day of each month**
- ✅ Each category is tracked **independently**
- ✅ Workers receive **notifications** for tier upgrades and bonuses
- ✅ All times are in **Saudi Arabia timezone**

### Support

If issues arise:

1. Check Firebase Functions logs in Firebase Console
2. Verify tier documents exist in Firestore
3. Ensure cloud functions are deployed
4. Check worker FCM tokens are valid
