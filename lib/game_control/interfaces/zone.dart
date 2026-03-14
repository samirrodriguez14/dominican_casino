enum ZoneType { gameDeck, table, playerHand, playerDeck, stack }

ZoneType zoneTypeFromName(String name){
  switch(name){
    case "gameDeck":
    return ZoneType.gameDeck;
    case "table":
    return ZoneType.table;
    case ("playerHand"):
    return ZoneType.playerHand;
    case "playerDeck":
    return ZoneType.playerDeck;
    case "stack":
    return ZoneType.stack;
    default:
    return ZoneType.gameDeck;
  }
}

class Zone {
  final ZoneType type;
  final String? holderId; //me opponent?

  const Zone({required this.type, this.holderId});

  factory Zone.fromDto(Map<String,dynamic> zoneDto){
    return Zone(type: zoneTypeFromName((zoneDto['type'])), holderId: zoneDto['holderId']);
  }
}