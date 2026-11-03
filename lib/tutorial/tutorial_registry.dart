import 'package:youareup/l10n/app_localizations.dart';
import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/tutorial_step.dart';
import 'package:youareup/tutorial/tutorial_bs_factory.dart';
import 'package:youareup/tutorial/tutorial_bs_steps.dart';
import 'package:youareup/tutorial/tutorial_casino_factory.dart';
import 'package:youareup/tutorial/tutorial_casino_speed_factory.dart';
import 'package:youareup/tutorial/tutorial_casino_speed_steps.dart';
import 'package:youareup/tutorial/tutorial_casino_steps.dart';
import 'package:youareup/tutorial/tutorial_rummy_factory.dart';
import 'package:youareup/tutorial/tutorial_rummy_steps.dart';
import 'package:youareup/tutorial/tutorial_tresydos_factory.dart';
import 'package:youareup/tutorial/tutorial_tresydos_steps.dart';
import 'package:flutter/material.dart';

List<TutorialStep> buildTutorialSteps({
  required GameMode mode,
  required AppLocalizations l10n,
  required GlobalKey tableContentKey,
  required GlobalKey myDeckKey,
  required GlobalKey addButtonKey,
  required GlobalKey takeStackButtonKey,
  required GlobalKey Function(String cardId) handCardKey,
  required GlobalKey Function(String cardId) tableCardKey,
  required GlobalKey? Function() firstStackKey,
}) {
  return switch (mode) {
    GameMode.casino => getCasinoTutorialSteps(
      l10n: l10n,
      tableContentKey: tableContentKey,
      myDeckKey: myDeckKey,
      addButtonKey: addButtonKey,
      takeStackButtonKey: takeStackButtonKey,
      handCardKey: handCardKey,
      tableCardKey: tableCardKey,
      firstStackKey: firstStackKey,
    ),
    GameMode.casinoSpeed => getCasinoSpeedTutorialSteps(
      l10n: l10n,
      tableContentKey: tableContentKey,
      myDeckKey: myDeckKey,
      addButtonKey: addButtonKey,
      takeStackButtonKey: takeStackButtonKey,
      handCardKey: handCardKey,
      tableCardKey: tableCardKey,
      firstStackKey: firstStackKey,
    ),
    GameMode.rummy => getRummyTutorialSteps(l10n: l10n),
    GameMode.tresydos => getTresydosTutorialSteps(l10n: l10n),
    GameMode.bs => getBsTutorialSteps(l10n: l10n),
    _ => const [],
  };
}

GameState? createTutorialGameState({
  required GameMode mode,
  required String gid,
  required String playerId,
}) {
  return switch (mode) {
    GameMode.casino => TutorialCasinoFactory.createBasicTakeTutorial(
      gid: gid,
      playerId: playerId,
    ),
    GameMode.casinoSpeed => TutorialCasinoSpeedFactory.createBasicTakeTutorial(
      gid: gid,
      playerId: playerId,
    ),
    GameMode.rummy => TutorialRummyFactory.create(gid: gid, playerId: playerId),
    GameMode.tresydos =>
      TutorialTresydosFactory.create(gid: gid, playerId: playerId),
    GameMode.bs => TutorialBsFactory.create(gid: gid, playerId: playerId),
    _ => null,
  };
}
