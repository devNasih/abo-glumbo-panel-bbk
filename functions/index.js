const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Helper function to send FCM and store notification in Firestore
async function sendAndStoreNotification({
  targetRole, // 'customer', 'technician', 'admin'
  targetId,
  titleEn,
  titleAr,
  bodyEn,
  bodyAr,
  data,
  fcmToken,
  lanCode,
}) {
  // 1. Determine collection based on role
  // Customer -> customers collection
  // Technician/Admin -> users collection
  let collectionName = "users";
  if (targetRole === "customer") {
    collectionName = "customers";
  }

  // 2. Store in Firestore (subcollection 'notifications')
  try {
    await admin
      .firestore()
      .collection(collectionName)
      .doc(targetId)
      .collection("notifications")
      .add({
        titleEn,
        titleAr,
        bodyEn,
        bodyAr,
        data: data || {},
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    console.log(`Notification stored for ${targetRole} ${targetId}`);
  } catch (e) {
    console.error(
      `Error storing notification for ${targetRole} ${targetId}:`,
      e
    );
  }

  // 3. Send FCM
  if (fcmToken && fcmToken.trim() !== "") {
    const title = lanCode === "ar" ? titleAr : titleEn;
    const body = lanCode === "ar" ? bodyAr : bodyEn;

    const message = {
      notification: { title, body },
      data: { ...data, lanCode: lanCode || "en" },
      token: fcmToken,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`FCM sent to ${targetRole} ${targetId}, msgId: ${response}`);
      return response;
    } catch (e) {
      console.error(`Error sending FCM to ${targetRole} ${targetId}:`, e);
    }
  }
  return null;
}

exports.notifyAdminsOnNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const booking = snap.data();
    if (booking.bookingStatusCode !== "P") {
      console.log("Booking is not pending, skipping notification.");
      return null;
    }

    try {
      const adminUsersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            uid: doc.id,
            token: user.fcmToken,
            lanCode: user.lanCode,
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      const results = [];

      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "New Booking Request",
          titleAr: "طلب حجز جديد",
          bodyEn: "Hey Admin, a new booking request just came in!",
          bodyAr: "مرحبًا Admin، لقد تم تقديم طلب حجز جديد!",
          data: {
            targetRole: "admin",
            category: "booking",
            bookingId: event.params.bookingId,
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }
    } catch (error) {
      console.error("Error sending admin notifications:", error);
    }

    return null;
  }
);
exports.notifyAgentOnAssignment = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};

    if (!afterData) {
      console.log(`[${bookingId}] Document deleted, skipping...`);
      return;
    }

    const serviceName = afterData?.service?.name || "";

    // --- Fetch admin users once ---
    let adminTokens = [];
    try {
      const adminSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      adminTokens = adminSnapshot.docs
        .map((doc) => {
          const data = doc.data();
          return data.fcmToken && data.fcmToken.trim() !== ""
            ? { token: data.fcmToken, lanCode: data.lanCode || "en" }
            : null;
        })
        .filter(Boolean);

      if (adminTokens.length === 0) {
        console.log(`[${bookingId}] No admin FCM tokens found`);
      }
    } catch (error) {
      console.error(`[${bookingId}] Error fetching admin users:`, error);
    }

    // ==============================
    // 1. New Assignment Notification
    // ==============================
    const statusChangedToAssigned =
      beforeData?.bookingStatusCode !== "A" &&
      afterData.bookingStatusCode === "A";

    if (statusChangedToAssigned) {
      const agent = afterData.agent;
      if (!agent?.uid) {
        console.log(
          `[${bookingId}] No agent assigned, skipping assignment notification`
        );
      } else {
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

            await sendAndStoreNotification({
              targetRole: "technician",
              targetId: agent.uid,
              titleEn: "New Booking Assigned",
              titleAr: "تم تعيين حجز جديد لك",
              bodyEn: `You have accepted a new booking for "${serviceName}"`,
              bodyAr: `لقد قبلت حجزاً جديداً لخدمة "${serviceName}"`,
              data: {
                targetRole: "worker",
                category: "booking",
                bookingId,
                serviceName,
              },
              fcmToken: agentFcmToken,
              lanCode: agentLanCode,
            });
          }
        } catch (error) {
          console.error(
            `[${bookingId}] Error sending worker assignment notification:`,
            error
          );
        }
      }

      // Notify admins about assignment
      if (adminTokens.length > 0) {
        for (const { uid, token, lanCode } of adminTokens) {
          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: uid,
            titleEn: "New Agent Assigned",
            titleAr: "تم تعيين فني جديد لحجز",
            bodyEn: `An Technician has been assigned to a new booking for "${serviceName}".`,
            bodyAr: `تم تعيين الفني لحجز جديد لخدمة "${serviceName}".`,
            data: {
              targetRole: "admin",
              category: "booking",
              bookingId,
              serviceName,
            },
            fcmToken: token,
            lanCode: lanCode,
          });
        }
      }
    }

    // ==============================
    // 2. Worker Cancellation Notification
    // ==============================
    try {
      const beforeCancelledWorkers = beforeData.cancelledWorkers || [];
      const afterCancelledWorkers = afterData.cancelledWorkers || [];

      // Find new worker(s) who cancelled
      const newCancellations = afterCancelledWorkers.filter(
        (worker) =>
          !beforeCancelledWorkers.some(
            (w) =>
              w.uid === worker.uid &&
              w.cancelledAt?.toMillis?.() === worker.cancelledAt?.toMillis?.()
          )
      );

      if (newCancellations.length > 0) {
        const latestCancelled = newCancellations[newCancellations.length - 1];
        const workerName = latestCancelled?.agentName || "Unknown Worker";
        const workerId = latestCancelled?.uid || "";

        if (adminTokens.length > 0) {
          for (const { uid, token, lanCode } of adminTokens) {
            await sendAndStoreNotification({
              targetRole: "admin",
              targetId: uid,
              titleEn: "Booking Cancelled by Technician",
              titleAr: "إلغاء الحجز من قبل الفني",
              bodyEn: `The booking has been cancelled by Technician ${workerName}.`,
              bodyAr: `تم إلغاء الحجز من قبل الفني ${workerName}.`,
              data: {
                targetRole: "admin",
                category: "booking",
                bookingId,
                workerId,
                workerName,
              },
              fcmToken: token,
              lanCode: lanCode,
            });
          }
        }
      }
    } catch (error) {
      console.error(
        `[${bookingId}] Error notifying admins of cancellation:`,
        error
      );
    }

    return null;
  }
);
exports.notifyCustomerOnBookingStatusChange = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    if (afterData.bookingStatusCode === "P") {
      console.log("Booking status is pending, skipping notification...");
      return;
    }

    // Check for status change or payment completion change
    const statusChanged =
      beforeData?.bookingStatusCode !== afterData.bookingStatusCode;
    const paymentCompleted =
      beforeData?.paymentCompleted !== afterData.paymentCompleted;

    if (!statusChanged && !paymentCompleted) {
      console.log("No relevant changes detected, skipping...");
      return;
    }

    // Only send payment completed notification if status is already "C"
    if (paymentCompleted && afterData.bookingStatusCode !== "C") {
      console.log(
        "Payment completed notification only sent for completed bookings (C)..."
      );
      return;
    }

    const customer = afterData.customer;
    const customerId = customer?.uid;
    if (!customer) {
      console.log("No customer found.");
      return;
    }

    let customerData;
    try {
      const customerDoc = await admin
        .firestore()
        .collection("customers")
        .doc(customerId)
        .get();
      if (!customerDoc.exists) {
        console.log("Customer document not found.");
        return;
      }
      customerData = customerDoc.data();
    } catch (error) {
      console.error("Error fetching customer data:", error);
      return;
    }

    const fcmToken = customerData?.fcmToken;
    const lanCode = customerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Customer has no valid FCM token.");
      return;
    }

    const service = afterData.service;
    const serviceName = service?.name;
    const bookingStatus = afterData.bookingStatusCode;
    const isPaymentCompleted = afterData.paymentCompleted;

    const statusMessages = {
      A: {
        en: "Your booking has been accepted.",
        ar: "تم قبول حجزك.",
      },
      R: {
        en: "Your booking has been rejected.",
        ar: "تم رفض حجزك.",
      },
      C: {
        // Service complete, awaiting payment
        en: "Your service is complete!\nComplete your payment now.\nWe hope you had a great experience.",
        ar: "تم الانتهاء من خدمتك!\nأكمل دفعتك الآن.\nنأمل أن تكون قد قضيت وقتًا رائعًا.",
      },
      C_PAYMENT_COMPLETED: {
        // Service complete and payment received
        en: "Thank you! Your payment has been received.\nWe'd love to hear about your experience.\nPlease share your feedback by rating your service provider.\nYour reviews help us maintain the best service quality.\nIf you'd like, you can also leave a tip to show your appreciation.",
        ar: "شكراً لك! تم استلام دفعتك.\nنود أن نسمع عن تجربتك.\nيرجى مشاركة آرائك بتقييم مقدم الخدمة الخاص بك.\nتساعدنا تقييماتك في الحفاظ على أفضل جودة للخدمة.\nوإذا رغبت، يمكنك ترك إكرامية.",
      },
      XC: {
        en: "Your booking has been canceled.",
        ar: "تم إلغاء حجزك.",
      },
    };

    // Determine which message to use
    let messageKey = bookingStatus;
    if (bookingStatus === "C" && isPaymentCompleted) {
      messageKey = "C_PAYMENT_COMPLETED";
    }

    const bodyEn =
      statusMessages[messageKey]?.["en"] ||
      `Your booking status changed to ${bookingStatus}`;
    const bodyAr =
      statusMessages[messageKey]?.["ar"] ||
      `تغيرت حالة حجزك إلى ${bookingStatus}`;

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn: "Booking Status Update",
      titleAr: "تحديث حالة الحجز",
      bodyEn: `${bodyEn} (${serviceName})`,
      bodyAr: `${bodyAr} (${serviceName})`,
      data: {
        customerId: customerId,
        targetRole: "customer",
        bookingId: event.params.bookingId,
        status: bookingStatus,
        serviceName: serviceName || "Service",
        paymentCompleted: isPaymentCompleted.toString(),
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);

