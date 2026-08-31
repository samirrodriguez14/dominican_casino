import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  type GameModeId,
  type MatchSeeker,
  pickGroup,
} from "./matchmaking_logic.js";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const GROW_DEFER_MS = 8000;
const WAITING_MAX_AGE_MS = 2 * 60 * 1000;
const TIMEOUT_MS = 60 * 1000;
const QUEUE_COLLECTION = "matchmakingQueue";

interface QueueSeeker extends MatchSeeker {
  ref: admin.firestore.DocumentReference;
}

/**
 * Firestore trigger: attempt match when someone enters/refreshes the queue.
 */
export const onMatchmakingQueueWrite = onDocumentWritten(
  {
    document: `${QUEUE_COLLECTION}/{uid}`,
    timeoutSeconds: 60,
  },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data();
    if (!data || data.status !== "waiting") return;

    const formed = await runMatchPass({deferGrow: true});
    if (formed.deferred) {
      await sleep(GROW_DEFER_MS);
      await runMatchPass({deferGrow: false});
    }
  },
);

/**
 * Minute sweeper: time out stale seekers and drop old terminal tickets.
 */
export const onMatchmakingSweep = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();
    const now = Date.now();
    const waiting = await db
      .collection(QUEUE_COLLECTION)
      .where("status", "==", "waiting")
      .limit(200)
      .get();

    let timedOut = 0;
    for (const doc of waiting.docs) {
      const created = createdAtMs(doc.data());
      if (created > 0 && now - created >= TIMEOUT_MS) {
        await doc.ref.update({
          status: "timedOut",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        timedOut += 1;
      }
    }

    const staleCutoff = admin.firestore.Timestamp.fromMillis(
      now - 6 * 60 * 60 * 1000,
    );
    for (const status of ["matched", "timedOut", "cancelled"] as const) {
      const stale = await db
        .collection(QUEUE_COLLECTION)
        .where("status", "==", status)
        .where("updatedAt", "<=", staleCutoff)
        .limit(50)
        .get();
      for (const doc of stale.docs) {
        await doc.ref.delete();
      }
    }

    logger.info("Matchmaking sweep", {timedOut, waiting: waiting.size});
    // Catch matches the onWrite path missed (e.g. only one write then quiet).
    await runMatchPass({deferGrow: false});
  },
);

/**
 * Load waiting seekers and form as many lobbies as possible.
 * @param {object} opts Match options.
 * @param {boolean} opts.deferGrow When true, skip forming under-filled growable
 *   tables so the caller can wait and retry.
 * @return {Promise<{deferred: boolean, formed: number}>}
 */
async function runMatchPass(
  opts: {deferGrow: boolean},
): Promise<{deferred: boolean; formed: number}> {
  const seekers = await loadWaitingSeekers();
  if (seekers.length < 2) {
    return {deferred: false, formed: 0};
  }

  let deferred = false;
  let formed = 0;
  const used = new Set<string>();

  // Repeat until no more groups form this pass.
  for (let guard = 0; guard < 20; guard++) {
    const available = seekers.filter((s) => !used.has(s.uid));
    const pick = pickGroup(available, opts.deferGrow);
    if (!pick) break;
    if (pick.kind === "defer") {
      deferred = true;
      break;
    }

    const ok = await claimAndCreateGame(pick.mode, pick.stake, pick.members);
    if (ok) {
      formed += 1;
      for (const m of pick.members) used.add(m.uid);
    } else {
      // Claim raced — stop this pass; another run will retry.
      break;
    }
  }

  logger.info("Match pass", {
    seekers: seekers.length,
    formed,
    deferred,
    deferGrow: opts.deferGrow,
  });
  return {deferred, formed};
}

/**
 * Atomically claim seekers and create the lobby game.
 * @param {GameModeId} mode Chosen mode.
 * @param {number} stake Entry cost.
 * @param {QueueSeeker[]} members Claimed seekers.
 * @return {Promise<boolean>} True when claim succeeded.
 */
