const test = require("node:test");
const assert = require("node:assert/strict");
const {
  pickGroup,
  commonStake,
  effectiveModes,
  minSeats,
  maxSeats,
  planLobbySeats,
  CAROUSEL_MODES,
} = require("../lib/matchmaking_logic.js");

/**
 * @param {object} partial Seeker overrides.
 * @return {object} MatchSeeker
 */
function seeker(partial) {
  return {
    uid: partial.uid ?? "u",
    modes: partial.modes ?? [],
    maxEntryCost: partial.maxEntryCost ?? 100,
    maxPlayers: partial.maxPlayers ?? 6,
    createdAtMs: partial.createdAtMs ?? 1,
    displayName: partial.displayName,
    avatarId: partial.avatarId,
    ticketId: partial.ticketId,
  };
}

test("minSeats / maxSeats for each mode", () => {
  assert.equal(minSeats("casino"), 2);
  assert.equal(minSeats("bs"), 3);
  assert.equal(maxSeats("casino"), 2);
  assert.equal(maxSeats("tresydos"), 4);
  assert.equal(maxSeats("bs"), 6);
});

test("effectiveModes: empty means any carousel mode", () => {
  assert.deepEqual(effectiveModes(seeker({modes: []})), [...CAROUSEL_MODES]);
});

test("effectiveModes: explicit subset", () => {
  assert.deepEqual(
    effectiveModes(seeker({modes: ["bs", "tresydos"]})),
    ["bs", "tresydos"],
  );
});

test("commonStake picks highest shared stake", () => {
  assert.equal(
    commonStake([
      seeker({maxEntryCost: 100}),
      seeker({maxEntryCost: 50}),
    ]),
    50,
  );
  assert.equal(
    commonStake([
      seeker({maxEntryCost: 0}),
      seeker({maxEntryCost: 300}),
    ]),
    0,
  );
});

test("commonStake null when no allowed stake fits", () => {
  // Stakes are 0/50/100/300 — nothing fits below 0.
  assert.equal(
    commonStake([seeker({maxEntryCost: -1})]),
    null,
  );
});

test("2× BS only → no match (needs 3)", () => {
  const a = seeker({uid: "a", modes: ["bs"], createdAtMs: 1});
  const b = seeker({uid: "b", modes: ["bs"], createdAtMs: 2});
  assert.equal(pickGroup([a, b], false), null);
  assert.equal(pickGroup([a, b], true), null);
});

test("2× BS with maxPlayers=2 → still no match", () => {
  const a = seeker({
    uid: "a", modes: ["bs"], maxPlayers: 2, createdAtMs: 1,
  });
  const b = seeker({
    uid: "b", modes: ["bs"], maxPlayers: 2, createdAtMs: 2,
  });
  assert.equal(pickGroup([a, b], false), null);
});

test("3× BS → form bs at min", () => {
  const group = [
    seeker({uid: "a", modes: ["bs"], createdAtMs: 1}),
    seeker({uid: "b", modes: ["bs"], createdAtMs: 2}),
    seeker({uid: "c", modes: ["bs"], createdAtMs: 3}),
  ];
  const defer = pickGroup(group, true);
  assert.equal(defer?.kind, "defer");

  const form = pickGroup(group, false);
  assert.equal(form?.kind, "form");
  if (form?.kind === "form") {
    assert.equal(form.mode, "bs");
    assert.equal(form.members.length, 3);
    assert.equal(form.members[0].uid, "a");
  }
});

test("2× Casino → form immediately (perfect fit)", () => {
  const a = seeker({uid: "a", modes: ["casino"], createdAtMs: 1});
  const b = seeker({uid: "b", modes: ["casino"], createdAtMs: 2});
  for (const deferGrow of [true, false]) {
    const pick = pickGroup([a, b], deferGrow);
    assert.equal(pick?.kind, "form");
    if (pick?.kind === "form") {
      assert.equal(pick.mode, "casino");
      assert.equal(pick.members.length, 2);
    }
  }
});

test("ANY ∩ {tres, casino, casinoSpeed} at 2 → prefer Casino", () => {
  const any = seeker({uid: "a", modes: [], createdAtMs: 1});
  const multi = seeker({
    uid: "b",
    modes: ["tresydos", "casino", "casinoSpeed"],
    createdAtMs: 2,
  });
  const pick = pickGroup([any, multi], true);
  assert.equal(pick?.kind, "form");
  if (pick?.kind === "form") {
    assert.equal(pick.mode, "casino");
  }
});

test("2× Tres with deferGrow → defer; without → form", () => {
  const a = seeker({uid: "a", modes: ["tresydos"], createdAtMs: 1});
  const b = seeker({uid: "b", modes: ["tresydos"], createdAtMs: 2});
  assert.equal(pickGroup([a, b], true)?.kind, "defer");

  const form = pickGroup([a, b], false);
  assert.equal(form?.kind, "form");
  if (form?.kind === "form") {
    assert.equal(form.mode, "tresydos");
    assert.equal(form.members.length, 2);
  }
});

test("single seeker → no match", () => {
  assert.equal(
    pickGroup([seeker({uid: "solo", modes: ["casino"]})], false),
    null,
  );
});

test("incompatible modes → no match", () => {
  const a = seeker({uid: "a", modes: ["casino"], createdAtMs: 1});
  const b = seeker({uid: "b", modes: ["bs"], createdAtMs: 2});
  assert.equal(pickGroup([a, b], false), null);
});

test("stake intersection applied on form", () => {
  const a = seeker({
    uid: "a", modes: ["casino"], maxEntryCost: 50, createdAtMs: 1,
  });
  const b = seeker({
    uid: "b", modes: ["casino"], maxEntryCost: 300, createdAtMs: 2,
  });
  const pick = pickGroup([a, b], false);
  assert.equal(pick?.kind, "form");
  if (pick?.kind === "form") {
    assert.equal(pick.stake, 50);
  }
});

test("planLobbySeats: oldest is controller, seats all", () => {
  const members = [
    seeker({uid: "host", displayName: "Host", createdAtMs: 1}),
    seeker({uid: "guest", displayName: "Guest", createdAtMs: 2}),
  ];
  const plan = planLobbySeats(members);
  assert.equal(plan.controllerId, "host");
  assert.deepEqual(plan.playerIds, ["host", "guest"]);
  assert.equal(plan.playersInfo.host.name, "Host");
  assert.equal(plan.playersInfo.guest.name, "Guest");
});

test("4 seekers: forms Casino pair, leaves Tres pair for next pick", () => {
  const casinoA = seeker({uid: "c1", modes: ["casino"], createdAtMs: 1});
  const casinoB = seeker({uid: "c2", modes: ["casino"], createdAtMs: 2});
  const tresA = seeker({uid: "t1", modes: ["tresydos"], createdAtMs: 3});
  const tresB = seeker({uid: "t2", modes: ["tresydos"], createdAtMs: 4});

  const first = pickGroup([casinoA, casinoB, tresA, tresB], false);
  assert.equal(first?.kind, "form");
  if (first?.kind !== "form") return;
  assert.equal(first.mode, "casino");

  const used = new Set(first.members.map((m) => m.uid));
  const rest = [casinoA, casinoB, tresA, tresB].filter((s) => !used.has(s.uid));
  const second = pickGroup(rest, false);
  assert.equal(second?.kind, "form");
  if (second?.kind === "form") {
    assert.equal(second.mode, "tresydos");
  }
});
