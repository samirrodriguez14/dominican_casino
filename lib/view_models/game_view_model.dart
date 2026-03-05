import 'dart:developer' as developer;
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

enum Actions { take, play, add, stack }

class RoomViewModel extends ChangeNotifier {
  ///START VAR DECLARATIONS
  ///

  late final GameRepo _gameRepo;
  late final AppRepo _appRepo;
  GameState? currentGame;

  int roundIndex = 1;
  RoundStatus roundStatus = RoundStatus.playing;

  Map<String, bool> roundReady = {};
  Map<String, dynamic> roundScores = {};

  bool iAmReadyForNextRound = false;
  bool bothPlayersReady = false;

  int? _lastShownCompletedRoundIndex;
  bool showRoundCompletePopup = false;

  List<PlayingCardModel> playerCards = [];
  List<PlayingCardModel> playingAreaCards = [];
  List<PlayingAreaStackModel> playingAreaStacks = [];
  List<PlayingCardModel> playerDeckCards = [];

  ///
  ///END VAR DECLARATION

  ///START GETTERS
  ///
  bool get isController => currentGame != null && playerId != null
      ? currentGame!.controllerId == playerId
      : false;

  bool get canStartNextRound =>
      currentGame != null &&
      currentGame!.started &&
      roundStatus == RoundStatus.completed &&
      bothPlayersReady;

  bool get bothPlayersJoined =>
      _gameRepo.gameState?.player1 != "" && _gameRepo.gameState?.player2 != "";

  String? get playerId => _appRepo.player?.id;

  String? get gameId => _appRepo.currentGameId;

  bool get currentTurn {
    final g = currentGame;
    final me = playerId;
    return g != null && me != null && g.currentTurnPlayerId == me;
  }

  String get joinedAsPlayer {
    final g = currentGame;
    final me = playerId;
    if (g == null || me == null) return 'player2';
    return (me == g.player1) ? 'player1' : 'player2';
  }

  String? get opponentId {
    final g = currentGame;
    if (g == null) return null;
    return joinedAsPlayer == 'player1' ? g.player2 : g.player1;
  }

  bool get handsNotNull {
    final g = currentGame;
    final me = playerId;
    final opp = opponentId;
    if (g == null || me == null || opp == null) return false;

    return g.hands[me] != null && g.hands[opp] != null;
  }

  bool get handsEmpty {
    final g = currentGame;
    final me = playerId;
    final opp = opponentId;
    if (g == null || me == null || opp == null) return false;

    final myHand = g.hands[me];
    final oppHand = g.hands[opp];

    return myHand != null &&
        oppHand != null &&
        myHand.isEmpty &&
        oppHand.isEmpty;
  }

  bool get playerLeftMidGame =>
      (currentGame?.player1 == null || currentGame?.player2 == null);

  ///
  ///END GETTERS

  RoomViewModel({required GameRepo gameRepo, required AppRepo appRepo})
    : _gameRepo = gameRepo,
      _appRepo = appRepo {
    _gameRepo.addListener(_onGameRepoChanged);
  }

  ///LISTEN FOR GAME CHANGES START
  ///
  void startListening() {
    final id = gameId;
    if (id == null) return;
    _gameRepo.listenToGame(id);
  }

  void _onGameRepoChanged() {
    currentGame = _gameRepo.gameState;
    developer.log("GameViewModel. LoadingGameState $playerId");
    try {
      if (currentGame != null && playerId != null) {
        final g = currentGame!;
        final me = playerId!;

        // existing board state
        playerDeckCards = g.playersDeck[me] ?? [];
        playingAreaCards = g.playingArea;
        playingAreaStacks = g.playingAreaStacks;
        playerCards = g.hands[me] ?? [];

        // round state
        roundIndex = g.roundIndex;
        roundStatus = g.roundStatus;

        roundReady = Map<String, bool>.from(g.roundReady);
        roundScores = Map<String, dynamic>.from(g.roundScores);

        iAmReadyForNextRound = roundReady[me] == true;

        final p1 = g.player1 ?? '';
        final p2 = g.player2 ?? '';

        bothPlayersReady =
            (p1.isNotEmpty &&
            p2.isNotEmpty &&
            roundReady[p1] == true &&
            roundReady[p2] == true);

        // popup logic
        if (roundStatus == RoundStatus.completed && !iAmReadyForNextRound) {
          final alreadyShown = (_lastShownCompletedRoundIndex == roundIndex);

          showRoundCompletePopup = !alreadyShown;

          if (showRoundCompletePopup) {
            _lastShownCompletedRoundIndex = roundIndex;
          }
        } else {
          showRoundCompletePopup = false;
        }
      } else {
        playingAreaCards = [];
        playerCards = [];
        playerDeckCards = [];
        playingAreaStacks = [];

        roundIndex = 1;
        roundStatus = RoundStatus.playing;
        roundReady = {};
        roundScores = {};

        iAmReadyForNextRound = false;
        bothPlayersReady = false;
        showRoundCompletePopup = false;
      }

      cancelSelection();
    } catch (e) {
      _appRepo.leaveGame();
      developer.log("Error mounting the game back $e");
    }
  }

