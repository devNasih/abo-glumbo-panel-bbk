const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

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

      for (const { token, lanCode } of tokensWithLanguage) {
        try {
          const message = {
            notification: {
              title: lanCode === "ar" ? "طلب حجز جديد" : "New Booking Request",
              body:
                lanCode === "ar"
                  ? "مرحبًا Admin، لقد تم تقديم طلب حجز جديد!"
                  : "Hey Admin, a new booking request just came in!",
            },
            data: {
              targetRole: "admin",
              category: "booking",
              bookingId: event.params.bookingId,
            },
            token: token,
          };

          const response = await admin.messaging().send(message);
          results.push({ token, success: true, messageId: response });
        } catch (error) {
          results.push({ token, success: false, error: error.message });
        }
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

            if (agentFcmToken && agentFcmToken.trim() !== "") {
              const title =
                agentLanCode === "ar"
                  ? "تم تعيين حجز جديد لك"
                  : "New Booking Assigned";
              const body =
                agentLanCode === "ar"
                  ? `لقد قبلت حجزاً جديداً لخدمة "${serviceName}"`
                  : `You have accepted a new booking for "${serviceName}"`;

              await admin.messaging().send({
                notification: { title, body },
                data: {
                  targetRole: "worker",
                  category: "booking",
                  bookingId,
                  serviceName,
                },
                token: agentFcmToken,
              });

              console.log(
                `[${bookingId}] Notification sent to assigned worker`
              );
            }
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
        const adminMessages = adminTokens.map(({ token, lanCode }) => ({
          notification: {
            title:
              lanCode === "ar"
                ? "تم تعيين عامل جديد لحجز"
                : "New Agent Assigned",
            body:
              lanCode === "ar"
                ? `تم تعيين العامل لحجز جديد لخدمة "${serviceName}".`
                : `An agent has been assigned to a new booking for "${serviceName}".`,
          },
          token,
          data: {
            targetRole: "admin",
            category: "booking",
            bookingId,
            serviceName,
            lanCode,
          },
        }));

        try {
          await Promise.all(
            adminMessages.map((msg) => admin.messaging().send(msg))
          );
          console.log(`[${bookingId}] Admins notified of assignment`);
        } catch (error) {
          console.error(
            `[${bookingId}] Error notifying admins of assignment:`,
            error
          );
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
          const cancelMessages = adminTokens.map(({ token, lanCode }) => ({
            notification: {
              title:
                lanCode === "ar"
                  ? "إلغاء حجز من قبل عامل"
                  : "Booking Cancelled by Worker",
              body:
                lanCode === "ar"
                  ? `تم إلغاء الحجز من قبل العامل ${workerName}.`
                  : `The booking has been cancelled by worker ${workerName}.`,
            },
            token,
            data: {
              targetRole: "admin",
              category: "booking",
              bookingId,
              workerId,
              workerName,
            },
          }));

          await Promise.all(
            cancelMessages.map((msg) => admin.messaging().send(msg))
          );
          console.log(`[${bookingId}] Admins notified of worker cancellation`);
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

    const statusChanged =
      beforeData?.bookingStatusCode !== afterData.bookingStatusCode;
    if (!statusChanged) {
      console.log("Booking status did not change, skipping...");
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
        en: "Your service is complete!\nComplete your payment now.\nWe hope you had a great experience.\nPlease take a moment to rate your service provider.\nIf you'd like, you can also leave a tip to show your appreciation.",
        ar: "تم الانتهاء من خدمتك!\nأكمل دفعتك الآن.\nنأمل أن تكون قد قضيت وقتًا رائعًا.\nيرجى تقييم مقدم الخدمة الخاص بك.\nوإذا رغبت، يمكنك ترك إكرامية.",
      },
      X: {
        en: "Your booking has been canceled.",
        ar: "تم إلغاء حجزك.",
      },
    };

    const notificationBody =
      statusMessages[bookingStatus]?.[lanCode] ||
      statusMessages[bookingStatus]?.["en"] ||
      `Your booking status changed to ${bookingStatus}`;

    const message = {
      notification: {
        title: lanCode === "ar" ? "تحديث حالة الحجز" : "Booking Status Update",
        body: `${notificationBody} (${serviceName})`,
      },
      token: fcmToken,
      data: {
        bookingId: event.params.bookingId,
        status: bookingStatus,
        serviceName: serviceName || "Service",
        lanCode: lanCode,
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending FCM notification:", error);
    }
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

    let trackingMessageTitle = "";
    let trackingMessageBody = "";

    // Debug: Ensure lanCode is valid
    const language =
      typeof lanCode === "string" && lanCode.trim().toLowerCase() === "ar"
        ? "ar"
        : "en";

    if (!wasStarted && isStartedNow) {
      trackingMessageTitle =
        language === "ar" ? "بدء تتبع الحجز" : "Tracking Started";
      trackingMessageBody =
        language === "ar"
          ? "يمكنك الآن تتبع حالة حجزك."
          : "The service provider has started tracking your location for the booking.";
    } else if (wasStarted && !isStartedNow) {
      trackingMessageTitle =
        language === "ar" ? "إيقاف تتبع الحجز" : "Tracking Stopped";
      trackingMessageBody =
        language === "ar"
          ? "تم إيقاف تتبع موقعك بواسطة مقدم الخدمة."
          : "Tracking has been stopped by the service provider.";
    } else {
      console.log("Tracking status unchanged, skipping...");
      return;
    }

    const message = {
      notification: {
        title: trackingMessageTitle,
        body: trackingMessageBody,
      },
      token: fcmToken,
    };
    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending tracking notification:", error);
    }
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
        const isCardPayment = paymentType.toLowerCase() === "cards" || 
                              paymentType.toLowerCase() === "card";
        
        const updateData = {
          walletId: tippingWalletId,
          agentId: agent.uid,
          agentName: agent.name || "",
          agentPhone: agent.phone || "",
          lastUpdated: FieldValue.serverTimestamp(),
          cashtip: isCardPayment ? existingCashTip : existingCashTip + tipAmount,
          cardtip: isCardPayment ? existingCardTip + tipAmount : existingCardTip,
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

        const message = {
          notification: {
            title: "New Tip Received",
            body: `You have received a new ${isCardPayment ? 'card' : 'cash'} tip of ${tipAmount}.`,
          },
          token: agentFcmToken,
        };
        
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
        `Successfully updated ${isCardPayment ? 'card' : 'cash'} tip +${tipAmount} for agent ${agent.name} (${agent.uid})`
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

      for (const { token, lanCode } of tokensWithLanguage) {
        try {
          const message = {
            notification: {
              title: lanCode === "ar" ? "طلب دفع جديد" : "New Payout Request",
              body:
                lanCode === "ar"
                  ? `${workerName} طلب دفع بقيمة ₹${amount}`
                  : `${workerName} requested a payout of ₹${amount}`,
            },
            data: {
              targetRole: "admin",
              category: "payout",
              requestId: requestId,
              workerId: userId,
              workerName: workerName,
              amount: amount,
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

    const message = {
      notification: {
        title: title,
        body: notificationBody,
      },
      token: fcmToken,
      data: {
        targetRole: "worker",
        category: "payout",
        requestId: requestId,
        status: status,
        amount: amount,
        lanCode: lanCode,
      },
    };

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

// ============================================
// Function 1: Reset Tiers Monthly (1st at 00:00 IST)
// ============================================
exports.resetMonthlyTiers = onSchedule(
  {
    schedule: "0 0 1 * *",
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

          batch.update(tierRef, {
            tier: "Bronze",
            currentMonthJobs: 0,
            currentMonthRating: 0.0,
            lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
            previousMonthTier: tierDoc.data().tier || "Bronze",
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
// ============================================
// ============================================
// Function 2: Calculate and Apply Monthly Bonuses (Last day at 23:00 Saudi Arabia Time)
// ============================================
exports.applyMonthlyBonus = onSchedule(
  {
    schedule: "0 23 * * *",
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (tomorrow.getDate() !== 1) {
      logger.info(
        `Not last day of month (${today.getDate()}). Skipping bonus calculation.`
      );
      return null;
    }

    logger.info(
      `Last day of month detected (${today.getDate()}). Calculating bonuses...`
    );

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

          // Check if bonus already applied this month
          const lastBonusDate = tierData.lastBonusDate?.toDate();
          if (
            lastBonusDate &&
            lastBonusDate.getMonth() === today.getMonth() &&
            lastBonusDate.getFullYear() === today.getFullYear()
          ) {
            logger.info(
              `Bonus already applied for user ${userId}, category ${categoryId}`
            );
            continue;
          }

          // Get stats for this category
          const statsDoc = await db
            .collection("users")
            .doc(userId)
            .collection("stats")
            .doc(categoryId)
            .get();

          if (!statsDoc.exists) {
            logger.info(
              `No stats found for user ${userId}, category ${categoryId}`
            );
            continue;
          }

          const stats = statsDoc.data();
          const jobs = stats.jobs || 0;
          const rating = stats.rating || 0.0;

          // Calculate tier and bonus percentage
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

          // Calculate monthly earnings from transactions
          const firstDayOfMonth = new Date(
            today.getFullYear(),
            today.getMonth(),
            1
          );
          const lastDayOfMonth = new Date(
            today.getFullYear(),
            today.getMonth() + 1,
            0,
            23,
            59,
            59
          );

          // Query transactions for this worker in this month
          const transactionsSnapshot = await db
            .collection("transactions")
            .where("workerId", "==", userId)
            .where("paymentStatus", "==", "completed") // Only count completed payments
            .where("createdAt", ">=", firstDayOfMonth.toISOString())
            .where("createdAt", "<=", lastDayOfMonth.toISOString())
            .get();

          // Get all bookings for this month to filter by category
          const bookingsSnapshot = await db
            .collection("bookings")
            .where("agent.uid", "==", userId)
            .where("bookingStatusCode", "==", "C")
            .where(
              "completedAt",
              ">=",
              admin.firestore.Timestamp.fromDate(firstDayOfMonth)
            )
            .where(
              "completedAt",
              "<=",
              admin.firestore.Timestamp.fromDate(lastDayOfMonth)
            )
            .get();

          // Create a map of bookingId -> categoryId for filtering
          const bookingCategoryMap = {};
          bookingsSnapshot.forEach((doc) => {
            const booking = doc.data();
            // FIXED: Use service.category instead of service.categoryId
            if (booking.service?.category === categoryId) {
              bookingCategoryMap[doc.id] = booking.service.category;
            }
          });

          // Calculate total earnings from transactions for this category
          let totalEarnings = 0;
          transactionsSnapshot.forEach((doc) => {
            const transaction = doc.data();
            const bookingId = transaction.bookingId;

            // Only count transactions for bookings in this category
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
              `No earnings for user ${userId}, category ${categoryId}`
            );
            continue;
          }

          const bonusAmount = totalEarnings * bonusPercentage;

          // Update tier document with bonus info
          await tierDoc.ref.update({
            tier: tier,
            bonusAmount: bonusAmount,
            lastBonusDate: admin.firestore.FieldValue.serverTimestamp(),
            lastBonusMonth: `${today.getFullYear()}-${today.getMonth() + 1}`,
          });

          // Get current available balance and update
          const currentBalance = userData.availableBalance;
          const currentBalanceNum =
            typeof currentBalance === "string"
              ? parseFloat(currentBalance) || 0
              : currentBalance || 0;
          const newBalance = currentBalanceNum + bonusAmount;

          // Update user's availableBalance
          await db
            .collection("users")
            .doc(userId)
            .update({
              availableBalance: newBalance.toFixed(2),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

          // Create bonus transaction record in transactions collection
          await db.collection("transactions").add({
            amount: parseFloat(bonusAmount.toFixed(2)),
            customerId: "", // No customer for bonus transactions
            workerId: userId,
            paymentStatus: "completed",
            paymentMethod: "bonus", // Special payment method for bonuses
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            bookingId: "", // No specific booking for bonus
            orderId: `BONUS-${today.getFullYear()}${(today.getMonth() + 1)
              .toString()
              .padStart(2, "0")}-${userId}-${categoryId}`,
            // Additional bonus metadata
            transactionType: "bonus",
            tier: tier,
            categoryId: categoryId,
            bonusPercentage: bonusPercentage * 100,
            totalEarnings: parseFloat(totalEarnings.toFixed(2)),
            jobs: jobs,
            rating: rating,
            month: `${today.getFullYear()}-${today.getMonth() + 1}`,
          });

          totalBonusesApplied++;
          totalBonusAmount += bonusAmount;

          logger.info(
            `Applied ${tier} bonus of ₹${bonusAmount.toFixed(
              2
            )} to user ${userId} (based on ₹${totalEarnings.toFixed(
              2
            )} earnings)`
          );
        }
      }

      logger.info(
        `Monthly bonus calculation completed. Bonuses applied: ${totalBonusesApplied}, Total amount: ₹${totalBonusAmount.toFixed(
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
// Function 3: Update Tier Stats on Job Completion (WITH DEBUG LOGGING)
// ============================================
// ============================================
// Function 3: Update Tier Stats on Job Completion (FIXED)
// ============================================
exports.updateTierStatsOnJobComplete = onDocumentUpdated(
  "bookings/{jobId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only proceed if status changed to completed (bookingStatusCode changed to 'C')
    if (before.bookingStatusCode === "C" || after.bookingStatusCode !== "C") {
      return null;
    }

    // Get worker ID from nested agent object
    const workerId = after.agent?.uid;

    // FIXED: Get category ID from service.category (not service.categoryId)
    const categoryId = after.service?.category;
    const serviceName = after.service?.name;

    // Get rating from nested review object
    const rating = after.review?.rating || 0;

    if (!workerId || !categoryId) {
      logger.warn(
        `Booking ${event.params.jobId} missing workerId or categoryId`
      );
      logger.warn(`workerId: ${workerId}, categoryId: ${categoryId}`);
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
        });

        logger.info(
          `✅ Initialized tier document for user ${workerId}, category ${categoryId} (${serviceName})`
        );
      } else {
        // Update existing tier document
        const currentData = tierDoc.data();
        const currentJobs = currentData.currentMonthJobs || 0;
        const currentRating = currentData.currentMonthRating || 0;

        // Calculate new average rating
        const newJobCount = currentJobs + 1;
        const newAverageRating =
          (currentRating * currentJobs + rating) / newJobCount;

        await tierRef.update({
          currentMonthJobs: admin.firestore.FieldValue.increment(1),
          currentMonthRating: newAverageRating,
        });

        logger.info(
          `✅ Updated tier stats for user ${workerId}, category ${categoryId} (${serviceName}): ${newJobCount} jobs, ${newAverageRating.toFixed(
            2
          )} rating`
        );
      }

      return null;
    } catch (error) {
      logger.error("Error updating tier stats:", error);
      throw error;
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

    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
      data: {
        targetRole: "worker",
        category: "booking",
        bookingId: bookingId,
        serviceName: serviceName,
        customerName: customerName,
        lanCode: lanCode,
      },
    };

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
      for (const { token, lanCode } of tokensWithLanguage) {
        try {
          const message = {
            notification: {
              title:
                lanCode === "ar" ? "طلب سحب إكرامية" : "Tip Payout Request",
              body:
                lanCode === "ar"
                  ? `${agentName} طلب سحب إكرامية بمبلغ ${totalTip}. يرجى المراجعة والموافقة.`
                  : `${agentName} requested a tip payout of ₹${totalTip}. Please review and approve.`,
            },
            data: {
              targetRole: "admin",
              category: "tip_payout",
              walletId: walletId,
              agentId: agentId,
              agentName: agentName,
              amount: totalTip.toString(),
            },
            token: token,
          };

          const response = await admin.messaging().send(message);
          results.push({ token, success: true, messageId: response });
          console.log(
            `Notification sent to admin with token ${token.substring(0, 20)}...`
          );
        } catch (error) {
          results.push({ token, success: false, error: error.message });
          console.error(`Failed to send to token: ${error.message}`);
        }
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

    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
      data: {
        targetRole: "worker",
        category: "tip_payout",
        walletId: walletId,
        amount: totalTip.toString(),
        lanCode: lanCode,
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`Tip payout notification sent to worker ${agentId}`);
    } catch (error) {
      console.error("Error sending FCM notification to worker:", error);
    }
  }
);
