# Admin Assignment Notifications - Implementation Guide

## Overview

This document outlines the missing notification functionality for technician assignments by admins and provides the exact code changes needed.

## Current State Analysis

### ✅ What EXISTS:

1. **Initial Assignment Notification** - `notifyAgentOnAssignment` (line 154)

   - Triggers when `bookingStatusCode` changes to 'A'
   - Sends notification to technician
   - **Already handles:** Normal cancellation workflow (P → A when admin assigns after cancellation)

2. **Warranty Notification Function** - `notifyOnWarrantyRequestStatusChange` (line 2133)
   - Handles various warranty status changes
   - **Problem:** Does NOT detect when `warranty.assignedTechnicianId` changes

### ⚠️ What's PARTIALLY MISSING:

1. **Normal Booking Re-Assignment Edge Case** - When admin directly swaps technicians while status stays 'A' (rare)
   - **Note:** Normal workflow (cancel → P → assign → A) is ALREADY handled ✅
2. **Warranty Technician Assignment** - When admin assigns technician to warranty repair

---

## Important Clarification

### Normal Booking Workflow (ALREADY WORKS ✅):

1. Technician cancels → `bookingStatusCode` changes from 'A' to 'P'
2. Admin assigns new technician → `booking.agent` is set AND `bookingStatusCode` changes from 'P' to 'A'
3. **Result:** Existing `statusChangedToAssigned` check triggers → Notification sent ✅

### Edge Case (NEEDS FIX ❌):

1. Status is already 'A' (booking assigned)
2. Admin directly changes `booking.agent` to different technician WITHOUT status change
3. **Result:** No notification sent ❌

**Conclusion:** Change 1 is optional for edge cases. Change 2 (warranty) is essential.

---

## Required Changes

### Change 1: Detect Normal Booking Re-Assignment (OPTIONAL - Edge Case Only)

**Location:** `notifyAgentOnAssignment` function, around line 200

**Current Code:**

```javascript
const statusChangedToAssigned =
  beforeData?.bookingStatusCode !== "A" && afterData.bookingStatusCode === "A";

if (statusChangedToAssigned) {
  // ... notification logic
}
```

**New Code:**

```javascript
const statusChangedToAssigned =
  beforeData?.bookingStatusCode !== "A" && afterData.bookingStatusCode === "A";

// Also detect admin re-assignment (agent.uid changed while status is already 'A')
const agentReassigned =
  afterData.bookingStatusCode === "A" &&
  beforeData?.agent?.uid !== afterData.agent?.uid &&
  afterData.agent?.uid; // Make sure new agent exists

if (statusChangedToAssigned || agentReassigned) {
  const agent = afterData.agent;
  if (!agent?.uid) {
    console.log(
      `[${bookingId}] No agent assigned, skipping assignment notification`
    );
  } else {
    const assignmentType = statusChangedToAssigned ? "initial" : "reassignment";
    console.log(
      `[${bookingId}] Agent ${assignmentType} detected for technician ${agent.uid}`
    );

    try {
      const agentDoc = await admin
        .firestore()
        .collection("users")
        .doc(agent.uid)
        .get();

      if (!agentDoc.exists) {
        console.log(`[${bookingId}] Agent user not found`);
      } else {
        const agentData = agentDoc.data();
        const agentLanCode = agentData.lanCode || "en";
        const agentFcmToken = agentData.fcmToken;

        // Different message for reassignment vs initial assignment
        const titleEn = agentReassigned
          ? "Booking Reassigned to You"
          : "New Booking Assigned";
        const titleAr = agentReassigned
          ? "تم إعادة تعيين حجز لك"
          : "تم تعيين حجز جديد لك";
        const bodyEn = agentReassigned
          ? `You have been assigned to a booking for "${serviceName}". Please review and accept.`
          : `You have accepted a new booking for "${serviceName}"`;
        const bodyAr = agentReassigned
          ? `تم تعيينك لحجز خدمة "${serviceName}". يرجى المراجعة والقبول.`
          : `لقد قبلت حجزاً جديداً لخدمة "${serviceName}"`;

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: agent.uid,
          titleEn: titleEn,
          titleAr: titleAr,
          bodyEn: bodyEn,
          bodyAr: bodyAr,
          data: {
            targetRole: "technician",
            category: "booking",
            bookingId,
            serviceName,
            isAdmin: "false",
            assignmentType: assignmentType,
          },
          fcmToken: agentFcmToken,
          lanCode: agentLanCode,
        });
        console.log(
          `[${bookingId}] ${assignmentType} notification sent to technician ${agent.uid}`
        );
      }
    } catch (error) {
      console.error(
        `[${bookingId}] Error sending worker assignment notification:`,
        error
      );
    }
  }

  // ... rest of the code (admin notifications, etc.)
}
```

**What This Does:**

- Detects when `agent.uid` changes while status is already 'A'
- Sends different notification message for re-assignment
- Logs whether it's initial assignment or re-assignment

