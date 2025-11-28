# Notification Issues - Fixed

## Issue 1: Duplicate Payment Complete Notifications to Technicians ✅ FIXED

### Problem

Technicians were receiving **two identical notifications** when a customer completed payment for a booking.

### Root Cause

Two separate Cloud Functions were both triggering on the same `paymentCompleted` field change:

1. **`notifyCustomerOnBookingStatusChange`** (line 330) - Intended for customer notifications but was also checking `paymentCompleted` changes
2. **`notifyTechnicianOnPaymentCompletion`** (line 460) - Dedicated function for technician payment notifications

Both functions use `onDocumentWritten` on the `bookings/{bookingId}` path, so when `paymentCompleted` changed from `false` to `true`, both functions executed and sent notifications to the technician.

### Solution

Modified `notifyCustomerOnBookingStatusChange` to skip execution when **only** `paymentCompleted` changes (and status doesn't change). This ensures:

- Customer notifications are still sent for status changes
- Customer notifications for payment completion are still sent
- **Technician payment notifications are ONLY sent by the dedicated `notifyTechnicianOnPaymentCompletion` function**

**Code Change (lines 346-363):**

```javascript
// Skip if only payment completed changed (technician gets notified by separate function)
// This function should only notify customers
if (!statusChanged && paymentCompleted) {
  console.log(
    "Payment completed change only - handled by separate technician notification function, skipping customer notification..."
  );
  return;
}
```

---

## Issue 2: Missing Warranty Repair Request Notifications ✅ FIXED

### Problem

When a customer requests warranty repair service (when `booking.warranty.warrantyStatusCode` changes from `'A'` to `'R'`), notifications were being sent to:

- ✅ Customer
- ✅ Admin

But **NOT** to:

- ❌ The assigned technician (whose ID is in `booking.warranty.assignedTechnicianId`)

### Root Cause

The `notifyOnWarrantyRequestStatusChange` function (line 2133) correctly detected the `'A'` → `'R'` status change and sent notifications to customers and admins, but there was no code to notify the assigned technician.

### Solution

Added notification logic to send a notification to the assigned technician when `status === "repair_requested"`. The notification:

- Fetches the technician document using `booking.warranty.assignedTechnicianId`
- Retrieves their FCM token and language preference
- Sends a bilingual notification (English/Arabic) informing them of the warranty repair request
- Includes relevant booking data (customer name, service name, booking ID, etc.)

**Code Change (lines 2509-2565):**

```javascript
// Notify assigned technician for repair_requested status
if (status === "repair_requested" && workerId) {
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
          titleEn: "Warranty Repair Request",
          titleAr: "طلب إصلاح ضمان",
          bodyEn: `${customerName} has requested warranty repair for ${serviceName}. Please review and accept the request.`,
          bodyAr: `طلب ${customerName} إصلاح ضمان لـ ${serviceNameAr}. يرجى المراجعة وقبول الطلب.`,
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
          `[${bookingId}] Warranty repair request notification sent to technician ${workerId}`
        );
      }
    }
  } catch (error) {
    console.error(
      `[${bookingId}] Error sending notification to technician:`,
      error
    );
  }
}
```

### Notification Recipients Now (for A → R warranty status change):

1. ✅ **Customer** - Confirmation that their repair request was submitted
2. ✅ **Admin(s)** - Alert that a warranty repair was requested
3. ✅ **Assigned Technician** - Notification to review and accept the warranty repair request

---

## Testing Recommendations

### Test Case 1: Payment Completion

1. Create a booking and complete the service (status = 'C')
2. Have the customer complete payment
3. **Expected Result:** Technician receives **ONE** notification about payment completion

### Test Case 2: Warranty Repair Request

1. Create a completed booking with warranty (status = 'C', warranty.warrantyStatusCode = 'A')
2. Assign a technician to the warranty (`warranty.assignedTechnicianId`)
3. Customer requests repair (change `warranty.warrantyStatusCode` from 'A' to 'R')
4. **Expected Result:**
   - Customer receives notification confirming request
   - All admins receive notification about the request
   - **Assigned technician receives notification to review the request**

---

## Files Modified

- `functions/index.js` - Fixed duplicate notifications and added technician notification for warranty repair requests
