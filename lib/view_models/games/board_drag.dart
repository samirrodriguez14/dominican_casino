import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

enum BoardDragKind { handCard, tableCard, tableStack }

enum DropTargetKind { emptyTable, tableCard, tableStack }

/// What the player is dragging.
class BoardDragSource {
  const BoardDragSource.hand(PlayingCardModel card)
    : kind = BoardDragKind.handCard,
      card = card,
      stack = null;

  const BoardDragSource.tableCard(PlayingCardModel card)
    : kind = BoardDragKind.tableCard,
      card = card,
      stack = null;

  const BoardDragSource.tableStack(PlayingAreaStackModel stack)
    : kind = BoardDragKind.tableStack,
      card = null,
      stack = stack;

  final BoardDragKind kind;
  final PlayingCardModel? card;
  final PlayingAreaStackModel? stack;

  String get id {
    switch (kind) {
      case BoardDragKind.handCard:
      case BoardDragKind.tableCard:
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

  const DropTarget.tableCard(PlayingCardModel card)
    : kind = DropTargetKind.tableCard,
      card = card,
      stack = null;

  const DropTarget.tableStack(PlayingAreaStackModel stack)
    : kind = DropTargetKind.tableStack,
      card = null,
      stack = stack;

  final DropTargetKind kind;
  final PlayingCardModel? card;
  final PlayingAreaStackModel? stack;

  String? get id {
    switch (kind) {
      case DropTargetKind.emptyTable:
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
      actions.any((a) => a is PlayCardAction);

  String get hintLabel {
    if (actions.isEmpty) return '';
    if (actions.length > 1) return 'Drop to choose';
    return actionLabel(actions.first);
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

String actionLabel(PlayAction action) {
  final name = action.runtimeType.toString();
  switch (name) {
    case 'PlayCardAction':
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