async function claimAndCreateGame(
  mode: GameModeId,
  stake: number,
  members: MatchSeeker[],
): Promise<boolean> {
  const db = admin.firestore();
  const gid = randomGid();
  const host = members[0];
  const invitedPlayers: Record<
    string,
    {id: string; name?: string; avatarId?: string}
  > = {};
  for (const m of members) {
    invitedPlayers[m.uid] = {
      id: m.uid,
      ...(m.displayName ? {name: m.displayName} : {}),
      ...(m.avatarId ? {avatarId: m.avatarId} : {}),
    };
  }

  // Seat everyone at write time in queue order so controller / dealer /
  // turn rotation are fixed before any client opens the lobby.
  const playersInfo: Record<
    string,
    {id: string; name?: string; avatarId?: string}
  > = {};
  const playerIds: string[] = [];
  for (const m of members) {
    playerIds.push(m.uid);
    playersInfo[m.uid] = {
      id: m.uid,
      ...(m.displayName ? {name: m.displayName} : {}),
      ...(m.avatarId ? {avatarId: m.avatarId} : {}),
    };
  }

  const gamePayload = buildLobbyGame({
    gid,
    controllerId: host.uid,
    mode,
    entryCost: stake,
    targetSeats: members.length,
    invitedPlayers,
    playersInfo,
    playerIds,
  });

  try {
    await db.runTransaction(async (tx) => {
      for (const m of members) {
        const ref = db.collection(QUEUE_COLLECTION).doc(m.uid);
        const snap = await tx.get(ref);
        if (!snap.exists) {
          throw new Error("seeker_missing");
        }
        const data = snap.data() ?? {};
        if (data.status !== "waiting") {
          throw new Error("seeker_not_waiting");
        }
        if (m.ticketId && data.ticketId && data.ticketId !== m.ticketId) {
          throw new Error("ticket_mismatch");
        }
      }

      const gameRef = db.collection("games").doc(gid);
      tx.set(gameRef, gamePayload);

      for (const m of members) {
        const ref = db.collection(QUEUE_COLLECTION).doc(m.uid);
        tx.update(ref, {
          status: "matched",
          matchedGameId: gid,
          matchedGameMode: mode,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
    logger.info("Match formed", {
      gid,
      mode,
      stake,
      uids: members.map((m) => m.uid),
    });
    return true;
  } catch (err) {
    logger.info("Match claim failed", {
      err: err instanceof Error ? err.message : err,
      uids: members.map((m) => m.uid),
    });
    return false;
  }
}

/**
 * @param {object} args Lobby fields.
 * @return {Record<string, unknown>} Firestore game document.
 */
function buildLobbyGame(args: {
  gid: string;
  controllerId: string;
  mode: GameModeId;
  entryCost: number;
  targetSeats: number;
  invitedPlayers: Record<string, unknown>;
  playersInfo: Record<string, unknown>;
  playerIds: string[];
}): Record<string, unknown> {
  return {
    id: args.gid,
    gameMode: args.mode,
    // Oldest seeker is host / initial dealer; Start stays with them.
    controllerId: args.controllerId,
    // All matched seats are written up front → ready for host Start.
    gameStatus: "readyToStart",
    started: false,
    currentTurnPlayerId: "",
    deck: [],
    playingArea: [],
    playingAreaStacks: [],
    tableOrder: [],
    hands: {},
    scores: {},
    playersInfo: args.playersInfo,
    invitedPlayers: args.invitedPlayers,
    playersDeck: {},
    lastTakes: {},
    extraPoints: 0,
    extraPointsHolderId: "",
    lastTookCardId: "",
    winnerId: "",
    cardMoveEvents: [],
    settlementEvents: [],
    round: {
      id: 0,
      roundStatus: "completed",
      roundScores: {},
      nextAcknowledged: false,
    },
    isLocalBot: false,
    botPlayerIds: [],
    entryCost: args.entryCost,
    entryPaidBy: [],
    payoutClaimedBy: [],
    pendingCoins: {},
    viraosCreditedRoundId: -1,
    roundTakeCoins: {},
    roundSpecialCoins: {},
    roundViraoCoins: {},
    turnDurationSeconds: 15,
    isPublic: false,
    targetSeats: args.targetSeats,
    playerIds: args.playerIds,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * @return {Promise<QueueSeeker[]>} Waiting seekers within the age window.
 */
async function loadWaitingSeekers(): Promise<QueueSeeker[]> {
  const db = admin.firestore();
  const cutoff = admin.firestore.Timestamp.fromMillis(
    Date.now() - WAITING_MAX_AGE_MS,
  );
  let snap: admin.firestore.QuerySnapshot;
  try {
    snap = await db
      .collection(QUEUE_COLLECTION)
      .where("status", "==", "waiting")
      .where("createdAt", ">=", cutoff)
      .orderBy("createdAt", "asc")
      .limit(100)
      .get();
  } catch (err) {
    logger.warn("Queue query with createdAt failed, falling back", {err});
    snap = await db
      .collection(QUEUE_COLLECTION)
      .where("status", "==", "waiting")
      .limit(100)
      .get();
  }

  const now = Date.now();
  const out: QueueSeeker[] = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const created = createdAtMs(data);
    if (created > 0 && now - created >= TIMEOUT_MS) continue;
    const uid = typeof data.uid === "string" ? data.uid : doc.id;
    const maxEntryCost =
      typeof data.maxEntryCost === "number" ? data.maxEntryCost : 100;
    const maxPlayers =
      typeof data.maxPlayers === "number" ? data.maxPlayers : 6;
    const modes = Array.isArray(data.modes) ?
      data.modes.filter((m): m is string => typeof m === "string") :
      [];
    out.push({
      uid,
      ref: doc.ref,
      modes,
      maxEntryCost,
      maxPlayers: Math.max(2, Math.min(6, maxPlayers)),
      createdAtMs: created || now,
      displayName:
        typeof data.displayName === "string" ? data.displayName : undefined,
      avatarId: typeof data.avatarId === "string" ? data.avatarId : undefined,
      ticketId: typeof data.ticketId === "string" ? data.ticketId : undefined,
    });
  }
  out.sort((a, b) => a.createdAtMs - b.createdAtMs);
  return out;
}

/**
 * @param {admin.firestore.DocumentData} data Queue doc data.
 * @return {number} createdAt epoch ms, or 0.
 */
function createdAtMs(data: admin.firestore.DocumentData): number {
  const raw = data.createdAt;
  if (raw && typeof raw.toMillis === "function") {
    return raw.toMillis();
  }
  if (typeof raw === "number") return raw;
  return 0;
}

/**
 * @return {string} Short game id.
 */
function randomGid(): string {
  return Math.random().toString(36).slice(2, 10);
}

/**
 * @param {number} ms Delay.
 * @return {Promise<void>}
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
