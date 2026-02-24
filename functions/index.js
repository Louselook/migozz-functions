/**
 * Firebase Cloud Functions for Migozz App
 * 
 * This file contains Cloud Functions that handle push notifications
 * for various events like follows, messages, etc.
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { transactionsController } = require("./src/transactions");
const { asociateWalletToNewUser } = require("./src/wallet");
const { createStripePayment, stripeWebhook } = require("./src/payments/stripe");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();
/*STRIPE secret key, this line just saves it as a enviroment variable in the firebase server*/

/**
 * Send push notification when a new follow notification is created
 *
 * Triggers when a document is created in:
 * users/{userId}/notifications/{notificationId}
 *
 * The notification document should have:
 * - type: 'follow'
 * - fromUserId: the ID of the user who followed
 * - timestamp: server timestamp
 * - isRead: false
 */
exports.onFollowNotificationCreated = onDocumentCreated(
  {
    document: "users/{userId}/notifications/{notificationId}",
    region: "us-central1", // Change this to match your Firestore region if different
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return null;
    }

    const notificationData = snapshot.data();
    const targetUserId = event.params.userId;
    const notificationId = event.params.notificationId;

    console.log(`📬 New notification created for user ${targetUserId}:`, notificationData);

    // Only process follow notifications
    if (notificationData.type !== "follow") {
      console.log("Not a follow notification, skipping");
      return null;
    }

    const fromUserId = notificationData.fromUserId;
    if (!fromUserId) {
      console.log("No fromUserId in notification, skipping");
      return null;
    }

    try {
      // Get the follower's info
      const followerDoc = await db.collection("users").doc(fromUserId).get();
      if (!followerDoc.exists) {
        console.log(`Follower user ${fromUserId} not found`);
        return null;
      }

      const followerData = followerDoc.data();
      const followerName = followerData.displayName || followerData.username || "Someone";
      const followerAvatar = followerData.avatarUrl || null;

      // Get the target user's FCM token
      const targetUserDoc = await db.collection("users").doc(targetUserId).get();
      if (!targetUserDoc.exists) {
        console.log(`Target user ${targetUserId} not found`);
        return null;
      }

      const targetUserData = targetUserDoc.data();
      const fcmToken = targetUserData.lastFcmToken;

      if (!fcmToken) {
        console.log(`Target user ${targetUserId} has no FCM token`);
        return null;
      }

      // Build the notification message
      // ⚠️ IMPORTANT: For follow notifications, we send ONLY data payload (no notification payload)
      // This prevents duplicate notifications because the Firestore listener in the app
      // will handle displaying the notification. If we include the notification payload,
      // the system will auto-display it AND the app will also display it = duplicates!
      // ⚠️ IMPORTANT: For follow notifications, we send ONLY data payload (no notification payload)
      // This prevents duplicate notifications because the Firestore listener in the app
      // will handle displaying the notification. If we include the notification payload,
      // the system will auto-display it AND the app will also display it = duplicates!
      const message = {
        token: fcmToken,
        // ❌ NO notification payload - prevents system from auto-displaying
        // ❌ NO notification payload - prevents system from auto-displaying
        data: {
          type: "follow",
          followerId: fromUserId,
          followerName: followerName,
          followerAvatar: followerAvatar || "",
          notificationId: notificationId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        // Set high priority to ensure delivery even when app is in background
        // Set high priority to ensure delivery even when app is in background
        android: {
          priority: "high",
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              "content-available": 1, // Silent notification for iOS
              "content-available": 1, // Silent notification for iOS
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      console.log(`📤 Sending data-only push notification to ${targetUserId}`);
      console.log(`📤 Sending data-only push notification to ${targetUserId}`);
      const response = await messaging.send(message);
      console.log(`✅ Successfully sent notification: ${response}`);

      return response;
    } catch (error) {
      console.error("❌ Error sending notification:", error);

      // If the token is invalid, remove it from the user's document
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        console.log(`Removing invalid FCM token for user ${targetUserId}`);
        await db.collection("users").doc(targetUserId).update({
          lastFcmToken: null,
        });
      }

      return null;
    }
  }
);

/**
 * Send push notification when a new chat message is created
 * 
 * Triggers when a document is created in:
 * chat_rooms/{chatRoomId}/messages/{messageId}
 */
exports.onChatMessageCreated = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return null;
    }

    const messageData = snapshot.data();
    const chatRoomId = event.params.chatRoomId;
    const messageId = event.params.messageId;

    console.log(`💬 New message in chat ${chatRoomId}:`, messageData);

    const senderId = messageData.senderId; // This is the sender's email
    const receiverId = messageData.receiverId; // This is the receiver's email

    if (!senderId || !receiverId) {
      console.log("Missing senderId or receiverId, skipping");
      return null;
    }

    try {
      // Get sender info by email
      const senderQuery = await db
        .collection("users")
        .where("email", "==", senderId)
        .limit(1)
        .get();

      if (senderQuery.empty) {
        console.log(`Sender ${senderId} not found`);
        return null;
      }

      const senderDoc = senderQuery.docs[0];
      const senderData = senderDoc.data();
      const senderName = senderData.displayName || senderData.username || "Someone";
      const senderAvatar = senderData.avatarUrl || null;

      // Get receiver info by email
      const receiverQuery = await db
        .collection("users")
        .where("email", "==", receiverId)
        .limit(1)
        .get();

      if (receiverQuery.empty) {
        console.log(`Receiver ${receiverId} not found`);
        return null;
      }

      const receiverDoc = receiverQuery.docs[0];
      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.lastFcmToken;

      if (!fcmToken) {
        console.log(`Receiver ${receiverId} has no FCM token`);
        return null;
      }

      // Determine message body based on type
      let messageBody = "Sent you a message";
      if (messageData.type === "text" && messageData.textContent) {
        // Truncate long messages
        const text = messageData.textContent;
        messageBody = text.length > 100 ? text.substring(0, 100) + "..." : text;
      } else if (messageData.type === "audio") {
        messageBody = "🎤 Sent a voice message";
      } else if (messageData.type === "image" || messageData.type === "images") {
        messageBody = "📷 Sent an image";
      }

      // Build the notification message
      // ✅ Include notification payload for reliable delivery on iOS
      // The app's background handler will prevent duplicates by checking message type
      // ✅ Include notification payload for reliable delivery on iOS
      // The app's background handler will prevent duplicates by checking message type
      const message = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: messageBody,
        },
        data: {
          type: "chat",
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar || "",
          chatRoomId: chatRoomId,
          messageId: messageId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        // Set high priority to ensure delivery even when app is in background
        // Set high priority to ensure delivery even when app is in background
        android: {
          priority: "high",
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      console.log(`📤 Sending chat notification to ${receiverId}`);
      const response = await messaging.send(message);
      console.log(`✅ Successfully sent chat notification: ${response}`);

      return response;
    } catch (error) {
      console.error("❌ Error sending chat notification:", error);

      // If the token is invalid, we could remove it, but we need the user doc ID
      // For now, just log the error
      return null;
    }
  }
);

//TRANSACTIONS
exports.transactionsController = transactionsController
//WALLET
exports.asociateWalletToNewUser = asociateWalletToNewUser
//PAYMENTS
exports.createStripePayment = createStripePayment
exports.stripeWebhook = stripeWebhook