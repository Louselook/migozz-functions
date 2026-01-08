import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, type DocumentData} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {getMessaging} from "firebase-admin/messaging";
import QRCode from "qrcode";
import { logger } from "firebase-functions";
import nodemailer, { SendMailOptions } from "nodemailer";

initializeApp();
const db = getFirestore();
const storage = getStorage();
const messaging = getMessaging();

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function computeTotalFollowersFromSocialEcosystem(ecosystem: unknown): number {
  if (!Array.isArray(ecosystem)) return 0;
  let total = 0;
  for (const social of ecosystem) {
    if (!isRecord(social)) continue;
    for (const value of Object.values(social)) {
      if (!isRecord(value)) continue;
      const followers = value.followers;
      if (typeof followers === "number") total += followers;
      else if (typeof followers === "string") total += Number.parseInt(followers, 10) || 0;
    }
  }
  return total;
}


// 1. onUserCreate → sincroniza con profiles_public
export const onUserCreate = onDocumentCreated("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const snap = event.data;
  if (!snap) return;

  const userData = snap.data();

  await db.collection("profiles_public").doc(uid).set({
    username: userData.username || "",
    displayName: userData.displayName || "",
    avatarUrl: userData.avatarUrl || "",
    category: userData.category || "",
    city: userData.location?.city || "",
    country: userData.location?.country || "",
    totalFollowers: userData.totalFollowers || 0,
    linksCount: userData.linksCount || 0,
    t: FieldValue.serverTimestamp(),
  });
});


// 2. verifyHandle → reserva usernames
export const verifyHandle = onCall(async (request) => {
  const {handle, uid} = request.data;

  const ref = db.collection("shareHandles").doc(handle);
  const snap = await ref.get();

  if (snap.exists) {
    throw new Error("Handle already taken");
  }

  await ref.set({
    uid,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {success: true};
});


// 3. profilesPublicSync → actualiza perfiles públicos
export const profilesPublicSync = onDocumentUpdated("users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;
    if (!after) return;

    const data = after.data() as DocumentData;

    const location = isRecord(data.location) ? data.location : undefined;

    const totalFollowers =
      typeof data.totalFollowers === "number"
        ? data.totalFollowers
        : computeTotalFollowersFromSocialEcosystem(data.socialEcosystem);

    const username = typeof data.username === "string" ? data.username : "";
    const displayName = typeof data.displayName === "string" ? data.displayName : "";
    const avatarUrl = typeof data.avatarUrl === "string" ? data.avatarUrl : "";
    const category = typeof data.category === "string" ? data.category : "";
    const city = typeof location?.city === "string" ? location.city : "";
    const country = typeof location?.country === "string" ? location.country : "";
    const linksCount = typeof data.linksCount === "number" ? data.linksCount : 0;

    await db.collection("profiles_public").doc(uid).set({
      username,
      displayName,
      avatarUrl,
      category,
      city,
      country,
      totalFollowers,
      linksCount,
      t: FieldValue.serverTimestamp(),
    }, {merge: true});
  });


// 4. fetchSocialMetrics (ejemplo básico, sin APIs reales)
export const fetchSocialMetrics = onCall(async (request) => {
  const {uid, linkId} = request.data;

  const followers = Math.floor(Math.random() * 10000);
  const postsCount = Math.floor(Math.random() * 500);

  await db.collection("userSocials")
    .doc(uid)
    .collection("links")
    .doc(linkId).update({
      followers,
      postsCount,
      lastFetchedAt: FieldValue.serverTimestamp(),
    });

  // recalcular totalFollowers
  const linksSnap = await db
    .collection("userSocials")
    .doc(uid)
    .collection("links")
    .get();
  const totalFollowers = linksSnap
    .docs.reduce((sum, doc) => sum + (doc.data().followers || 0), 0);

  await db.collection("users").doc(uid).update({totalFollowers});

  return {success: true, followers, postsCount};
});


// 5. generateProfileQR → genera QR y lo guarda en Storage
export const generateProfileQR = onCall(async (request) => {
  const {uid, publicUrl} = request.data;

  const qrDataUrl = await QRCode.toDataURL(publicUrl);
  const buffer = Buffer.from(qrDataUrl.split(",")[1], "base64");

  const file = storage.bucket().file(`qr/${uid}/profile.png`);
  await file.save(buffer, {contentType: "image/png"});

  const qrUrl = `https://storage.googleapis.com/${file.bucket.name}/${file.name}`;

  await db.collection("users").doc(uid).update({
    "share.qrUrl": qrUrl,
  });

  return {success: true, qrUrl};
});

// 6. sendSupportEmail → envía correo al crear ticket de soporte
export const sendSupportEmail = onDocumentCreated(
  "supportTickets/{ticketId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    logger.info("📨 Nuevo ticket de soporte recibido:", data);

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "issamu382@gmail.com",
        pass: "nfnsyuwdkymgbwbs",
      },
    });

    const mailOptions: SendMailOptions = {
      from: "Migozz Support <MigozzSupport@migozz.com>",
      to: "issamu382@gmail.com",
      subject: `Nuevo Ticket de Soporte — ${data.email}`,
      html: `
        <h2>Nuevo Ticket de Soporte</h2>

        <p><strong>Nombre:</strong> ${data.name}</p>
        <p><strong>Email:</strong> ${data.email}</p>

        <p><strong>Mensaje:</strong></p>
        <p>${data.message}</p>

        ${data.fileName ? `<p><strong>Adjunto:</strong> ${data.fileName}</p>` : ""}

        <br><hr>
        <p>Ticket generado automáticamente desde Migozz.</p>
      `,
      attachments: data.fileBase64
        ? [
            {
              filename: data.fileName,
              content: Buffer.from(data.fileBase64, "base64"),
            },
          ]
        : [],
    };

    await transporter.sendMail(mailOptions);

    logger.info("📧 Correo de soporte enviado correctamente.");
  }
);

