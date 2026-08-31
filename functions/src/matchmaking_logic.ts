/**
 * Pure matchmaking helpers — no Firestore / Admin SDK.
 * Used by the Cloud Function and by unit tests.
 */

/** Carousel modes — must match gameModeCarouselModes on the client. */
export const CAROUSEL_MODES = [
  "casino",
  "casinoSpeed",
  "tresydos",
  "rummy",
  "bs",
] as const;

export type GameModeId = (typeof CAROUSEL_MODES)[number];

export const MODE_TIEBREAK: GameModeId[] = [
  "casino",
  "casinoSpeed",
  "tresydos",
  "rummy",
  "bs",
];

/** Stakes with no-bet — mirrors WalletConfig.casinoEntryStakes. */
export const STAKES_ALLOW_NO_BET = [0, 50, 100, 300];

/** Prefs for one waiting player (no Firestore ref). */
export interface MatchSeeker {
  uid: string;
  modes: string[];
  maxEntryCost: number;
  maxPlayers: number;
  createdAtMs: number;
  displayName?: string;
  avatarId?: string;
  ticketId?: string;
}

export type PickResult =
  | {kind: "form"; mode: GameModeId; stake: number; members: MatchSeeker[]}
  | {kind: "defer"};

/**
 * Modes this seeker accepts. Empty / full list = any carousel mode.
 * @param {MatchSeeker} seeker Queue row.
 * @return {GameModeId[]}
 */
export function effectiveModes(seeker: MatchSeeker): GameModeId[] {
  const filtered = seeker.modes.filter((m): m is GameModeId =>
    (CAROUSEL_MODES as readonly string[]).includes(m),
  );
  if (filtered.length === 0 || filtered.length >= CAROUSEL_MODES.length) {
    return [...CAROUSEL_MODES];
  }
  return filtered;
}

/**
 * Highest common stake ≤ every member's maxEntryCost.
 * @param {MatchSeeker[]} members Group members.
 * @return {number|null}
 */
export function commonStake(members: MatchSeeker[]): number | null {
  if (members.length === 0) return null;
  const maxAllowed = Math.min(...members.map((m) => m.maxEntryCost));
  const allowed = STAKES_ALLOW_NO_BET.filter((s) => s <= maxAllowed);
  if (allowed.length === 0) return null;
  return Math.max(...allowed);
}

/**
 * @param {GameModeId} mode Mode id.
 * @return {number} Minimum seats to start.
 */
export function minSeats(mode: GameModeId): number {
  return mode === "bs" ? 3 : 2;
}

/**
 * @param {GameModeId} mode Mode id.
 * @return {number} Mode seat cap.
 */
export function maxSeats(mode: GameModeId): number {
  switch (mode) {
  case "bs":
    return 6;
  case "tresydos":
  case "rummy":
    return 4;
  default:
    return 2;
  }
}

/**
 * Choose one matchable group from [available], preferring perfect-fit modes.
 * @param {MatchSeeker[]} available Unused waiting seekers.
 * @param {boolean} deferGrow Whether to defer under-filled growable tables.
 * @return {PickResult|null}
 */
export function pickGroup(
  available: MatchSeeker[],
  deferGrow: boolean,
): PickResult | null {
  if (available.length < 2) return null;

  const sortedModes = [...MODE_TIEBREAK];
  let deferCandidate: PickResult | null = null;

  for (const mode of sortedModes) {
    const min = minSeats(mode);
    const modeMax = maxSeats(mode);
    const pool = available
      .filter((s) => effectiveModes(s).includes(mode))
      .filter((s) => s.maxPlayers >= min)
      .sort((a, b) => a.createdAtMs - b.createdAtMs);
    if (pool.length < min) continue;

    const takeMax = Math.min(pool.length, modeMax);
    let members = pool.slice(0, takeMax);
    // Shrink until every member's maxPlayers allows the group size.
    while (members.length >= min) {
      const cap = Math.min(
        modeMax,
        ...members.map((s) => s.maxPlayers),
      );
      if (members.length <= cap) break;
      members = members.slice(0, members.length - 1);
    }
    if (members.length < min) continue;

    const stake = commonStake(members);
    if (stake === null) continue;

    const n = members.length;
    const perfect = n === modeMax;
    const canGrow = n < Math.min(modeMax, ...members.map((s) => s.maxPlayers));

    if (perfect) {
      return {kind: "form", mode, stake, members};
    }
    if (canGrow && deferGrow) {
      if (!deferCandidate) {
        deferCandidate = {kind: "defer"};
      }
      continue;
    }
    return {kind: "form", mode, stake, members};
  }

  // Second pass: form growable at min if we were not deferring.
  if (!deferGrow) {
    for (const mode of sortedModes) {
      const min = minSeats(mode);
      const modeMax = maxSeats(mode);
      const pool = available
        .filter((s) => effectiveModes(s).includes(mode))
        .filter((s) => s.maxPlayers >= min)
        .sort((a, b) => a.createdAtMs - b.createdAtMs);
      if (pool.length < min) continue;

      let members = pool.slice(0, Math.min(pool.length, modeMax));
      while (members.length >= min) {
        const cap = Math.min(modeMax, ...members.map((s) => s.maxPlayers));
        if (members.length <= cap) break;
        members = members.slice(0, members.length - 1);
      }
      if (members.length < min) continue;
      const stake = commonStake(members);
      if (stake === null) continue;
      return {kind: "form", mode, stake, members};
    }
  }

  return deferCandidate;
}

/**
 * Seat plan written when a match is formed (host = oldest).
 * @param {MatchSeeker[]} members Claimed seekers (already age-sorted).
 * @return {{controllerId: string, playerIds: string[], playersInfo: Object}}
 */
export function planLobbySeats(members: MatchSeeker[]): {
  controllerId: string;
  playerIds: string[];
  playersInfo: Record<
    string,
    {id: string; name?: string; avatarId?: string}
  >;
} {
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
  return {
    controllerId: members[0]?.uid ?? "",
    playerIds,
    playersInfo,
  };
}
