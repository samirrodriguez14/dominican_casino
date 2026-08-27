import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/** Must match WalletConfig.energyCap on the client. */
const ENERGY_CAP = 50;

/** Must match AndroidManifest + NotificationsService on the client. */
const ANDROID_CHANNEL_ID = "fcm_game";

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

  const gameMode =
    typeof after.gameMode === "string" ? after.gameMode : "";
  const copy = _turnCopy();
  logger.info("Turn change notify", {
    gid: event.params.gid,
    nextPid,
    gameMode,
  });
  await _sendToUser(nextPid, copy, {
    type: "turn",
    gid: event.params.gid,
    gameMode,
  });
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

    logger.info("Energy full due", {count: due.size});

    for (const doc of due.docs) {
      const result = await _notifyEnergyFull(doc.id);
      if (result === "skip") continue;
      await doc.ref.update({
        energyFullAt: admin.firestore.FieldValue.delete(),
      });
    }
  },
);

/**
 * Send the energy-full push to the signed-in caller. Use this to test
 * FCM without waiting for regen; does not change energyFullAt.
 * invoker public is Cloud Run IAM (not Firebase Auth). The handler still
 * requires request.auth.
 * @return {{result: string}} sent | skip | clear
 */
export const testEnergyFull = onCall(
  {invoker: "public"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first");
    }
    const result = await _notifyEnergyFull(uid, {force: true});
    return {result};
  },
);

/**
 * Send a turn-style push to the signed-in caller for FCM testing.
 * @return {{result: string}} sent | skip
 */
export const testTurn = onCall(
  {invoker: "public"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first");
    }
    const gid = typeof request.data?.gid === "string" ?
      request.data.gid :
      "test";
    const copy = _turnCopy();
    const sent = await _sendToUser(uid, copy, {
      type: "turn",
      gid,
      gameMode: "test",
    }, {force: true});
    return {result: sent ? "sent" : "skip"};
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
 * Push energy-full, or explain why not.
 * @param {string} uid Auth uid / users doc id.
 * @param {object=} opts Optional flags.
 * @param {boolean=} opts.force Skip in-game / cap checks for testing.
 * @return {Promise<string>} sent, skip (retry later), or clear timestamp.
 */
async function _notifyEnergyFull(
  uid: string,
  opts?: {force?: boolean},
): Promise<"sent" | "skip" | "clear"> {
  const force = opts?.force === true;
  const userSnap = await admin.firestore()
    .collection("users").doc(uid).get();
  const user = userSnap.data();
  if (!user) {
    logger.info("No user doc", {uid});
    return "clear";
  }

  const energy = (user.energy as number | undefined) ?? 0;
  if (!force && energy >= ENERGY_CAP) {
    logger.info("Energy already full in doc", {uid, energy});
    return "clear";
  }

  const viewing = user.activeGameId as string | undefined;
  if (!force && viewing) {
    logger.info("Skip energy, user in game", {uid, viewing});
    return "skip";
  }

  const tokens = _collectFcmTokens(user);
  if (tokens.length === 0) {
    logger.info("No FCM token", {uid});
    return "clear";
  }

  const copy = _energyCopy(user.locale as string | undefined);
  const sent = await _sendToUser(uid, copy, {type: "energy_full"});
  return sent ? "sent" : "skip";
}

/**
 * Collect unique FCM registration tokens for a user profile.
 * @param {Record<string, unknown>|undefined} user users/{uid} data.
 * @return {string[]} De-duplicated tokens.
 */
function _collectFcmTokens(
  user: Record<string, unknown> | undefined,
): string[] {
  if (!user) return [];
  const out = new Set<string>();
  const legacy = user.fcmToken;
  if (typeof legacy === "string" && legacy.length > 0) {
    out.add(legacy);
  }
  const map = user.fcmTokens;
  if (map && typeof map === "object" && !Array.isArray(map)) {
    for (const value of Object.values(map as Record<string, unknown>)) {
      if (typeof value === "string" && value.length > 0) {
        out.add(value);
      }
    }
  }
  return [...out];
}

/**
 * Send an alert to all of a user's FCM tokens.
 * @param {string} uid Auth uid / users doc id.
 * @param {{title: string, body: string}} copy Notification text.
 * @param {Record<string, string>} data Extra FCM data payload.
 * @param {object=} opts Optional flags.
 * @param {boolean=} opts.force Skip in-game skip for testing.
 * @return {Promise<boolean>} True when at least one FCM send succeeded.
 */
async function _sendToUser(
  uid: string,
  copy: {title: string; body: string},
  data: Record<string, string>,
  opts?: {force?: boolean},
): Promise<boolean> {
  const force = opts?.force === true;
  const userSnap = await admin.firestore()
    .collection("users").doc(uid).get();
  const user = userSnap.data();
  const viewingGid = user?.activeGameId as string | undefined;
  const targetGid = data.gid;
  if (!force && targetGid && viewingGid === targetGid) {
    logger.info("Skip, user viewing game", {uid, gid: targetGid});
    return false;
  }
  const tokens = _collectFcmTokens(user);
  if (tokens.length === 0) {
    logger.info("No FCM token", {uid});
    return false;
  }

  const payloadData: Record<string, string> = {
    ...data,
    title: copy.title,
    body: copy.body,
  };

  let anySent = false;
  for (const token of tokens) {
    try {
      const messageId = await admin.messaging().send({
        token,
        notification: {
          title: copy.title,
          body: copy.body,
        },
        data: payloadData,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: ANDROID_CHANNEL_ID,
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
      logger.info("Push sent", {
        uid,
        messageId,
        type: data.type ?? "turn",
        tokenTail: token.slice(-8),
      });
      anySent = true;
    } catch (err) {
      logger.error("FCM send failed", {uid, tokenTail: token.slice(-8), err});
    }
  }
  return anySent;
}