  ///
  ///LISTEN FOR GAME CHANGES FINISH

  ///GENERAL ACTIONS START
  ///
  void startGame() {
    _gameRepo.startGame();
  }

  void playAction(PlayingCardModel card) {
    _gameRepo.makePlay(playerId!, card);
  }

  void takeCardAction(PlayingCardModel card, PlayingCardModel takingCard) {
    _gameRepo.takeCard(playerId!, card, takingCard);
  }

  void stackCardsActon(
    PlayingAreaStackModel stack,
    List<String?> cardStackIds,
  ) {
    _gameRepo.stackCards(playerId!, selectedCard, cardStackIds, stack);
  }

  void pairCardsAction(PlayingAreaStackModel stack, List<String?> cardStackId) {
    _gameRepo.pairStacks(playerId!, cardStackId, selectedCard, stack);
  }

  void stackAndPairStacks(
    PlayingAreaStackModel stack,
    List<String?> cardStackId,
  ) {
    _gameRepo.stackAndPairStacks(playerId!, cardStackId, selectedCard, stack);
  }

  void takeStackAction(PlayingAreaStackModel stack, PlayingCardModel card) {
    _gameRepo.takeStack(playerId!, stack, card);
  }

  void addAndTakeCardsAction(
    List<PlayingCardModel> takingCards,
    PlayingCardModel card,
  ) {
    _gameRepo.addAndTakeCards(playerId!, card, takingCards);
  }

  Future<void> pressContinue() async {
    await _gameRepo.setRoundReady(playerId!);
  }

  Future<void> startNextRound() async {
    await _gameRepo.dealNextRound(playerId!);
  }

  Future<void> redealSameRound() async {
    _gameRepo.dealSameRound();
  }

  Future<void> leaveGame() async {
    if (currentGame != null) {
      await _gameRepo.leaveGame(playerId!);
      await _gameRepo.endGame();
    }
    _appRepo.leaveGame();
    notifyListeners();
  }

  Future<void> endGame() async {
    await _gameRepo.endGame();
  }

