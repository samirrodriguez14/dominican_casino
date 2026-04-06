import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onTurnChange = onDocumentUpdated("games/{gid}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!before || !after) return;

  console.log("start call");

  // Only notify if turn changed
  if (before.currentTurnPlayerId === after.currentTurnPlayerId) return;

  console.log("turn changed");

  const nextPid = after.currentTurnPlayerId;
  const players = after.playersInfo ?? {};

  const player = players[nextPid];

  console.log(`new turn ${player?.id}`);

  if (!player || !player.token) return;

  const tokens = Array.isArray(player.token) ? player.token : [player.token];

  console.log(`token found: ${tokens}`);

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: "Your turn",
      body: "It's your turn to play",
    },
    data: {
      gid: event.params.gid,
    },
    android: {
      notification: {
        sound: "default",
        channelId: "turns",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });
});