exports.customerTrackingNotification = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const afterData = event.data?.after?.data();
    const beforeData = event.data?.before?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    const customer = afterData.customer;
    const customerId = customer?.uid;

    if (!customerId) {
      console.log("No customer UID found.");
      return;
    }

    let customerData;
    try {
      const customerDoc = await admin
        .firestore()
        .collection("customers")
        .doc(customerId)
        .get();

      if (!customerDoc.exists) {
        console.log("Customer document not found.");
        return;
      }

      customerData = customerDoc.data();
    } catch (error) {
      console.error("Error fetching customer data:", error);
      return;
    }

    const fcmToken = customerData?.fcmToken;
    const lanCode = customerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Customer has no valid FCM token.");
      return;
    }

    const isAccepted = afterData.bookingStatusCode === "A";
    if (!isAccepted) {
      console.log("Booking not accepted, skipping tracking notification...");
      return;
    }

    const wasStarted = beforeData?.isStarted;
    const isStartedNow = afterData.isStarted;
    if (wasStarted === isStartedNow) return;

    // Determine titles and bodies for both languages
    let titleEn, titleAr, bodyEn, bodyAr;

    if (!wasStarted && isStartedNow) {
      titleEn = "Tracking Started";
      titleAr = "بدء تتبع الحجز";
      bodyEn =
        "The Technician has started tracking your location for the booking.";
      bodyAr = "يمكنك الآن تتبع حالة حجزك.";
    } else if (wasStarted && !isStartedNow) {
      titleEn = "Tracking Stopped";
      titleAr = "إيقاف تتبع الحجز";
      bodyEn = "Tracking has been stopped by the Technician.";
      bodyAr = "تم إيقاف تتبع موقعك بواسطة الفني.";
    }

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn,
      titleAr,
      bodyEn,
      bodyAr,
      data: {},
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
    console.log("✅ Final Message Object:", JSON.stringify(message, null, 2));
  }
);
exports.onBookingUpdateToTip = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    console.log(`Triggered for bookingId: ${bookingId}`);

    if (!after) {
      console.log("Document deleted, skipping.");
      return;
    }

    const wasTipPaid = before?.review?.isTipPaid || false;
    const isTipPaid = after?.review?.isTipPaid || false;
    const tipAmount = after?.review?.tipAmount || 0;
    const paymentType = after?.review?.paymentType || "cash"; // Get payment type

    if (isTipPaid && !wasTipPaid && tipAmount > 0) {
      console.log("New tip detected. Processing...");
    } else {
      console.log("No new tip paid or already processed. Skipping.");
      return;
    }

    const agent = after.agent;

    if (!agent?.uid) {
      console.error("Missing agent UID in booking data.");
      return;
    }
    const tippingWalletId = agent.uid;
    const tippingRef = db.collection("tipping").doc(tippingWalletId);

    try {
      await db.runTransaction(async (tx) => {
        const tippingDoc = await tx.get(tippingRef);

        // Get existing tip amounts based on new model structure
        const existingCashTip = tippingDoc.exists
          ? tippingDoc.data().cashtip || 0
          : 0;
        const existingCardTip = tippingDoc.exists
          ? tippingDoc.data().cardtip || 0
          : 0;

        // Determine which tip field to update based on payment type
        const isCardPayment =
          paymentType.toLowerCase() === "cards" ||
          paymentType.toLowerCase() === "card";

        const updateData = {
          walletId: tippingWalletId,
          agentId: agent.uid,
          agentName: agent.name || "",
          agentPhone: agent.phone || "",
          lastUpdated: FieldValue.serverTimestamp(),
          cashtip: isCardPayment
            ? existingCashTip
            : existingCashTip + tipAmount,
          cardtip: isCardPayment
            ? existingCardTip + tipAmount
            : existingCardTip,
          payoutRequested: false, // Add new field from model
        };

        if (!tippingDoc.exists) {
          console.log("Creating new tipping document.");
          tx.set(tippingRef, updateData);
        } else {
          console.log(
            `Updating tipping document. Current cash: ${existingCashTip}, card: ${existingCardTip}`
          );
          tx.update(tippingRef, updateData);
        }

        const agentFcmToken = agent.fcmToken;

        const tipType = isCardPayment ? "card" : "cash";

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: agent.uid,
          titleEn: "New Tip Received",
          titleAr: "تم استلام إكرامية جديدة",
          bodyEn: `You have received a new ${tipType} tip of ${tipAmount}.`,
          bodyAr: `لقد تلقيت إكرامية ${
            tipType === "card" ? "بطاقة" : "نقدية"
          } جديدة بقيمة ${tipAmount}.`,
          data: {
            category: "tip",
            amount: tipAmount.toString(),
            type: tipType,
          },
          fcmToken: agentFcmToken,
          lanCode: agent.lanCode || "en",
        });

        if (agentFcmToken && agentFcmToken.trim() !== "") {
          try {
            await admin.messaging().send(message);
            console.log(
              `Notification sent to agent ${agent.name} (${agent.uid})`
            );
          } catch (error) {
            console.error(
              "Error sending notification to agent:",
              error.message
            );
          }
        } else {
          console.warn(
            `No valid FCM token for agent ${agent.name} (${agent.uid})`
          );
        }
      });

      console.log(
        `Successfully updated ${
          isCardPayment ? "card" : "cash"
        } tip +${tipAmount} for agent ${agent.name} (${agent.uid})`
      );
    } catch (error) {
      console.error("Error processing tip update:", error);
    }
  }
);

exports.updateServiceRating = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const change = event.data;
    const afterData = change.after.exists ? change.after.data() : null;
    const beforeData = change.before.exists ? change.before.data() : null;

    const newRating = afterData?.review?.rating;
    const oldRating = beforeData?.review?.rating;

    if (typeof newRating !== "number") {
      console.log("No valid new rating found.");
      return null;
    }

    const serviceId = afterData?.service?.id;
    if (!serviceId) {
      console.log("No valid service ID found.");
      return null;
    }

    const serviceRef = admin.firestore().collection("services").doc(serviceId);

    await admin.firestore().runTransaction(async (transaction) => {
      const serviceDoc = await transaction.get(serviceRef);

      if (!serviceDoc.exists) {
        throw new Error("Service document does not exist.");
      }

      const data = serviceDoc.data();
      const currentTotal = data.totalRating || 0;
      const currentCount = data.ratingCount || 0;

      let updatedTotal = currentTotal;
      let updatedCount = currentCount;

      if (typeof oldRating !== "number") {
        updatedTotal += newRating;
        updatedCount += 1;
      } else if (oldRating !== newRating) {
        updatedTotal = updatedTotal - oldRating + newRating;
      }

      transaction.update(serviceRef, {
        totalRating: updatedTotal,
        ratingCount: updatedCount,
      });
    });

    console.log(`Processed rating: ${newRating} for service: ${serviceId}`);
    return null;
  }
);
exports.sendNotificationToFCM = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Only POST method is allowed");
  }

  const { fcmToken, title, body } = req.body;

  if (!fcmToken || !title || !body) {
    return res.status(400).send("Missing fcmToken, title, or body");
  }

  if (typeof fcmToken !== "string" || fcmToken.trim() === "") {
    return res.status(400).send("Invalid FCM token format");
  }

  console.log(`Sending notification to token: ${fcmToken.substring(0, 20)}...`);

  const message = {
    notification: {
      title,
      body,
    },
    token: fcmToken.trim(),
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notification sent to token:", fcmToken);
    return res.status(200).send({
      success: true,
      messageId: response,
    });
  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).send({
      success: false,
      error: error.message,
    });
  }
});

