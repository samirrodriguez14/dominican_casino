import 'dart:ui' show Offset;

import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

enum BoardDragKind { handCard, tableCard, tableStack, deckCard }

enum DropTargetKind {
  emptyTable,
  tableCard,
  tableStack,
  playerHand,
  rummyBoxA,
  rummyBoxB,
}

/// What the player is dragging.
class BoardDragSource {
  const BoardDragSource.hand(PlayingCardModel this.card)
    : kind = BoardDragKind.handCard,
      stack = null;

  const BoardDragSource.tableCard(PlayingCardModel this.card)
    : kind = BoardDragKind.tableCard,
      stack = null;

  const BoardDragSource.tableStack(PlayingAreaStackModel this.stack)
    : kind = BoardDragKind.tableStack,
      card = null;

  const BoardDragSource.deck(PlayingCardModel this.card)
    : kind = BoardDragKind.deckCard,
      stack = null;

  final BoardDragKind kind;
  final PlayingCardModel? card;
  final PlayingAreaStackModel? stack;

  String get id {
    switch (kind) {
      case BoardDragKind.handCard:
      case BoardDragKind.tableCard:
      case BoardDragKind.deckCard:
        return card!.id;
      case BoardDragKind.tableStack:
        return stack!.id;
    }
  }

  bool get isHand => kind == BoardDragKind.handCard;
}

/// Where the finger is / was released.
class DropTarget {
  const DropTarget.emptyTable()
    : kind = DropTargetKind.emptyTable,
      card = null,
      stack = null;

  const DropTarget.tableCard(PlayingCardModel this.card)
    : kind = DropTargetKind.tableCard,
      stack = null;

  const DropTarget.tableStack(PlayingAreaStackModel this.stack)
    : kind = DropTargetKind.tableStack,
      card = null;

  const DropTarget.playerHand()
    : kind = DropTargetKind.playerHand,
      card = null,
      stack = null;

  const DropTarget.rummyBoxA()
    : kind = DropTargetKind.rummyBoxA,
      card = null,
      stack = null;

  const DropTarget.rummyBoxB()
    : kind = DropTargetKind.rummyBoxB,
      card = null,
      stack = null;

  final DropTargetKind kind;
  final PlayingCardModel? card;
  final PlayingAreaStackModel? stack;

  String? get id {
    switch (kind) {
      case DropTargetKind.emptyTable:
      case DropTargetKind.playerHand:
      case DropTargetKind.rummyBoxA:
      case DropTargetKind.rummyBoxB:
        return null;
      case DropTargetKind.tableCard:
        return card!.id;
      case DropTargetKind.tableStack:
        return stack!.id;
    }
  }
}

/// Live Add preview: e.g. dragging 2 onto 3 with 5 in hand → `2+3→5`.
class BuildPreview {
  const BuildPreview({
    required this.label,
    required this.total,
    required this.previewCards,
  });

  final String label;
  final int total;
  final List<PlayingCardModel> previewCards;
}

class DropHover {
  const DropHover({
    required this.target,
    required this.actions,
    this.buildPreview,
  });

  final DropTarget target;
  final List<PlayAction> actions;
  final BuildPreview? buildPreview;

  bool get isEmptyTablePlay =>
      target.kind == DropTargetKind.emptyTable &&
      actions.any((a) => a is PlayCardAction || a is ClaimPlayAction);

  String get hintLabel {
    if (actions.isEmpty) return '';
    if (actions.length > 1) return 'Drop to choose';
    return actionLabel(actions.first);
  }

  /// Same drop slot + same action set (preview cards ignored for equality).
  bool sameAs(DropHover? other) {
    if (other == null) return false;
    if (identical(this, other)) return true;
    if (target.kind != other.target.kind || target.id != other.target.id) {
      return false;
    }
    if (actions.length != other.actions.length) return false;
    for (var i = 0; i < actions.length; i++) {
      if (actions[i].runtimeType != other.actions[i].runtimeType) return false;
    }
    final a = buildPreview;
    final b = other.buildPreview;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.label != b.label || a.total != b.total) return false;
    if (a.previewCards.length != b.previewCards.length) return false;
    for (var i = 0; i < a.previewCards.length; i++) {
      if (a.previewCards[i].id != b.previewCards[i].id) return false;
    }
    return true;
  }
}

class DropPending {
  const DropPending({
    required this.source,
    required this.target,
    required this.actions,
    this.buildPreview,
  });

  final BoardDragSource source;
  final DropTarget target;
  final List<PlayAction> actions;
  final BuildPreview? buildPreview;
}

/// Frozen drag overlay: same visual object continues into the card flight.
class DragHandoff {
  const DragHandoff({
    required this.cardIds,
    required this.globalCenter,
    required this.width,
  });

  final Set<String> cardIds;
  final Offset globalCenter;
  final double width;
}

String actionLabel(PlayAction action) {
  final name = action.runtimeType.toString();
  switch (name) {
    case 'PlayCardAction':
    case 'ClaimPlayAction':
      return 'Play';
    case 'TakeCardAction':
      return 'Take';
    case 'TakeStackAction':
      return 'Take Stack';
    case 'AddCardsAction':
    case 'AddCardStackAction':
    case 'AddTableCardsAction':
      return 'Add';
    case 'PairCardsAction':
      return 'Pair';
    case 'PairTableCardsAction':
      return 'Pair Table';
    case 'AddAndPairCardsAction':
      return 'Add & Pair';
    case 'AddAndTakeAction':
      return 'Add & Take';
    case 'PairAndTakeCardsAction':
      return 'Pair & Take';
    default:
      return name.replaceAll('Action', '');
  }
}
