import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

//Start (only at the begining of the game when everyone has joined)
//people join as Ready.
//A random dealer is selected...

//Deal [Start of each round] (gives n cards to each player) 
// deals m card to table. (casino deals 4) (tresydos deals 1)

//DealSame [In vetween rounds]
// for casino, deals 4 cards to players. tresy dos doesn't use this

//Set ready. After each round each player gets to set their state to Ready.. 
//if everyone's ready and round complete,
//     automatically create new deck.
//     select new dealer.
//     make deal available for dealer

//NoAction. players that can't controll or deal will have this option.

enum InGameAction { start, share, deal, dealSame, setReady, waiting, noAction }
enum OutGameAction {create, load, join, leave, delete }
enum PlayActionEnum { play, takeCard, takeStack, add, pair, addTake, addPair}
abstract class PlayAction {
  String performedById;
  PlayAction({required this.performedById});
}

class PlayCardAction extends PlayAction {
  PlayingCardModel usedCard;
  PlayCardAction({required this.usedCard, required super.performedById});
}

class TakeCardAction extends PlayAction {
  PlayingCardModel usedCard;
  PlayingCardModel targetCard;

  TakeCardAction({required this.usedCard, required this.targetCard, required super.performedById});
}

class TakeStackAction extends PlayAction {
  PlayingCardModel usedCard;
  PlayingAreaStackModel targetStack;

  TakeStackAction({required this.usedCard, required this.targetStack, required super.performedById});
}

class AddTableCardsAction extends PlayAction {
  List<PlayingCardModel> targetCards;
  List<PlayingAreaStackModel> targetStacks;
  AddTableCardsAction({
    required this.targetCards,
    required this.targetStacks, required super.performedById,
  });
}
class AddCardsAction extends PlayAction {
  PlayingCardModel usedCard;
  List<PlayingCardModel> targetCards;
  List<PlayingAreaStackModel> targetStacks;
  AddCardsAction({
   required this.usedCard,
    required this.targetCards,
    required this.targetStacks, required super.performedById,
  });
}

class PairCardsAction extends PlayAction {
  PlayingCardModel? usedCard;
  List<PlayingCardModel> targetCards;
  List<PlayingAreaStackModel> targetStacks;
  PairCardsAction({
    this.usedCard,
    required this.targetCards,
    required this.targetStacks, required super.performedById,
  });
}