exports.notifyAdminsOnPayoutRequest = onDocumentCreated(
  "payoutRequests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const payoutRequest = snap.data();
    const requestId = event.params.requestId;
    const userId = payoutRequest.userId;
    const amount = payoutRequest.amount || "0";

    if (!userId) {
      console.log("No userId found in payout request");
      return null;
    }

    // Fetch worker details from users collection
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!workerDoc.exists) {
        console.log(`Worker document not found for userId: ${userId}`);
        return null;
      }

      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return null;
    }

    const workerName =
      workerData.name || workerData.fullName || "Unknown Worker";
    const workerPhone = workerData.phone || "";

    try {
      const adminUsersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            token: user.fcmToken,
            lanCode: user.lanCode || "en",
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      const results = [];

      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "New Payout Request",
          titleAr: "طلب دفع جديد",
          bodyEn: `${workerName} requested a payout of ₹${amount}`,
          bodyAr: `${workerName} طلب دفع بقيمة ₹${amount}`,
          data: {
            targetRole: "admin",
            category: "payout",
            requestId: requestId,
            workerId: userId,
            workerName: workerName,
            amount: amount,
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }

      console.log(
        `Notified ${
          results.filter((r) => r.success).length
        } admins about payout request`
      );
    } catch (error) {
      console.error("Error sending admin notifications:", error);
    }

    return null;
  }
);
exports.notifyWorkerOnPayoutStatusChange = onDocumentWritten(
  "payoutRequests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const requestId = event.params.requestId;

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    // Check if status changed
    const statusChanged = beforeData?.status !== afterData.status;
    if (!statusChanged) {
      console.log("Payout status did not change, skipping...");
      return;
    }

    const userId = afterData.userId;
    const status = afterData.status; // Expected: "pending", "approved", "rejected"

    if (!userId) {
      console.log("No userId found in payout request.");
      return;
    }

    // Only notify on approved or rejected, not pending
    if (status !== "approved" && status !== "rejected") {
      console.log(`Status ${status} doesn't require notification.`);
      return;
    }

    // Fetch worker details
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!workerDoc.exists) {
        console.log("Worker document not found.");
        return;
      }

      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return;
    }

    const fcmToken = workerData?.fcmToken;
    const lanCode = workerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token.");
      return;
    }

    const amount = afterData.amount || "0";
    const accountType = afterData.payoutAccount?.accountType || "";

    const statusMessages = {
      approved: {
        en: `Your payout request of ₹${amount} has been approved! The amount will be transferred to your ${accountType} account shortly.`,
        ar: `تمت الموافقة على طلب الدفع الخاص بك بقيمة ₹${amount}! سيتم تحويل المبلغ إلى حسابك ${accountType} قريبًا.`,
      },
      rejected: {
        en: `Your payout request of ₹${amount} has been rejected. Please contact support for more details.`,
        ar: `تم رفض طلب الدفع الخاص بك بقيمة ₹${amount}. يرجى الاتصال بالدعم لمزيد من التفاصيل.`,
      },
    };

    const notificationTitle = {
      approved: {
        en: "Payout Approved ✅",
        ar: "تمت الموافقة على الدفع ✅",
      },
      rejected: {
        en: "Payout Rejected ❌",
        ar: "تم رفض الدفع ❌",
      },
    };

    const notificationBody =
      statusMessages[status]?.[lanCode] || statusMessages[status]?.["en"];
    const title =
      notificationTitle[status]?.[lanCode] || notificationTitle[status]?.["en"];

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: userId,
      titleEn: notificationTitle[status]?.["en"],
      titleAr: notificationTitle[status]?.["ar"],
      bodyEn: statusMessages[status]?.["en"],
      bodyAr: statusMessages[status]?.["ar"],
      data: {
        targetRole: "worker",
        category: "payout",
        requestId: requestId,
        status: status,
        amount: amount,
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    try {
      await admin.messaging().send(message);
      console.log(
        `✅ Notification sent to worker ${userId} for payout status: ${status}`
      );
    } catch (error) {
      console.error("❌ Error sending FCM notification:", error);

      // Handle invalid token errors
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        console.log(
          `Invalid FCM token for user ${userId}, consider removing it from database`
        );
      }
    }
  }
);

exports.notifyWorkerOnNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const booking = snap.data();
    const bookingId = event.params.bookingId;

    // Only notify for pending bookings
    if (booking.bookingStatusCode !== "P") {
      console.log("Booking is not pending, skipping worker notification.");
      return null;
    }

    // Get the selected worker/agent details
    const agent = booking.agent;
    if (!agent || !agent.uid) {
      console.log("No worker assigned to this booking.");
      return null;
    }

    const workerId = agent.uid;
    const serviceName = booking.service?.name || "Service";
    const customerName = booking.customer?.name || "A customer";

    // Fetch worker details from users collection
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(workerId)
        .get();

      if (!workerDoc.exists) {
        console.log("Worker document not found.");
        return null;
      }
      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return null;
    }

    const fcmToken = workerData?.fcmToken;
    const lanCode = workerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token.");
      return null;
    }

    // Prepare notification messages
    const notificationTitle = {
      en: "New Booking Request!",
      ar: "طلب حجز جديد!",
    };

    const notificationBody = {
      en: `A customer has requested ${serviceName}. Please review and accept the booking.`,
      ar: `طلب عميل ${serviceName}. يرجى المراجعة وقبول الحجز.`,
    };

    const title = notificationTitle[lanCode] || notificationTitle["en"];
    const body = notificationBody[lanCode] || notificationBody["en"];

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: workerId,
      titleEn: notificationTitle["en"],
      titleAr: notificationTitle["ar"],
      bodyEn: notificationBody["en"],
      bodyAr: notificationBody["ar"],
      data: {
        targetRole: "worker",
        category: "booking",
        bookingId: bookingId,
        serviceName: serviceName,
        customerName: customerName,
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    try {
      const response = await admin.messaging().send(message);
      console.log(
        `Notification sent to worker ${workerId} for new booking ${bookingId}. MessageId: ${response}`
      );
    } catch (error) {
      console.error("Error sending FCM notification to worker:", error);
    }

    return null;
  }
);

exports.notifyAdminsOnTipPayoutRequest = onDocumentWritten(
  "tipping/{walletId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const walletId = event.params.walletId;

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    // Check if payoutRequested changed from false to true
    const wasRequested = beforeData?.payoutRequested === true;
    const isRequestedNow = afterData.payoutRequested === true;

    if (!isRequestedNow || wasRequested) {
      console.log("No new payout request detected, skipping...");
      return;
    }

    const agentName = afterData.agentName || "A worker";
    const agentId = afterData.agentId;
    const totalTip = afterData.totalTip || 0;

    // Fetch all admin users
    try {
      const adminUsersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            uid: doc.id,
            token: user.fcmToken,
            lanCode: user.lanCode || "en",
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      // Send notification to each admin
      const results = [];
      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "Tip Payout Request",
          titleAr: "طلب سحب إكرامية",
          bodyEn: `${agentName} requested a tip payout of ₹${totalTip}. Please review and approve.`,
          bodyAr: `${agentName} طلب سحب إكرامية بمبلغ ${totalTip}. يرجى المراجعة والموافقة.`,
          data: {
            targetRole: "admin",
            category: "tip_payout",
            walletId: walletId,
            agentId: agentId,
            agentName: agentName,
            amount: totalTip.toString(),
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }

      console.log(
        `Notified ${
          results.filter((r) => r.success).length
        } admins about tip payout request.`
      );
    } catch (error) {
      console.error("Error sending admin notifications:", error);
      return null;
    }
  }
);

