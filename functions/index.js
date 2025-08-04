const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    const statusChangedToAssigned =
      beforeData?.bookingStatusCode !== "A" &&
      afterData.bookingStatusCode === "A";

    if (!statusChangedToAssigned) {
      console.log("Booking was not newly assigned, skipping...");
      return;
    }

    const agent = afterData.agent;
    if (!agent) {
      console.log("No agent assigned.");
      return;
    }

    const agentId = agent.uid;
    if (!agentId) {
      console.log("No agent UID found.");
      return;
    }
    let agentLanCode = "en";
    let agentFcmToken;
    try {
      const agentDoc = await admin
        .firestore()
        .collection("users")
        .doc(agentId)
        .get();
      if (agentDoc.exists) {
        const agentData = agentDoc.data();
        agentLanCode = agentData.lanCode;
        agentFcmToken = agentData.fcmToken;
      }
    } catch (error) {
      console.error("Error fetching agent lanCode:", error.message);
    }

    if (!agentFcmToken || agentFcmToken.trim() === "") {
      console.log("Agent has no valid FCM token.");
      return;
    }

    const service = afterData.service;
    const serviceName = service?.name;

    const title =
      agentLanCode === "ar" ? "تم تعيين حجز جديد لك" : "New Booking Assigned";
    const body =
      agentLanCode === "ar"
        ? `تم تعيين حجز جديد لخدمة "${serviceName}"`
        : `You have been assigned a new booking for "${serviceName}"`;

    const message = {
      notification: {
        title,
        body,
      },
      token: agentFcmToken,
    };

    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending notification to agent:", error.message);
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
            lanCode: user.lanCode || "en",
          });
        }
      });

      const adminMessages = tokensWithLanguage.map((admin) => {
        const title =
          admin.lanCode === "ar"
            ? "تم تعيين عامل جديد لحجز"
            : "New Agent Assigned";

        const body =
          admin.lanCode === "ar"
            ? `تم تعيين العامل لحجز جديد لخدمة "${serviceName}".`
            : `An agent has been assigned to a new booking for "${serviceName}".`;

        return {
          notification: { title, body },
          token: admin.token,
          data: {
            bookingId: bookingId,
            serviceName: serviceName,
            lanCode: admin.lanCode,
          },
        };
      });

      for (const message of adminMessages) {
        await admin.messaging().send(message);
      }

      console.log("Admins notified of new agent assignment.");
    } catch (error) {
      console.error("Error notifying admins:", error);
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
        en: "Your service is complete!\nWe hope you had a great experience.\nPlease take a moment to rate your service provider.\nIf you'd like, you can also leave a tip to show your appreciation.",
        ar: "تم الانتهاء من خدمتك!\nنأمل أن تكون قد قضيت وقتًا رائعًا.\nيرجى تقييم مقدم الخدمة الخاص بك.\nوإذا رغبت، يمكنك ترك إكرامية.",
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
        const existingTip = tippingDoc.exists
          ? tippingDoc.data().totalTip || 0
          : 0;

        const updateData = {
          walletId: tippingWalletId,
          agentId: agent.uid,
          agentName: agent.name || "",
          agentPhone: agent.phone || "",
          lastTipAmount: tipAmount,
          lastUpdated: FieldValue.serverTimestamp(),
          totalTip: existingTip + tipAmount,
        };

        if (!tippingDoc.exists) {
          console.log("Creating new tipping document.");
          tx.set(tippingRef, updateData);
        } else {
          console.log(
            `Updating tipping document. Current total: ${existingTip}`
          );
          tx.update(tippingRef, updateData);
        }

        const agentFcmToken = agent.fcmToken;

        const message = {
          notification: {
            title: "New Tip Received",
            body: `You have received a new tip of ${tipAmount}.`,
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
        `Successfully updated tip +${tipAmount} for agent ${agent.name} (${agent.uid})`
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
