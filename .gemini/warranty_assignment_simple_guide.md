# Warranty Technician Assignment Notification - Simple Implementation

## What's Missing

When admin assigns a technician to a warranty repair by setting `warranty.assignedTechnicianId`, the technician does NOT receive a notification.

## Solution

Add 2 code blocks to the `notifyOnWarrantyRequestStatusChange` function in `functions/index.js`.

---

## Change 1: Detect Warranty Assignment

**Location:** Line ~2270 (after the tracking stopped section, BEFORE `if (!status)`)

**Find this code:**

```javascript
      // Only send notification if tracking stopped after warranty was accepted
      if (trackingStoppedTime > acceptedAtTime) {
        status = "warranty_tracking_stopped";
        console.log(
          `Warranty-based tracking stopped for booking ${bookingId} (tracking stopped after warranty acceptance)`
        );
      }
    }

    if (!status) {
      return;
    }
```

**Add this BEFORE `if (!status)`:**

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

## Change 2: Send Notification to Assigned Technician

**Location:** Line ~2510 (after admin notifications, BEFORE `return null;`)

**Find this code:**

```javascript
      }
    }

    return null;
  }
);
```

**Add this BEFORE `return null;`:**

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

## Testing

1. Create a warranty repair request (status 'R')
2. Admin assigns a technician (sets `warranty.assignedTechnicianId`)
3. **Expected:** Technician receives "Warranty Repair Assigned" notification

---

## Deploy

```bash
cd functions
firebase deploy --only functions:notifyOnWarrantyRequestStatusChange
```

That's it! Just 2 code additions.