exports.notifyWorkerOnTipPayoutProcessed = onDocumentWritten(
  "tipping/{walletId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const walletId = event.params.walletId;

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    // Check if payoutRequested changed from true to false (payout processed)
    const wasRequested = beforeData?.payoutRequested === true;
    const isRequestedNow = afterData.payoutRequested === true;

    if (!wasRequested || isRequestedNow) {
      console.log("No payout processing detected, skipping...");
      return;
    }

    const agentId = afterData.agentId;
    const totalTip = afterData.totalTip || 0;

    if (!agentId) {
      console.log("No agentId found in tipping document.");
      return;
    }

    // Fetch worker details from users collection
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(agentId)
        .get();

      if (!workerDoc.exists) {
        console.log("Worker document not found.");
        return;
      }
      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return;
    }

    const fcmToken = workerData?.fcmToken;
    const lanCode = workerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token.");
      return;
    }

    // Prepare notification
    const notificationTitle = {
      en: "Tip Payout Processed",
      ar: "تم معالجة سحب الإكرامية",
    };

    const notificationBody = {
      en: `Your tip payout of ₹${totalTip} has been processed successfully. The amount will be transferred to your account shortly.`,
      ar: `تم معالجة سحب الإكرامية بمبلغ ₹${totalTip} بنجاح. سيتم تحويل المبلغ إلى حسابك قريبًا.`,
    };

    const title = notificationTitle[lanCode] || notificationTitle["en"];
    const body = notificationBody[lanCode] || notificationBody["en"];

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: agentId,
      titleEn: notificationTitle["en"],
      titleAr: notificationTitle["ar"],
      bodyEn: notificationBody["en"],
      bodyAr: notificationBody["ar"],
      data: {
        targetRole: "worker",
        category: "tip_payout",
        walletId: walletId,
        amount: totalTip.toString(),
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    try {
      await admin.messaging().send(message);
      console.log(`Tip payout notification sent to worker ${agentId}`);
    } catch (error) {
      console.error("Error sending FCM notification to worker:", error);
    }
  }
);
// ============================================
// Send Custom Notification to Technicians (Bilingual)
// ============================================
exports.sendCustomNotificationToTechnicians = onDocumentCreated(
  "notification_queue/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const data = snap.data();
    const docId = event.params.docId;
    const recipientId = data.recipientId;

    // Support both old format (single language) and new format (bilingual)
    const titleEn = data.titleEn || data.title || null;
    const bodyEn = data.bodyEn || data.body || null;
    const titleAr = data.titleAr || null;
    const bodyAr = data.bodyAr || null;

    if (!recipientId) {
      console.log("Missing recipientId in notification_queue");
      await snap.ref.update({
        processed: true,
        error: "Missing recipientId",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // Validate at least one language has content
    if ((!titleEn && !titleAr) || (!bodyEn && !bodyAr)) {
      console.log(
        "Missing required fields - at least one language must have title and body"
      );
      await snap.ref.update({
        processed: true,
        error: "Missing content in both languages",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      // Get technician's FCM token and language preference
      const techDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();

      if (!techDoc.exists) {
        console.log(`Technician document not found for ID: ${recipientId}`);
        await snap.ref.update({
          processed: true,
          error: "Technician not found",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const techData = techDoc.data();
      const fcmToken = techData?.fcmToken;
      const lanCode = techData?.lanCode || "en";

      if (!fcmToken || fcmToken.trim() === "") {
        console.log(`No valid FCM token for technician: ${recipientId}`);
        await snap.ref.update({
          processed: true,
          error: "No valid FCM token",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // Select notification text based on technician's language preference
      let notificationTitle, notificationBody;

      if (lanCode === "ar" && titleAr && bodyAr) {
        // If technician prefers Arabic and Arabic content is available, send Arabic
        notificationTitle = titleAr;
        notificationBody = bodyAr;
        console.log(`Sending Arabic notification to technician ${recipientId}`);
      } else if (titleEn && bodyEn) {
        // Otherwise send English (default fallback)
        notificationTitle = titleEn;
        notificationBody = bodyEn;
        console.log(
          `Sending English notification to technician ${recipientId}`
        );
      } else if (titleAr && bodyAr) {
        // If only Arabic is available, send Arabic
        notificationTitle = titleAr;
        notificationBody = bodyAr;
        console.log(`Sending Arabic notification to technician ${recipientId}`);
      } else {
        throw new Error("No valid notification content available");
      }

      // Send FCM notification
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: "custom",
          sentAt: new Date().toISOString(),
          recipientId: recipientId,
          language: lanCode,
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "abo_glumbo_channel",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title: notificationTitle,
                body: notificationBody,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);

      // Update notification in Firestore with both language versions
      const notificationRef = admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .collection("notifications")
        .doc();

      await notificationRef.set({
        titleEn: titleEn,
        bodyEn: bodyEn,
        titleAr: titleAr,
        bodyAr: bodyAr,
        // Store the sent notification text for history
        sentTitle: notificationTitle,
        sentBody: notificationBody,
        sentLanguage: lanCode,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        type: "custom",
        fcmMessageId: response,
      });

      // Mark queue document as processed
      await snap.ref.update({
        processed: true,
        fcmMessageId: response,
        sentLanguage: lanCode,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ Custom notification sent to technician ${recipientId} in ${lanCode}. MessageId: ${response}`
      );
    } catch (error) {
      console.error(
        `❌ Error sending custom notification to ${recipientId}:`,
        error
      );
      await snap.ref.update({
        processed: true,
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

exports.notifyCustomerOnWorkerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if cancelledWorkerUids array changed (new cancellation)
    const beforeCancelledCount = beforeData.cancelledWorkerUids?.length || 0;
    const afterCancelledCount = afterData.cancelledWorkerUids?.length || 0;

    // Only proceed if a worker was just added to cancelledWorkerUids
    if (afterCancelledCount <= beforeCancelledCount) {
      return;
    }

    try {
      // Get the customer data to retrieve FCM token
      const customerDoc = await db
        .collection("customers")
        .doc(afterData.customer.id)
        .get();

      if (!customerDoc.exists) {
        console.log("Customer document not found");
        return;
      }

      const customerData = customerDoc.data();
      const customerFcmToken = customerData.fcmToken;

      if (!customerFcmToken) {
        console.log("Customer FCM token not found");
        return;
      }

      // Get the worker details who just cancelled from CancelledWorkers array
      const cancelledWorkers = afterData.cancelledWorkers || [];
      const lastCancelledWorker = cancelledWorkers[cancelledWorkers.length - 1];

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName =
        customerData.lanCode === "ar"
          ? serviceData.name_ar || serviceData.name
          : serviceData.name;

      const customerLanCode = customerData.lanCode || "en";

      await sendAndStoreNotification({
        targetRole: "customer",
        targetId: afterData.customer.id,
        titleEn: "Booking Rejected",
        titleAr: "تم رفض الحجز",
        bodyEn: `A Technician rejected your booking for ${serviceName}.`,
        bodyAr: `لقد قام الفني برفض حجزك ل ${serviceName}.`,
        data: {
          bookingId: afterData.id,
          bookingStatusCode: afterData.bookingStatusCode,
          cancelledWorkerName: lastCancelledWorker.agentName,
          cancelledWorkerCount: afterCancelledCount.toString(),
          bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
        },
        fcmToken: customerFcmToken,
        lanCode: customerLanCode,
      });

      console.log(
        `✅ Customer notification sent for booking ${afterData.id} - Worker ${lastCancelledWorker.agentName} rejected`
      );
    } catch (error) {
      console.error(
        `❌ Error sending customer cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyAdminsOnWorkerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if cancelledWorkerUids array changed (new cancellation)
    const beforeCancelledCount = beforeData.cancelledWorkerUids?.length || 0;
    const afterCancelledCount = afterData.cancelledWorkerUids?.length || 0;

    // Only proceed if a worker was just added to cancelledWorkerUids
    if (afterCancelledCount <= beforeCancelledCount) {
      return;
    }

    try {
      // Get the worker details who just cancelled from CancelledWorkers array
      const cancelledWorkers = afterData.cancelledWorkers || [];
      const lastCancelledWorker = cancelledWorkers[cancelledWorkers.length - 1];

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Fetch all admin users with FCM tokens
      const adminsSnapshot = await db
        .collection("users")
        .where("isAdmin", "==", true)
        .where("fcmToken", "!=", null)
        .get();

      if (adminsSnapshot.empty) {
        console.log("No admin users found with FCM tokens");
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminsSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData.fcmToken;
        const adminLanCode = adminData.lanCode || "en";

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "Technician Cancelled A Booking",
          titleAr: "الفني قام برفض الحجز",
          bodyEn: `${lastCancelledWorker.agentName} rejected booking for ${serviceName} from ${customerName}. Please review and assign a new Technician.`,
          bodyAr: `${lastCancelledWorker.agentName} رفض حجزك ل${serviceNameAr} من ${customerName}. يرجى مراجعة وتعيين فني جديد.`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            cancelledWorkerName: lastCancelledWorker.agentName,
            cancelledWorkerUid: lastCancelledWorker.uid,
            cancelledWorkerCount: afterCancelledCount.toString(),
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            totalCancelledWorkers: afterCancelledCount.toString(),
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }
      console.log(
        `✅ Admin notifications sent for booking ${afterData.id} - Worker ${lastCancelledWorker.agentName} rejected`
      );
    } catch (error) {
      console.error(
        `❌ Error sending admin cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyWorkersOnCustomerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if booking status changed to XC (customer cancelled)
    if (
      beforeData.bookingStatusCode !== afterData.bookingStatusCode ||
      afterData.bookingStatusCode !== "XC"
    ) {
      return;
    }

    try {
      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Get list of workers who were assigned or cancelled this booking
      const cancelledWorkerUids = afterData.cancelledWorkerUids || [];
      const agent = afterData.agent;

      // Collect all worker UIDs (both cancelled workers and assigned agent)
      let workerUids = [...cancelledWorkerUids];
      if (agent && agent.uid && !workerUids.includes(agent.uid)) {
        workerUids.push(agent.uid);
      }

      if (workerUids.length === 0) {
        console.log("No workers to notify");
        return;
      }

      // Fetch all workers who were involved with this booking
      const workersSnapshot = await db
        .collection("users")
        .where("__name__", "in", workerUids.slice(0, 10)) // Firestore limits 'in' to 10 items
        .get();

      if (workersSnapshot.empty) {
        console.log("No workers found with FCM tokens");
        return;
      }

      // Send notification to each worker
      for (const workerDoc of workersSnapshot.docs) {
        const workerData = workerDoc.data();
        const workerFcmToken = workerData.fcmToken;
        const workerLanCode = workerData.lanCode || "en";

        if (!workerFcmToken) continue;

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: workerDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. You can no longer accept this booking.`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. لن تتمكن من قبول هذا الحجز.`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            cancelledBy: "customer",
          },
          fcmToken: workerFcmToken,
          lanCode: workerLanCode,
        });
      }
      console.log(
        `✅ Worker notifications sent for booking ${afterData.id} - Customer cancelled`
      );
    } catch (error) {
      console.error(
        `❌ Error sending worker cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyAdminsOnCustomerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if booking status changed to XC (customer cancelled)
    if (
      beforeData.bookingStatusCode !== afterData.bookingStatusCode ||
      afterData.bookingStatusCode !== "XC"
    ) {
      return;
    }

    try {
      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Get cancellation reason if available
      const cancellationReason = afterData.cancellationReason || "Not provided";

      // Fetch all admin users with FCM tokens
      const adminsSnapshot = await db
        .collection("users")
        .where("isAdmin", "==", true)
        .where("fcmToken", "!=", null)
        .get();

      if (adminsSnapshot.empty) {
        console.log("No admin users found with FCM tokens");
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminsSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData.fcmToken;
        const adminLanCode = adminData.lanCode || "en";

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. Reason: ${cancellationReason}`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. السبب: ${cancellationReason}`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            cancellationReason: cancellationReason,
            cancelledBy: "customer",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }
      console.log(
        `✅ Admin notifications sent for booking ${afterData.id} - Customer cancelled`
      );
    } catch (error) {
      console.error(
        `❌ Error sending admin cancellation notification: ${error}`
      );
    }
  }
);
exports.notifyAdminsOnNewWorkerSignup = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const worker = snap.data();
    const userId = event.params.userId;

    // Only notify for new workers (not admins or customers)
    if (worker.isAdmin === true) {
      console.log("User is admin, skipping notification.");
      return null;
    }

    // Optional: Check if worker has job roles (indicating they're a worker, not a customer)
    if (!worker.jobRoles || worker.jobRoles.length === 0) {
      console.log(
        "User has no job roles, might not be a Technician yet. Skipping notification."
      );
      return null;
    }

    const workerName = worker.name || "A new worker";
    const workerPhone = worker.phone || "Not provided";
    const workerEmail = worker.email || "Not provided";
    const jobRoles = worker.jobRoles
      ? worker.jobRoles.join(", ")
      : "Not specified";
    const districtName = worker.districtName || "Not specified";

    try {
      // Fetch all admin users
      const adminUsersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            token: user.fcmToken,
            lanCode: user.lanCode || "en",
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      const results = [];

      // Send notification to each admin
      for (const { token, lanCode } of tokensWithLanguage) {
        try {
          const message = {
            notification: {
              title:
                lanCode === "ar"
                  ? "فني جديد انضم!"
                  : "New Technician Signed Up!",
              body:
                lanCode === "ar"
                  ? `${workerName} قام بالتسجيل كفني جديد. يرجى مراجعة الملف الشخصي والموافقة عليه`
                  : `${workerName} has signed up as a new Technician. Please review their profile and approve`,
            },
            data: {
              targetRole: "admin",
              category: "worker_signup",
              workerId: userId,
              workerName: workerName,
              workerPhone: workerPhone,
              jobRoles: jobRoles,
              districtName: districtName,
            },
            token: token,
          };

          const response = await admin.messaging().send(message);
          results.push({ token, success: true, messageId: response });
          console.log(
            `Notification sent to admin with token: ${token.substring(
              0,
              20
            )}...`
          );
        } catch (error) {
          results.push({ token, success: false, error: error.message });
          console.error(`Failed to send to token: ${error.message}`);
        }
      }

      console.log(
        `Notified ${
          results.filter((r) => r.success).length
        } admins about new worker signup: ${workerName}`
      );
    } catch (error) {
      console.error("Error sending admin notifications:", error);
    }

    return null;
  }
);
exports.notifyWorkerOnPaymentComplete = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const bookingId = event.params.bookingId;

    // Check if paymentCompleted changed from false to true
    const wasPaymentPending = beforeData.paymentCompleted === false;
    const isPaymentCompleted = afterData.paymentCompleted === true;

    // Only trigger when payment status changes AND booking is completed
    if (!wasPaymentPending || !isPaymentCompleted) {
      console.log(
        "Payment status unchanged or already completed. Skipping notification."
      );
      return null;
    }

    // Verify booking is in completed status
    if (afterData.bookingStatusCode !== "C") {
      console.log("Booking is not in completed status. Skipping notification.");
      return null;
    }

    // Get worker details
    const agent = afterData.agent;
    if (!agent || !agent.fcmToken) {
      console.log("No agent assigned or agent has no FCM token.");
      return null;
    }

    const workerToken = agent.fcmToken;
    const workerLanCode = agent.lanCode || "en";
    const customerName = afterData.customer?.name || "Customer";
    const serviceName = afterData.service?.serviceName || "Service";

    // Get payment details
    const totalCost = afterData.completionData?.totalCost || 0;
    const paymentMethod =
      afterData.completionData?.paymentMethod || afterData.paymentModeCode;

    try {
      const message = {
        notification: {
          title:
            workerLanCode === "ar"
              ? "تم استلام الدفع! 💰"
              : "Payment Received! 💰",
          body:
            workerLanCode === "ar"
              ? `${customerName} أكمل الدفع بمبلغ ${totalCost.toFixed(2)}`
              : `${customerName} completed payment of ${totalCost.toFixed(2)}`,
        },
        data: {
          targetRole: "worker",
          category: "payment_completed",
          bookingId: bookingId,
          customerName: customerName,
          serviceName: serviceName,
          totalCost: totalCost.toString(),
          paymentMethod: paymentMethod,
          bookingStatusCode: afterData.bookingStatusCode,
        },
        token: workerToken,
      };

      const response = await admin.messaging().send(message);
      console.log(
        `Payment completion notification sent to worker ${agent.uid}: ${response}`
      );

      return { success: true, messageId: response };
    } catch (error) {
      console.error("Error sending payment notification to worker:", error);
      return { success: false, error: error.message };
    }
  }
);
// ============================================
// Warranty Request Notifications
// ============================================
exports.notifyOnWarrantyRequestStatusChange = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!afterData) {
      console.log("Booking document deleted, skipping warranty check...");
      return;
    }

    const beforeWarranty = beforeData?.warranty;
    const afterWarranty = afterData?.warranty;

    // Check if warranty exists in afterData
    if (!afterWarranty) {
      return;
    }

    // Determine status change
    let status = null;
    let isTechnicianRejection = false;

    // 1. Warranty Placed (New warranty object created)
    if (!beforeWarranty && afterWarranty) {
      status = "placed";
    }
    // 2. Accepted (claimStatus changed to true)
    else if (!beforeWarranty?.claimStatus && afterWarranty.claimStatus) {
      status = "accepted";
    }
    // 3. Tracking Started (isTracking changed to true)
    else if (!beforeWarranty?.isTracking && afterWarranty.isTracking) {
      status = "tracking_started";
    }
    // 4. Completed (completed changed to true)
    else if (!beforeWarranty?.completed && afterWarranty.completed) {
      status = "completed";
    }
    // 5. Technician Rejected (rejectedTechnicians array grew)
    else if (
      (beforeWarranty?.rejectedTechnicians?.length || 0) <
      (afterWarranty.rejectedTechnicians?.length || 0)
    ) {
      isTechnicianRejection = true;
      status = "technician_rejected";
    }
    // 6. Cancelled (availability changed to false AND not expired)
    else if (
      beforeWarranty?.availability === true &&
      afterWarranty.availability === false &&
      !afterWarranty.expiredAt // Avoid triggering on cron job expiration
    ) {
      status = "cancelled";
    }

    if (!status) {
      return;
    }

    console.log(
      `Warranty status changed to ${status} for booking ${bookingId}`
    );

    const customerId = afterData.customer?.uid;
    const serviceName = afterData.service?.name || "Service";
    const workerId = afterWarranty.assignedTechnicianId || afterData.agent?.uid;

    // Fetch customer data for notification
    let customerData;
    if (customerId) {
      try {
        const customerDoc = await admin
          .firestore()
          .collection("customers")
          .doc(customerId)
          .get();

        if (customerDoc.exists) {
          customerData = customerDoc.data();
        }
      } catch (error) {
        console.error("Error fetching customer data:", error);
      }
    }

    // Fetch admin users
    let adminTokens = [];
    try {
      const adminSnapshot = await admin
        .firestore()
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      adminTokens = adminSnapshot.docs
        .map((doc) => {
          const data = doc.data();
          return data.fcmToken && data.fcmToken.trim() !== ""
            ? { token: data.fcmToken, lanCode: data.lanCode || "en" }
            : null;
        })
        .filter(Boolean);
    } catch (error) {
      console.error("Error fetching admin users:", error);
    }

    // Status-specific messages
    const statusMessages = {
      placed: {
        customer: {
          en: "Your warranty request has been submitted successfully.",
          ar: "تم تقديم طلب الضمان الخاص بك بنجاح.",
        },
        admin: {
          en: "A new warranty request has been placed.",
          ar: "تم تقديم طلب ضمان جديد.",
        },
      },
      accepted: {
        customer: {
          en: "Your warranty request has been accepted. A technician will contact you soon.",
          ar: "تم قبول طلب الضمان الخاص بك. سيتصل بك فني قريبًا.",
        },
        admin: {
          en: "Warranty request has been accepted by a technician.",
          ar: "تم قبول طلب الضمان من قبل فني.",
        },
      },
      tracking_started: {
        customer: {
          en: "The technician is on the way. You can now track their location.",
          ar: "الفني في الطريق. يمكنك الآن تتبع موقعه.",
        },
        admin: {
          en: "Technician started tracking for warranty request.",
          ar: "بدأ الفني التتبع لطلب الضمان.",
        },
      },
      completed: {
        customer: {
          en: "Your warranty service has been completed successfully. We hope you're satisfied with the service!",
          ar: "تم إكمال خدمة الضمان الخاصة بك بنجاح. نأمل أن تكون راضيًا عن الخدمة!",
        },
        admin: {
          en: "Warranty request has been completed.",
          ar: "تم إكمال طلب الضمان.",
        },
      },
      technician_rejected: {
        customer: {
          en: "A technician rejected your warranty request. We are looking for another one.",
          ar: "رفض فني طلب الضمان الخاص بك. نحن نبحث عن فني آخر.",
        },
        admin: {
          en: "A technician rejected a warranty request.",
          ar: "رفض فني طلب ضمان.",
        },
      },
      cancelled: {
        customer: {
          en: "Your warranty request has been cancelled.",
          ar: "تم إلغاء طلب الضمان الخاص بك.",
        },
        admin: {
          en: "A warranty request has been cancelled.",
          ar: "تم إلغاء طلب ضمان.",
        },
      },
    };

    // Notify customer
    if (customerData?.fcmToken && customerData.fcmToken.trim() !== "") {
      const customerLanCode = customerData.lanCode || "en";
      const customerMessage =
        statusMessages[status]?.customer?.[customerLanCode] ||
        statusMessages[status]?.customer?.["en"] ||
        `Your warranty request status has been updated to ${status}`;

      try {
        await admin.messaging().send({
          notification: {
            title:
              customerLanCode === "ar"
                ? "تحديث طلب الضمان"
                : "Warranty Request Update",
            body: `${customerMessage} (${serviceName})`,
          },
          data: {
            targetRole: "customer",
            category: "warranty",
            bookingId: bookingId,
            status: status,
            serviceName: serviceName,
          },
          token: customerData.fcmToken,
        });
        console.log(
          `Warranty notification sent to customer ${customerId} for status: ${status}`
        );
      } catch (error) {
        console.error("Error sending customer warranty notification:", error);
      }
    }

    // Notify admins
    if (adminTokens.length > 0) {
      const adminMessages = adminTokens.map(({ token, lanCode }) => ({
        notification: {
          title:
            lanCode === "ar" ? "تحديث طلب الضمان" : "Warranty Request Update",
          body:
            statusMessages[status]?.admin?.[lanCode] ||
            statusMessages[status]?.admin?.["en"] ||
            `Warranty request for booking ${bookingId} updated to ${status}`,
        },
        token,
        data: {
          targetRole: "admin",
          category: "warranty",
          bookingId: bookingId,
          customerId: customerId || "",
          workerId: workerId || "",
          status: status,
          serviceName: serviceName,
        },
      }));

      try {
        await Promise.all(
          adminMessages.map((msg) => admin.messaging().send(msg))
        );
        console.log(
          `Warranty notification sent to ${adminTokens.length} admins for status: ${status}`
        );
      } catch (error) {
        console.error("Error sending admin warranty notifications:", error);
      }
    }

    return null;
  }
);

// ============================================
// Update Warranty Availability After 7 Days
// ============================================
exports.updateWarrantyAvailability = onSchedule(
  {
    schedule: "0 2 * * *", // Runs daily at 2:00 AM Saudi Arabia Time
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    logger.info("Starting warranty availability update check...");

    try {
      // Calculate the date 7 days ago from now
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      sevenDaysAgo.setHours(0, 0, 0, 0); // Start of the day

      const eightDaysAgo = new Date();
      eightDaysAgo.setDate(eightDaysAgo.getDate() - 8);
      eightDaysAgo.setHours(0, 0, 0, 0);

      logger.info(
        `Checking bookings completed between ${eightDaysAgo.toISOString()} and ${sevenDaysAgo.toISOString()}`
      );

      // Query completed bookings that have warranty enabled and completed exactly 7 days ago
      const bookingsSnapshot = await db
        .collection("bookings")
        .where("bookingStatusCode", "==", "C") // Completed bookings
        .where("warranty.availability", "==", true) // Warranty still available
        .where(
          "completedAt",
          ">=",
          admin.firestore.Timestamp.fromDate(eightDaysAgo)
        )
        .where(
          "completedAt",
          "<=",
          admin.firestore.Timestamp.fromDate(sevenDaysAgo)
        )
        .get();

      if (bookingsSnapshot.empty) {
        logger.info("No bookings found with warranty expiring today.");
        return null;
      }

      let updatedCount = 0;
      const batch = db.batch();
      const batchSize = 500; // Firestore batch limit
      let batchCount = 0;

      for (const bookingDoc of bookingsSnapshot.docs) {
        const bookingData = bookingDoc.data();
        const completedAt = bookingData.completedAt?.toDate();

        if (!completedAt) {
          logger.warn(
            `Booking ${bookingDoc.id} has no completedAt timestamp, skipping.`
          );
          continue;
        }

        // Calculate days since completion
        const daysSinceCompletion = Math.floor(
          (new Date() - completedAt) / (1000 * 60 * 60 * 24)
        );

        // Only update if exactly 7 or more days have passed
        if (daysSinceCompletion >= 7) {
          const bookingRef = bookingDoc.ref;

          // Update warranty availability to false
          batch.update(bookingRef, {
            "warranty.availability": false,
            "warranty.expiredAt": admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          updatedCount++;
          batchCount++;

          logger.info(
            `Scheduled warranty expiration for booking ${bookingDoc.id} (completed ${daysSinceCompletion} days ago)`
          );

          // Commit batch every 500 operations
          if (batchCount >= batchSize) {
            await batch.commit();
            logger.info(`Committed batch of ${batchCount} updates`);
            batchCount = 0;
          }
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        logger.info(`Committed final batch of ${batchCount} updates`);
      }

      logger.info(
        `Warranty availability update completed. Total bookings updated: ${updatedCount}`
      );
      return null;
    } catch (error) {
      logger.error("Error updating warranty availability:", error);
      throw error;
    }
  }
);

exports.notifyOnNewChatMessage = onValueCreated(
  "messages/{chatId}/{messageId}",
  async (event) => {
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const messageData = event.data.val();

    if (!messageData) {
      console.log(`[${chatId}] No message data found`);
      return null;
    }

    const senderId = messageData.senderId;
    const senderType = messageData.senderType; // 'technician', 'admin', or 'customer'
    const messageText = messageData.text || "";
    const mediaType = messageData.mediaType;

    console.log(
      `[${chatId}] New message from ${senderType} (${senderId}): ${messageText}`
    );

    try {
      // Get chat details from Realtime Database
      const rtdb = admin.database();
      const chatSnapshot = await rtdb.ref(`chats/${chatId}`).once("value");

      if (!chatSnapshot.exists()) {
        console.log(`[${chatId}] Chat not found`);
        return null;
      }

      const chatData = chatSnapshot.val();
      const participants = chatData.participants || {};

      // Determine receiver ID (the participant who is NOT the sender)
      let receiverId = null;
      let receiverType = null;

      for (const [userId, userType] of Object.entries(participants)) {
        if (userId !== senderId) {
          receiverId = userId;
          receiverType = userType;
          break;
        }
      }

      if (!receiverId) {
        console.log(`[${chatId}] No receiver found`);
        return null;
      }

      console.log(`[${chatId}] Receiver: ${receiverType} (${receiverId})`);

      // Get sender's name from their user/customer document
      let senderName = "Someone";
      try {
        if (senderType === "customer") {
          const senderDoc = await db
            .collection("customers")
            .doc(senderId)
            .get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = senderData.name || senderData.fullName || "Customer";
          }
        } else {
          // technician or admin
          const senderDoc = await db.collection("users").doc(senderId).get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = senderData.name || senderData.fullName || "Technician";
          }
        }
      } catch (error) {
        console.error(`[${chatId}] Error fetching sender name:`, error);
      }

      // Get receiver's FCM token and language preference
      let receiverFcmToken = null;
      let receiverLanCode = "en";

      try {
        if (receiverType === "customer") {
          const receiverDoc = await db
            .collection("customers")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverFcmToken = receiverData.fcmToken;
            receiverLanCode = receiverData.lanCode || "en";
          }
        } else {
          // technician or admin
          const receiverDoc = await db
            .collection("users")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverFcmToken = receiverData.fcmToken;
            receiverLanCode = receiverData.lanCode || "en";
          }
        }
      } catch (error) {
        console.error(`[${chatId}] Error fetching receiver data:`, error);
        return null;
      }

      if (!receiverFcmToken || receiverFcmToken.trim() === "") {
        console.log(`[${chatId}] Receiver has no valid FCM token`);
        return null;
      }

      // Prepare notification message
      let notificationBody = messageText;

      // Handle media messages
      if (mediaType === "image") {
        notificationBody = receiverLanCode === "ar" ? "📷 صورة" : "📷 Photo";
      } else if (mediaType === "video") {
        notificationBody = receiverLanCode === "ar" ? "🎥 فيديو" : "🎥 Video";
      }

      // Truncate long messages
      if (notificationBody.length > 100) {
        notificationBody = notificationBody.substring(0, 97) + "...";
      }

      const notificationTitle =
        receiverLanCode === "ar"
          ? `رسالة جديدة من ${senderName}`
          : `New message from ${senderName}`;

      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: "chat_message",
          chatId: chatId,
          senderId: senderId,
          senderType: senderType,
          senderName: senderName,
          messageId: messageId,
          bookingId: chatData.bookingId || "",
          targetRole: receiverType,
        },
        token: receiverFcmToken,
      };

      try {
        const response = await admin.messaging().send(message);
        console.log(
          `[${chatId}] Notification sent successfully to ${receiverType}:`,
          response
        );
      } catch (error) {
        console.error(`[${chatId}] Error sending notification:`, error);
      }

      return null;
    } catch (error) {
      console.error(`[${chatId}] Error in notifyOnNewChatMessage:`, error);
      return null;
    }
  }
);
// ============================================
// REWARDS SYSTEM CLOUD FUNCTIONS
// ============================================

// Function 1: Reset Tiers Monthly (1st at 00:00 Saudi Arabia Time)
// Resets all worker tier progress at the start of each month
// ============================================
exports.resetMonthlyTiers = onSchedule(
  {
    schedule: "0 0 1 * *", // 1st of every month at 00:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    logger.info("Starting monthly tier reset...");

    try {
      const usersSnapshot = await db.collection("users").get();
      let totalResets = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        const tiersSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("tiers")
          .get();

        const batch = db.batch();

        for (const tierDoc of tiersSnapshot.docs) {
          const tierRef = tierDoc.ref;
          const tierData = tierDoc.data();

          batch.update(tierRef, {
            tier: "Bronze",
            currentMonthJobs: 0,
            currentMonthRating: 0.0,
            lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
            previousMonthTier: tierData.tier || "Bronze",
            previousMonthJobs: tierData.currentMonthJobs || 0,
            previousMonthRating: tierData.currentMonthRating || 0.0,
          });

          totalResets++;
        }

        if (tiersSnapshot.docs.length > 0) {
          await batch.commit();
        }
      }

      logger.info(`Monthly tier reset completed. Total resets: ${totalResets}`);
      return null;
    } catch (error) {
      logger.error("Error resetting tiers:", error);
      throw error;
    }
  }
);

// ============================================
// Function 2: Calculate and Apply Monthly Bonuses
// Runs on 1st of month at 01:00 (after reset at 00:00)
// Calculates bonuses for PREVIOUS month and adds them
// Example: January's bonus is calculated and added on February 1st
// ============================================
exports.applyMonthlyBonus = onSchedule(
  {
    schedule: "0 1 1 * *", // 1st of every month at 01:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    const today = new Date();

    // Calculate for PREVIOUS month
    const previousMonth = new Date(today);
    previousMonth.setMonth(previousMonth.getMonth() - 1);

    const previousMonthStr = previousMonth.toLocaleString("en-US", {
      month: "long",
      year: "numeric",
    });

    logger.info(`Calculating bonuses for ${previousMonthStr}...`);

    try {
      const usersSnapshot = await db.collection("users").get();
      let totalBonusesApplied = 0;
      let totalBonusAmount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        const tiersSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("tiers")
          .get();

        for (const tierDoc of tiersSnapshot.docs) {
          const tierData = tierDoc.data();
          const categoryId = tierDoc.id;

          // Check if bonus already applied for this month
          const lastBonusMonth = tierData.lastBonusMonth;
          const currentMonthKey = `${today.getFullYear()}-${
            today.getMonth() + 1
          }`;

          if (lastBonusMonth === currentMonthKey) {
            logger.info(
              `Bonus already applied for user ${userId}, category ${categoryId}`
            );
            continue;
          }

          // Use PREVIOUS month's data (stored before reset)
          const jobs = tierData.previousMonthJobs || 0;
          const rating = tierData.previousMonthRating || 0.0;
          const previousTier = tierData.previousMonthTier || "Bronze";

          // Calculate tier and bonus percentage based on previous month performance
          let tier = "Bronze";
          let bonusPercentage = 0;

          if (rating >= 4.8 && jobs >= 60) {
            tier = "Platinum";
            bonusPercentage = 0.15;
          } else if (rating >= 4.5 && jobs >= 40) {
            tier = "Gold";
            bonusPercentage = 0.1;
          } else if (rating >= 4.0 && jobs >= 20) {
            tier = "Silver";
            bonusPercentage = 0.05;
          }

          if (bonusPercentage === 0) {
            logger.info(
              `User ${userId} in Bronze tier for category ${categoryId}. No bonus.`
            );
            continue;
          }

          // Calculate earnings from PREVIOUS month
          const firstDayOfPrevMonth = new Date(
            previousMonth.getFullYear(),
            previousMonth.getMonth(),
            1
          );
          const lastDayOfPrevMonth = new Date(
            previousMonth.getFullYear(),
            previousMonth.getMonth() + 1,
            0,
            23,
            59,
            59
          );

          // Query transactions for previous month
          const transactionsSnapshot = await db
            .collection("transactions")
            .where("workerId", "==", userId)
            .where("paymentStatus", "==", "completed")
            .where("createdAt", ">=", firstDayOfPrevMonth.toISOString())
            .where("createdAt", "<=", lastDayOfPrevMonth.toISOString())
            .get();

          // Get all bookings for previous month to filter by category
          const bookingsSnapshot = await db
            .collection("bookings")
            .where("agent.uid", "==", userId)
            .where("bookingStatusCode", "==", "C")
            .where(
              "completedAt",
              ">=",
              admin.firestore.Timestamp.fromDate(firstDayOfPrevMonth)
            )
            .where(
              "completedAt",
              "<=",
              admin.firestore.Timestamp.fromDate(lastDayOfPrevMonth)
            )
            .get();

          // Create a map of bookingId -> categoryId
          const bookingCategoryMap = {};
          bookingsSnapshot.forEach((doc) => {
            const booking = doc.data();
            if (booking.service?.category === categoryId) {
              bookingCategoryMap[doc.id] = booking.service.category;
            }
          });

          // Calculate total earnings from transactions for this category
          let totalEarnings = 0;
          transactionsSnapshot.forEach((doc) => {
            const transaction = doc.data();
            const bookingId = transaction.bookingId;

            if (bookingCategoryMap[bookingId]) {
              const amount =
                typeof transaction.amount === "string"
                  ? parseFloat(transaction.amount)
                  : transaction.amount;
              totalEarnings += amount || 0;
            }
          });

          if (totalEarnings === 0) {
            logger.info(
              `No earnings for user ${userId}, category ${categoryId} in ${previousMonthStr}`
            );
            continue;
          }

          const bonusAmount = totalEarnings * bonusPercentage;

          // Update tier document with bonus info
          await tierDoc.ref.update({
            bonusAmount: bonusAmount,
            lastBonusDate: admin.firestore.FieldValue.serverTimestamp(),
            lastBonusMonth: currentMonthKey,
          });

          // Get current totalMonthlyBonus
          const currentTotalBonus = userData.totalMonthlyBonus;
          const currentTotalBonusNum =
            typeof currentTotalBonus === "string"
              ? parseFloat(currentTotalBonus) || 0
              : currentTotalBonus || 0;
          const newTotalBonus = currentTotalBonusNum + bonusAmount;

         

          // Update user's totalMonthlyBonus
          await db
            .collection("users")
            .doc(userId)
            .update({
              totalMonthlyBonus: newTotalBonus.toFixed(2),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

          // Send notification to worker
          const workerFcmToken = userData.fcmToken;
          const workerLanCode = userData.lanCode || "en";

          if (workerFcmToken && workerFcmToken.trim() !== "") {
            await sendAndStoreNotification({
              targetRole: "technician",
              targetId: userId,
              titleEn: "🎉 Monthly Bonus Received!",
              titleAr: "🎉 تم استلام المكافأة الشهرية!",
              bodyEn: `Congratulations! You achieved ${tier} tier in ${previousMonthStr} and earned a bonus of ₹${bonusAmount.toFixed(
                2
              )} (${bonusPercentage * 100}% of ₹${totalEarnings.toFixed(
                2
              )} earnings).`,
              bodyAr: `تهانينا! لقد حققت مستوى ${tier} في ${previousMonthStr} وحصلت على مكافأة قدرها ₹${bonusAmount.toFixed(
                2
              )} (${bonusPercentage * 100}٪ من ₹${totalEarnings.toFixed(
                2
              )} أرباح).`,
              data: {
                category: "bonus",
                tier: tier,
                amount: bonusAmount.toFixed(2),
                bonusPercentage: (bonusPercentage * 100).toString(),
                month: previousMonthStr,
              },
              fcmToken: workerFcmToken,
              lanCode: workerLanCode,
            });
          }

          totalBonusesApplied++;
          totalBonusAmount += bonusAmount;

          logger.info(
            `Applied ${tier} bonus of ₹${bonusAmount.toFixed(
              2
            )} to user ${userId} for ${previousMonthStr} (based on ₹${totalEarnings.toFixed(
              2
            )} earnings)`
          );
        }
      }

      logger.info(
        `Monthly bonus calculation completed for ${previousMonthStr}. Bonuses applied: ${totalBonusesApplied}, Total amount: ₹${totalBonusAmount.toFixed(
          2
        )}`
      );
      return null;
    } catch (error) {
      logger.error("Error calculating bonuses:", error);
      throw error;
    }
  }
);

// ============================================
// Function 3: Update Tier Stats on Job Completion
// Triggers when a booking status changes to completed
// ============================================
exports.updateTierStatsOnJobComplete = onDocumentUpdated(
  "bookings/{jobId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only proceed if status changed to completed
    if (before.bookingStatusCode === "C" || after.bookingStatusCode !== "C") {
      return null;
    }

    const workerId = after.agent?.uid;
    const categoryId = after.service?.category;
    const serviceName = after.service?.name;
    const rating = after.review?.rating || 0;

    if (!workerId || !categoryId) {
      logger.warn(
        `Booking ${event.params.jobId} missing workerId or categoryId`
      );
      return null;
    }

    try {
      const tierRef = db
        .collection("users")
        .doc(workerId)
        .collection("tiers")
        .doc(categoryId);

      const tierDoc = await tierRef.get();

      if (!tierDoc.exists) {
        // Initialize tier document
        await tierRef.set({
          tier: "Bronze",
          currentMonthJobs: 1,
          currentMonthRating: rating,
          lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
          bonusAmount: 0,
          previousMonthTier: "Bronze",
          previousMonthJobs: 0,
          previousMonthRating: 0.0,
        });

        logger.info(
          `✅ Initialized tier document for user ${workerId}, category ${categoryId} (${serviceName})`
        );
      } else {
        // Update existing tier document
        const currentData = tierDoc.data();
        const currentJobs = currentData.currentMonthJobs || 0;
        const currentRating = currentData.currentMonthRating || 0;
        const currentTier = currentData.tier || "Bronze";

        // Calculate new average rating
        const newJobCount = currentJobs + 1;
        const newAverageRating =
          (currentRating * currentJobs + rating) / newJobCount;

        // Calculate new tier based on updated stats
        let newTier = "Bronze";
        if (newAverageRating >= 4.8 && newJobCount >= 60) {
          newTier = "Platinum";
        } else if (newAverageRating >= 4.5 && newJobCount >= 40) {
          newTier = "Gold";
        } else if (newAverageRating >= 4.0 && newJobCount >= 20) {
          newTier = "Silver";
        }

        // Update tier document
        await tierRef.update({
          currentMonthJobs: admin.firestore.FieldValue.increment(1),
          currentMonthRating: newAverageRating,
          tier: newTier,
        });

        // Send notification if tier upgraded
        if (newTier !== currentTier) {
          const tierOrder = { Bronze: 0, Silver: 1, Gold: 2, Platinum: 3 };
          if (tierOrder[newTier] > tierOrder[currentTier]) {
            const workerDoc = await db.collection("users").doc(workerId).get();
            if (workerDoc.exists) {
              const workerData = workerDoc.data();
              const fcmToken = workerData.fcmToken;
              const lanCode = workerData.lanCode || "en";

              if (fcmToken && fcmToken.trim() !== "") {
                const bonusPercentages = {
                  Silver: "5%",
                  Gold: "10%",
                  Platinum: "15%",
                };

                await sendAndStoreNotification({
                  targetRole: "technician",
                  targetId: workerId,
                  titleEn: `🎊 Tier Upgraded to ${newTier}!`,
                  titleAr: `🎊 تمت ترقية المستوى إلى ${newTier}!`,
                  bodyEn: `Congratulations! You've been upgraded to ${newTier} tier! You now earn ${
                    bonusPercentages[newTier] || "0%"
                  } bonus on your monthly earnings. Keep up the great work!`,
                  bodyAr: `تهانينا! تمت ترقيتك إلى مستوى ${newTier}! أنت الآن تكسب ${
                    bonusPercentages[newTier] || "0%"
                  } مكافأة على أرباحك الشهرية. استمر في العمل الرائع!`,
                  data: {
                    category: "tier_upgrade",
                    oldTier: currentTier,
                    newTier: newTier,
                    jobs: newJobCount.toString(),
                    rating: newAverageRating.toFixed(2),
                  },
                  fcmToken: fcmToken,
                  lanCode: lanCode,
                });

                logger.info(
                  `🎊 Tier upgraded for user ${workerId}: ${currentTier} → ${newTier}`
                );
              }
            }
          }
        }

        logger.info(
          `✅ Updated tier stats for user ${workerId}, category ${categoryId} (${serviceName}): ${newJobCount} jobs, ${newAverageRating.toFixed(
            2
          )} rating, tier: ${newTier}`
        );
      }

      return null;
    } catch (error) {
      logger.error("Error updating tier stats:", error);
      throw error;
    }
  }
);