// 7. sendChatNotification → sends push notification when a new chat message is created
export const sendChatNotification = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}",
  async (event) => {
    logger.info("🚀 sendChatNotification function triggered!");
    logger.info(`Event params: chatRoomId=${event.params.chatRoomId}, messageId=${event.params.messageId}`);

    const messageData = event.data?.data();
    if (!messageData) {
      logger.warn("No message data found");
      return;
    }

    logger.info(`Message data: ${JSON.stringify(messageData)}`);

    const chatRoomId = event.params.chatRoomId;
    const senderId = messageData.senderId as string; // This is an email
    const receiverId = messageData.receiverId as string; // This is an email
    const messageType = messageData.type as string || "text";
    // Message content is stored in textContent field, not content
    const messageContent = messageData.textContent as string || messageData.content as string || "";

    logger.info(`📨 New chat message from ${senderId} to ${receiverId} in room ${chatRoomId}`);

    // Don't send notification to the sender
    if (!receiverId || receiverId === senderId) {
      logger.info("Skipping notification - no receiver or sender is receiver");
      return;
    }

    try {
      // Get sender's user data by email (senderId is an email, not a UID)
      const senderQuery = await db.collection("users")
        .where("email", "==", senderId)
        .limit(1)
        .get();

      let senderName = "Someone";
      let senderAvatar = "";

      if (!senderQuery.empty) {
        const senderData = senderQuery.docs[0].data();
        senderName = senderData?.displayName || senderData?.username || "Someone";
        senderAvatar = senderData?.avatarUrl || "";
      } else {
        logger.warn(`Sender ${senderId} not found in users collection`);
      }

      // Get receiver's FCM tokens by email (receiverId is an email, not a UID)
      const receiverQuery = await db.collection("users")
        .where("email", "==", receiverId)
        .limit(1)
        .get();

      if (receiverQuery.empty) {
        logger.warn(`Receiver ${receiverId} not found in users collection`);
        return;
      }

      const receiverDoc = receiverQuery.docs[0];
      const receiverData = receiverDoc.data();

      if (!receiverData) {
        logger.warn(`Receiver ${receiverId} not found`);
        return;
      }

      const fcmTokens: string[] = receiverData.fcmTokens || [];
      const lastFcmToken = receiverData.lastFcmToken;

      // Collect all valid tokens
      const tokens: string[] = [];
      if (lastFcmToken) tokens.push(lastFcmToken);
      fcmTokens.forEach((token: string) => {
        if (token && !tokens.includes(token)) {
          tokens.push(token);
        }
      });

      if (tokens.length === 0) {
        logger.info(`No FCM tokens found for receiver ${receiverId}`);
        return;
      }

      // Prepare notification content based on message type
      let notificationBody = "";
      switch (messageType) {
        case "audio":
          notificationBody = "🎤 Sent a voice message";
          break;
        case "image":
          notificationBody = "📷 Sent an image";
          break;
        case "text":
        default:
          // Truncate message if too long
          notificationBody = messageContent.length > 100
            ? messageContent.substring(0, 100) + "..."
            : messageContent;
          break;
      }

      // Prepare the FCM message
      const fcmMessage = {
        notification: {
          title: senderName,
          body: notificationBody,
        },
        data: {
          type: "chat_message",
          senderId: senderId,
          receiverId: receiverId,
          chatRoomId: chatRoomId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          messageType: messageType,
          title: senderName,
          body: notificationBody,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "chat_notifications",
            priority: "high" as const,
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: senderName,
                body: notificationBody,
              },
              badge: 1,
              sound: "default",
              contentAvailable: true,
            },
          },
        },
      };

      // Send to all tokens
      const invalidTokens: string[] = [];

      for (const token of tokens) {
        try {
          await messaging.send({
            ...fcmMessage,
            token: token,
          });
          logger.info(`✅ Notification sent successfully to token: ${token.substring(0, 20)}...`);
        } catch (error: unknown) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          logger.error(`❌ Failed to send to token ${token.substring(0, 20)}...: ${errorMessage}`);

          // Check if token is invalid and should be removed
          if (errorMessage.includes("not-registered") ||
              errorMessage.includes("invalid-registration-token") ||
              errorMessage.includes("registration-token-not-registered")) {
            invalidTokens.push(token);
          }
        }
      }

      // Remove invalid tokens from user's document
      if (invalidTokens.length > 0) {
        logger.info(`Removing ${invalidTokens.length} invalid tokens for user ${receiverId}`);
        // Use the receiver document reference we already have
        await receiverDoc.ref.update({
          fcmTokens: FieldValue.arrayRemove(...invalidTokens),
        });
      }

      logger.info(`📬 Chat notification process completed for message in room ${chatRoomId}`);
    } catch (error) {
      logger.error("Error sending chat notification:", error);
    }
  }
);