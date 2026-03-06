import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Instructions"),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.go('/home'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                "Objective",
                "Capture cards from the table using cards from your hand. "
                "Players try to collect cards and score points each round.",
              ),

              _section(
                "Turns",
                "Players take turns playing one card from their hand to the table. "
                "If the played card matches a card or stack value, it captures them.",
              ),

              _section(
                "Stacks",
                "Cards can be combined into stacks. Stacks may only be captured "
                "by cards matching the stack value.",
              ),

              _section(
                "Deck",
                "If no play is possible, cards are played to the table until "
                "new captures become available.",
              ),

              _section(
                "Scoring",
                "Points are awarded for captured cards and special combinations.",
              ),

              _section(
                "Winning",
                "The game continues for several rounds until a player reaches "
                "the winning score.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyle.theme.title),
          const SizedBox(height: 6),
          Text(body, style: AppStyle.theme.body),
        ],
      ),
    );
  }
}