  Future<bool> confirmDelete(BuildContext context) async {
    final res = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Leave Game?"),
        content: Text(
          (currentGame == null) ? "Game deleted" : "This will delete the game",
        ),
        actions: [
          if (currentGame != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel"),
            ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text((currentGame == null) ? "Lobby" : "Abandon"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  ///
  ///GENERAL ACTIONS FINISH

  ///CARD SELECTION START
  ///
  PlayingCardModel? selectedCard;
  List<PlayingCardModel> selectedCards = [];
  List<PlayingAreaStackModel> selectedStacks = [];
  void cancelSelection() {
    selectedCards = [];
    selectedCard = null;
    selectedStacks = [];
    notifyListeners();
  }

  void selectCard(PlayingCardModel card) {
    if (selectedCard == card) {
      selectedCard = null;
    } else {
      selectedCard = card;
    }
    notifyListeners();
  }

  void selectCardToStack(PlayingCardModel card) {
    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }
    if (selectedCards.length > 1) {
      selectedCard = null;
    } //Only one more card if card is selected
    notifyListeners();
  }

  void selectStack(PlayingAreaStackModel stack) {
    if (selectedStacks.contains(stack)) {
      selectedStacks.remove(stack);
    } else {
      selectedStacks.add(stack);
    }
    if (selectedStacks.length > 1) selectedCard = null;
    notifyListeners();
  }

  ///
  ///CARD SELECTION FINISH

  ///PERFORMERS START
  ///

  void performPlayOnTable() {
    if (selectedCard == null) return;

    playAction(selectedCard!); // pass card
    selectedCard = null;
    notifyListeners();
  }

  void performStackSelectedCards() {
    final id = Uuid().v4().substring(0, 8);

    final hasCardsCombo =
        (selectedCard != null && selectedCards.isNotEmpty) ||
        selectedCards.length >= 2;
    final hasStackPlusCard =
        (selectedCard != null && selectedStacks.length == 1);

    if (hasCardsCombo || hasStackPlusCard) {
      final totals = possibleBuildTotals(
        selectedCard: selectedCard,
        selectedCards: selectedCards,
        selectedStacks: selectedStacks,
      );

      final chosen = pickTargetValue(totals, max: 14);
      if (chosen == null) return;

      final stack = PlayingAreaStackModel(
        id: id,
        cards: [...selectedCards],
        stackValue: chosen,
      );

      final cardStackIds = <String?>[];

      for (final s in selectedStacks) {
        stack.cards.addAll(s.cards);
        cardStackIds.add(s.id);
      }

      stackCardsActon(stack, cardStackIds);
    }

    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();
  }

  void performPairSelectedCards() {
    final id = Uuid().v4().substring(0, 8);

    // Helper: possible values for a table card (A => {1,14})
    Set<int> possibleValuesForTableCard(PlayingCardModel c) =>
        c.isAce ? {1, 14} : {c.valueLow};

    Set<int> intersectAll(Iterable<Set<int>> sets) {
      final it = sets.iterator;
      if (!it.moveNext()) return <int>{};
      var acc = Set<int>.from(it.current);
      while (it.moveNext()) {
        acc = acc.intersection(it.current);
        if (acc.isEmpty) break;
      }
      return acc;
    }

    int? pickPreferred(Set<int> common) {
      if (common.isEmpty) return null;
      // preference: 14 if possible, else 1, else highest
      if (common.contains(14)) return 14;
      if (common.contains(1)) return 1;
      final list = common.toList()..sort();
      return list.last;
    }

    // ---- Case 1: selectedCard != null (your existing flow) ----
    if (selectedCard != null &&
        (selectedCards.isNotEmpty || selectedStacks.isNotEmpty)) {
      // Compute common pair value from what’s selected on the table (NOT sums)
      final sets = <Set<int>>[];

      for (final c in selectedCards) {
        sets.add(possibleValuesForTableCard(c));
      }
      for (final s in selectedStacks) {
        sets.add({s.stackValue});
      }

      final common = intersectAll(sets);

      // must also be a value you can "claim" with a card in hand (excluding selectedCard)
      final handVals = possibleValuesInHand(playerCards, selectedCard);
      final allowed = common.where(handVals.contains).toSet();

      final desired = pickPreferred(allowed) ?? pickPreferred(common);
      if (desired == null) return;

      final stack = PlayingAreaStackModel(
        id: id,
        cards: [],
        paired: true,
        stackValue: desired,
      );

      if (selectedCards.isNotEmpty) stack.cards.addAll(selectedCards);

      final cardStackIds = <String?>[];
      for (final s in selectedStacks) {
        stack.cards.addAll(s.cards);
        cardStackIds.add(s.id);
      }

      pairCardsAction(stack, cardStackIds);

      selectedCard = null;
      selectedCards = [];
      selectedStacks = [];
      notifyListeners();
      return;
    }

    // ---- Case 2: selectedCard == null (ACE-FLEX pairing) ----
    if (selectedCard == null &&
        (selectedCards.isNotEmpty || selectedStacks.isNotEmpty)) {
      if (selectedCards.isEmpty && selectedStacks.length < 2) return;
      if (selectedCards.length < 2 && selectedStacks.isEmpty) return;

      final sets = <Set<int>>[];

      for (final c in selectedCards) {
        sets.add(possibleValuesForTableCard(c)); // A => {1,14}
      }
      for (final s in selectedStacks) {
        sets.add({s.stackValue}); // stacks fixed for now
      }

      final common = intersectAll(sets);
      if (common.isEmpty) return;

      // Must have that value in hand (since your rules require holding the pair value)
      final handVals = possibleValuesInHand(playerCards, null);
      final allowed = common.where(handVals.contains).toSet();
      final desired = pickPreferred(allowed);
      if (desired == null) return;

      final stack = PlayingAreaStackModel(
        id: id,
        cards: [],
        paired: true,
        stackValue: desired,
      );

      // Add selected cards (all of them)
      if (selectedCards.isNotEmpty) {
        stack.cards.addAll(selectedCards);
      }

      final cardStackIds = <String?>[];
      // Add selected stacks (only if they match desired)
      for (final s in selectedStacks) {
        if (s.stackValue == desired) {
          stack.cards.addAll(s.cards);
          cardStackIds.add(s.id);
        }
      }

      pairCardsAction(stack, cardStackIds);
    }

    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();
  }

  void performStackAndPairSelectedCards() {
    final id = Uuid().v4().substring(0, 8);
    if (selectedCard == null) return;
    if (selectedCards.isEmpty && selectedStacks.isEmpty) return;

    // base totals from selectedCards or selectedStacks[0]
    Set<int> baseTotals;
    if (selectedCards.isNotEmpty) {
      baseTotals = possibleTotals(selectedCards);
    } else {
      baseTotals = {selectedStacks[0].stackValue};
    }

    final selectedVals = possibleCardValues(selectedCard!);

    // candidate final values
    final candidates = <int>{};
    for (final b in baseTotals) {
      for (final sv in selectedVals) {
        candidates.add(b + sv);
      }
    }

    // What values exist on the table right now?
    final tableCardVals = <int>{};
    for (final c in playingAreaCards) {
      tableCardVals.addAll(possibleCardValues(c));
    }
    final tableStackVals = playingAreaStacks.map((s) => s.stackValue).toSet();

    // Require we can actually pair with something on table
    final matching =
        candidates
            .where(
              (v) =>
                  v <= 14 &&
                  (tableCardVals.contains(v) || tableStackVals.contains(v)),
            )
            .toList()
          ..sort();

    if (matching.isEmpty) return;

    final chosen = matching.last; // pick highest match (or first for lowest)

    final stack = PlayingAreaStackModel(
      id: id,
      cards: [],
      stackValue: chosen,
      paired: true,
    );

    // add selectedCards
    if (selectedCards.isNotEmpty) stack.cards.addAll(selectedCards);

    // absorb matching table card(s)
    for (final c in playingAreaCards) {
      if (possibleCardValues(c).contains(chosen)) {
        stack.cards.add(c);
      }
    }

    final cardStackIds = <String?>[];

    // include selectedStacks (always)
    for (final s in selectedStacks) {
      stack.cards.addAll(s.cards);
      cardStackIds.add(s.id);
    }

    // absorb matching table stacks
    for (final s in playingAreaStacks) {
      if (s.stackValue == chosen) {
        stack.cards.addAll(s.cards);
        cardStackIds.add(s.id);
      }
    }

    pairCardsAction(stack, cardStackIds);

    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();
  }

  void performTakeCards() {
    if (selectedCard == null) return;
    if (selectedStacks.length == 1) {
      takeStackAction(selectedStacks[0], selectedCard!);
    } else if (selectedCards.length == 1) {
      takeCardAction(selectedCard!, selectedCards[0]);
    } else if (selectedCards.length > 1) {
      //Create stack of selected cards and takestackaction
      if (possibleTotals(selectedCards).contains(selectedCard!.valueHigh)) {
        addAndTakeCardsAction(selectedCards, selectedCard!);
      }
    }
    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();
  }

  ///
  ///PERFORMERS FINISH

  /// HANDLERS START
  ///

  bool canPlay() {
    return (selectedCard != null &&
        selectedCards.isEmpty &&
        selectedStacks.isEmpty);
  }

  bool canTake() {
    if (selectedCard != null && selectedCards.isNotEmpty) {
      final cardVals = possibleCardValues(selectedCard!); // [1,14] for A
      final totals = possibleTotals(selectedCards); // all possible sums
      return cardVals.any(totals.contains);
    }

    if (selectedCard != null && selectedStacks.isNotEmpty) {
      final cardVals = possibleCardValues(selectedCard!);
      final selectedStacksValues = selectedStacks
          .map((e) => e.stackValue)
          .toList();
      // if stackValue itself can be ace-flex later, you'll update stackValue too.
      final allSame = selectedStacksValues.every(
        (v) => v == selectedStacksValues[0],
      );
      if (!allSame) return false;

      return cardVals.contains(selectedStacksValues[0]);
    }

    return false;
  }

  bool canAdd() {
    if (selectedCard != null) {
      // values of the selectedCard (A => [1,14])
      final cardVals = possibleCardValues(selectedCard!);

      // values you have in hand excluding selectedCard (A => {1,14})
      final handVals = possibleValuesInHand(playerCards, selectedCard);

      // Case 1: selectedCard + selectedCards(sum) must equal some other card you have in hand
      if (selectedCards.isNotEmpty && selectedStacks.isEmpty) {
        final totals = possibleTotals(selectedCards); // ace-flex sums

        for (final cv in cardVals) {
          for (final t in totals) {
            final needed = cv + t;
            if (handVals.contains(needed)) return true;
          }
        }
        return false;
      }

      // Case 2: selectedCard + selectedStack(current value) must equal some other card you have in hand
      if (selectedStacks.length == 1 &&
          !selectedStacks[0].paired &&
          selectedCards.isEmpty) {
        final stackCurrentValue = selectedStacks[0].stackValue;
        for (final cv in cardVals) {
          final needed = stackCurrentValue + cv;
          if (handVals.contains(needed)) return true;
        }
        return false;
      }

      return false;
    }

    // No selectedCard:
    // selecting multiple table cards to form a stack whose value matches a card you have in hand
    if (selectedCard == null) {
      if (selectedCards.length > 1 && selectedStacks.isEmpty) {
        final handVals = possibleValuesInHand(playerCards, null);
        final totals = possibleTotals(selectedCards);
        return totals.any(handVals.contains);
      }
    }

    return false;
  }

  bool canAddAndPair() {
    if (selectedCard == null) return false;

    final handVals = possibleValuesInHand(playerCards, selectedCard);

    // Base values for the selected card (A => [1,14], else [n])
    final selectedVals = possibleCardValues(selectedCard!);

    // What are we adding onto? (either selectedCards total OR selectedStacks[0].targetValue)
    Set<int> addTotals;
    if (selectedCards.isNotEmpty && selectedStacks.isEmpty) {
      addTotals = possibleTotals(selectedCards); // ace-flex sum
    } else if (selectedStacks.length == 1 &&
        !selectedStacks[0].paired &&
        selectedCards.isEmpty) {
      addTotals = {selectedStacks[0].stackValue};
    } else {
      return false;
    }

    // All possible resulting "potentialAddValue" values
    final potentialValues = <int>{};
    for (final sv in selectedVals) {
      for (final t in addTotals) {
        potentialValues.add(sv + t);
      }
    }

    // Values on table (cards + stacks)
    final tableCardVals = <int>{};
    for (final c in playingAreaCards) {
      tableCardVals.addAll(possibleCardValues(c)); // ace-flex table cards too
    }
    final tableStackVals = playingAreaStacks.map((s) => s.stackValue).toSet();

    // Condition: some potential value exists on table AND in your hand
    for (final v in potentialValues) {
      final existsOnTable =
          tableCardVals.contains(v) || tableStackVals.contains(v);
      final existsInHand = handVals.contains(v);
      if (existsOnTable && existsInHand) return true;
    }

    return false;
  }

  bool canPair() {
    final handVals = possibleValuesInHand(playerCards, selectedCard);

    if (selectedCard != null) {
      final cardVals = possibleCardValues(selectedCard!);

      if (selectedCards.isNotEmpty && selectedStacks.isEmpty) {
        final totals = possibleTotals(selectedCards);
        // pair means selectedCard value equals selectedCards sum AND you have that value in hand too
        final matches = cardVals.any(totals.contains);
        if (!matches) return false;

        // The paired value is the intersection; just check if any intersection value is in hand
        for (final v in cardVals) {
          if (totals.contains(v) && handVals.contains(v)) return true;
        }
        return false;
      }

      if (selectedStacks.length == 1 && selectedCards.isEmpty) {
        final sv = selectedStacks[0].stackValue;
        return cardVals.contains(sv) && handVals.contains(sv);
      }
    }

    // selectedCard == null case (pairing multiple items)
    if (selectedCard == null &&
        (selectedCards.isNotEmpty || selectedStacks.isNotEmpty)) {
      if (selectedCards.isEmpty && selectedStacks.length < 2) return false;
      if (selectedCards.length < 2 && selectedStacks.isEmpty) return false;

      // what values do I have in hand to "claim/pair" later?
      final handVals = possibleValuesInHand(playerCards, null);

      // build possible value set per selected item
      final sets = <Set<int>>[];

      for (final c in selectedCards) {
        sets.add(possibleValuesForTableCard(c)); // A => {1,14}
      }
      for (final s in selectedStacks) {
        sets.add({s.stackValue}); // stacks fixed for now
      }

      final common = intersectAll(sets);
      if (common.isEmpty) return false;

      // must have at least one common value present in hand
      return common.any(handVals.contains);
    }

    return false;
  }

  ///
  ///HANDLERS END

  ///HELPERS
  ///
  Set<int> possibleValuesForTableCard(PlayingCardModel c) =>
      c.isAce ? {1, 14} : {c.valueLow};

  Set<int> intersectAll(Iterable<Set<int>> sets) {
    final it = sets.iterator;
    if (!it.moveNext()) return <int>{};
    var acc = Set<int>.from(it.current);
    while (it.moveNext()) {
      acc = acc.intersection(it.current);
      if (acc.isEmpty) break;
    }
    return acc;
  }

  List<int> possibleCardValues(PlayingCardModel c) {
    return c.isAce ? const [1, 14] : [c.valueLow];
  }

  /// All possible totals for a list of cards (accounts for A=1 or 14)
  Set<int> possibleTotals(List<PlayingCardModel> cards) {
    Set<int> totals = {0};
    for (final c in cards) {
      final vals = possibleCardValues(c);
      final next = <int>{};
      for (final t in totals) {
        for (final v in vals) {
          next.add(t + v);
        }
      }
      totals = next;
    }
    return totals;
  }

  /// Player card values excluding selectedCard (your previous behavior)
  Set<int> possibleValuesInHand(
    List<PlayingCardModel> cards,
    PlayingCardModel? selectedCard,
  ) {
    final set = <int>{};
    for (final c in cards) {
      if (selectedCard != null && c == selectedCard) continue;
      set.addAll(possibleCardValues(c));
    }
    return set;
  }

  int? pickTargetValue(Set<int> candidates, {int max = 14, int? mustEqual}) {
    final filtered = candidates.where((v) => v <= max).toList()..sort();
    if (filtered.isEmpty) return null;
    if (mustEqual != null) {
      final i = filtered.indexOf(mustEqual);
      if (i != -1) return mustEqual;
    }
    return filtered.last; // choose highest <= max (good default)
  }

  Set<int> possibleBuildTotals({
    required PlayingCardModel? selectedCard,
    required List<PlayingCardModel> selectedCards,
    required List<PlayingAreaStackModel> selectedStacks,
  }) {
    Set<int> totals = {0};

    // selectedCards sum (ace-flex)
    if (selectedCards.isNotEmpty) {
      final t = possibleTotals(selectedCards);
      final next = <int>{};
      for (final a in totals) {
        for (final b in t) next.add(a + b);
      }
      totals = next;
    }

    // selectedStacks contribute fixed values (your stacks currently fixed)
    for (final s in selectedStacks) {
      final next = <int>{};
      for (final a in totals) {
        next.add(a + s.stackValue);
      }
      totals = next;
    }

    // selectedCard (ace-flex)
    if (selectedCard != null) {
      final vals = possibleCardValues(selectedCard);
      final next = <int>{};
      for (final a in totals) {
        for (final v in vals) next.add(a + v);
      }
      totals = next;
    }

    return totals;
  }

  ///
  /// HELPERS END

  @override
  void dispose() {
    _gameRepo.removeListener(_onGameRepoChanged);
    super.dispose();
  }
}
