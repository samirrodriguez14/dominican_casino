import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ChallengePlayersSection extends StatelessWidget {
  const ChallengePlayersSection({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(
        minHeight: 180,
        maxHeight: screenHeight * 0.42,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.theme.surfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Challenge a Player",
            style: AppStyle.theme.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: AppStyle.theme.muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    placeholder: "Search players",
                    placeholderStyle: AppStyle.theme.mutedText,
                    style: AppStyle.theme.body,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: 8,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ChallengePlayerTile(
                  playerName: "Player ${index + 1}",
                  onChallenge: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengePlayerTile extends StatelessWidget {
  const _ChallengePlayerTile({
    required this.playerName,
    required this.onChallenge,
  });

  final String playerName;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.theme.raisedSurfaceBox(),
      // BoxDecoration(
      //   color: AppStyle.theme.surface,
      //   borderRadius: BorderRadius.circular(AppStyle.theme.radius),
      //   border: Border.all(color: AppStyle.theme.border),
      // ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppStyle.theme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppStyle.theme.border),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppStyle.theme.muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              playerName,
              style: AppStyle.theme.title.copyWith(fontSize: 16),
            ),
          ),

          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppStyle.theme.turnHighlight,
            borderRadius: BorderRadius.circular(10),
            onPressed: SoundService.wrapTap(onChallenge),
            child: const Text("Challenge"),
          ),
        ],
      ),
    );
  }
}
