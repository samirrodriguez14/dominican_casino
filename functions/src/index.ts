import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Notify the next player when currentTurnPlayerId changes.
 * Token is read from users/{uid}.fcmToken — not from game documents.
 */
export const onTurnChange = onDocumentUpdated("games/{gid}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!before || !after) return;

  if (before.currentTurnPlayerId === after.currentTurnPlayerId) return;

  const nextPid = after.currentTurnPlayerId as string | undefined;
  if (!nextPid) return;

  const userSnap = await admin.firestore().collection("users").doc(nextPid).get();
  const token = userSnap.data()?.fcmToken as string | undefined;
  if (!token) {
    console.log(`No FCM token for user ${nextPid}`);
    return;
  }

  await admin.messaging().send({
    token,
    notification: {
      title: "Your turn",
      body: "It's your turn to play",
    },
    data: {
      gid: event.params.gid,
    },
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "turns",
      },
    },
    apns: {
      headers: {
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });
});
