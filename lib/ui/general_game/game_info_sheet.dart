import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

class GameInfoSheet extends StatefulWidget {
  const GameInfoSheet({super.key, required this.vm, this.scrollController});
  final GeneralGameViewModel vm;
  final ScrollController? scrollController;

  @override
  State<GameInfoSheet> createState() => _GameInfoSheetState();
}

class _GameInfoSheetState extends State<GameInfoSheet> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Column(
      children: [
        const SizedBox(height: 10),
        Text("Game: ${vm.gameState.gameMode.name}"),
        const SizedBox(height: 2),
        Text("Rules"),
      ],
    );
  }
}
