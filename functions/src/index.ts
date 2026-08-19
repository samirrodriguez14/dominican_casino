import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

/**
 * Notify the next human player when currentTurnPlayerId changes.
 * Token is read from users/{uid}.fcmToken — not from game documents.
 */
export const onTurnChange = onDocumentUpdated("games/{gid}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!before || !after) return;

  if (before.currentTurnPlayerId === after.currentTurnPlayerId) return;

  const nextPid = after.currentTurnPlayerId as string | undefined;
  if (!nextPid) return;

  if (_isBotPid(after, nextPid)) {
    logger.info("Skip bot turn", {gid: event.params.gid, nextPid});
    return;
  }

  const copy = _turnCopy();
  await _sendToUser(nextPid, copy, {gid: event.params.gid});
});

/**
 * When energyFullAt is due, tell that player their bar is full.
 * energyFullAt is written by the client from wallet regen math.
 */
export const onEnergyFull = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const due = await db.collection("users")
      .where("energyFullAt", "<=", now)
      .limit(100)
      .get();

    for (const doc of due.docs) {
      const data = doc.data();
      const energy = (data.energy as number | undefined) ?? 0;
      const token = data.fcmToken as string | undefined;
      if (energy >= 50 || !token) {
        await doc.ref.update({
          energyFullAt: admin.firestore.FieldValue.delete(),
        });
        continue;
      }
      const locale = data.locale as string | undefined;
      const copy = _energyCopy(locale);
      const sent = await _sendToUser(doc.id, copy, {
        type: "energy_full",
      });
      if (!sent) continue;
      await doc.ref.update({
        energyFullAt: admin.firestore.FieldValue.delete(),
      });
    }
  },
);

/**
 * Local/AI seats are not real FCM recipients.
 * @param {object} game Game document.
 * @param {string} pid Candidate player id.
 * @return {boolean} True when pid is a bot seat.
 */
function _isBotPid(
  game: {botPlayerId?: unknown; botPlayerIds?: unknown},
  pid: string,
): boolean {
  if (game.botPlayerId === pid) return true;
  const ids = game.botPlayerIds;
  return Array.isArray(ids) && ids.includes(pid);
}

/**
 * @return {{title: string, body: string}} Turn alert copy.
 */
function _turnCopy(): {title: string; body: string} {
  return {
    title: "Your turn",
    body: "It's your turn to play",
  };
}

/**
 * @param {string|undefined} locale Player language code.
 * @return {{title: string, body: string}} Energy-full copy.
 */
function _energyCopy(
  locale?: string,
): {title: string; body: string} {
  if (locale === "es") {
    return {
      title: "Energía llena",
      body: "Tu energía está llena. ¡A jugar!",
    };
  }
  return {
    title: "Energy full",
    body: "Your energy is full. Come play!",
  };
}

/**
 * Send an alert to users/{uid}.fcmToken.
 * @param {string} uid Auth uid / users doc id.
 * @param {{title: string, body: string}} copy Notification text.
 * @param {Record<string, string>} data Extra FCM data payload.
 * @return {Promise<boolean>} True when FCM accepted the send.
 */
async function _sendToUser(
  uid: string,
  copy: {title: string; body: string},
  data: Record<string, string>,
): Promise<boolean> {
  const userSnap = await admin.firestore()
    .collection("users").doc(uid).get();
  const token = userSnap.data()?.fcmToken as string | undefined;
  if (!token) {
    logger.info("No FCM token", {uid});
    return false;
  }

  try {
    const messageId = await admin.messaging().send({
      token,
      notification: {
        title: copy.title,
        body: copy.body,
      },
      data,
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
            alert: {
              title: copy.title,
              body: copy.body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    logger.info("Push sent", {uid, messageId, type: data.type ?? "turn"});
    return true;
  } catch (err) {
    logger.error("FCM send failed", {uid, err});
    return false;
  }
}