---

### Change 2: Add Warranty Technician Assignment Detection

**Location:** `notifyOnWarrantyRequestStatusChange` function, around line 2270 (after tracking stopped section)

**Add This Code BEFORE the `if (!status) { return; }` check:**

```javascript
// 10. Warranty Technician Assigned/Reassigned
else if (
  beforeWarranty?.assignedTechnicianId !== afterWarranty.assignedTechnicianId &&
  afterWarranty.assignedTechnicianId
) {
  status = "warranty_technician_assigned";
  console.log(
    `Warranty technician ${afterWarranty.assignedTechnicianId} assigned to booking ${bookingId}`
  );
}
```

---

### Change 3: Add Warranty Technician Notification Logic

**Location:** `notifyOnWarrantyRequestStatusChange` function, around line 2510 (after admin notifications, BEFORE `return null;`)

**Add This Code:**

```javascript
// Notify assigned technician for warranty_technician_assigned status
if (status === "warranty_technician_assigned" && workerId) {
  try {
    const technicianDoc = await admin
      .firestore()
      .collection("users")
      .doc(workerId)
      .get();

    if (technicianDoc.exists) {
      const technicianData = technicianDoc.data();
      const technicianFcmToken = technicianData?.fcmToken;
      const technicianLanCode = technicianData?.lanCode || "en";

      if (technicianFcmToken && technicianFcmToken.trim() !== "") {
        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: workerId,
          titleEn: "Warranty Repair Assigned",
          titleAr: "تم تعيينك لإصلاح ضمان",
          bodyEn: `You have been assigned to a warranty repair for ${serviceName}. Customer: ${customerName}. Please review and accept.`,
          bodyAr: `تم تعيينك لإصلاح ضمان لـ ${serviceNameAr}. العميل: ${customerName}. يرجى المراجعة والقبول.`,
          data: {
            targetRole: "technician",
            category: "warranty",
            bookingId: bookingId,
            customerId: customerId || "",
            customerName: customerName,
            status: status,
            warrantyStatusCode: afterStatusCode,
            serviceName: serviceName,
            isWarranty: "true",
            isAdmin: "false",
            ...notificationData,
          },
          fcmToken: technicianFcmToken,
          lanCode: technicianLanCode,
        });
        console.log(
          `[${bookingId}] Warranty assignment notification sent to technician ${workerId}`
        );
      } else {
        console.log(
          `[${bookingId}] Technician ${workerId} has no valid FCM token`
        );
      }
    } else {
      console.log(
        `[${bookingId}] Technician document not found for ID: ${workerId}`
      );
    }
  } catch (error) {
    console.error(
      `[${bookingId}] Error sending notification to assigned warranty technician:`,
      error
    );
  }
}
```

---

## Implementation Steps

1. **Backup the current file:**

   ```bash
   cp functions/index.js functions/index.js.backup
   ```

2. **Make Change 1:**

   - Find the `notifyAgentOnAssignment` function (line ~154)
   - Locate the `if (statusChangedToAssigned)` block (line ~204)
   - Replace the entire block with the new code from Change 1

3. **Make Change 2:**

   - Find the `notifyOnWarrantyRequestStatusChange` function (line ~2133)
   - Locate the tracking stopped section (line ~2265)
   - Add the new `else if` block for warranty technician assignment

4. **Make Change 3:**

   - In the same function, find the admin notification section
   - After the admin notifications (line ~2508), BEFORE `return null;`
   - Add the warranty technician notification logic

5. **Deploy:**
   ```bash
   cd functions
   firebase deploy --only functions
   ```

---

## Testing

### Test 1: Normal Booking Re-Assignment

1. Create a booking with a technician assigned (status = 'A')
2. Have the technician reject it (clears `booking.agent`)
3. Admin assigns a new technician (sets `booking.agent` to new technician)
4. **Expected:** New technician receives "Booking Reassigned to You" notification

### Test 2: Warranty Technician Assignment

1. Create a warranty repair request (status = 'R')
2. Admin assigns a technician (sets `warranty.assignedTechnicianId`)
3. **Expected:** Assigned technician receives "Warranty Repair Assigned" notification

### Test 3: Warranty Technician Re-Assignment

1. Technician rejects warranty (added to `warranty.rejectedTechnicians`, `assignedTechnicianId` cleared)
2. Admin assigns a new technician (sets `warranty.assignedTechnicianId` to new ID)
3. **Expected:** New technician receives "Warranty Repair Assigned" notification

---

## Summary

These changes ensure that:

- ✅ Technicians are notified when admin assigns them to a normal booking (initial or re-assignment)
- ✅ Technicians are notified when admin assigns them to a warranty repair
- ✅ Different messages are shown for initial assignment vs re-assignment
- ✅ All notifications are bilingual (English/Arabic)
- ✅ Proper logging for debugging

All changes are additive and don't break existing functionality.
