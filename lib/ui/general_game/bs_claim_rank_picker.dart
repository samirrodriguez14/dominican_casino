import 'package:dominican_casino/game_control/game_engine/bs/bs_handlers.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

/// Pick the rank the player is claiming for a BS play.
Future<String?> showBsClaimRankPicker(
  BuildContext context, {
  required int cardCount,
}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => _BsClaimRankSheet(cardCount: cardCount),
  );
}

class _BsClaimRankSheet extends StatelessWidget {
  const _BsClaimRankSheet({required this.cardCount});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Claim $cardCount × ?',
              style: theme.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'What rank are you playing?',
              style: theme.caption,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final rank in bsClaimRanks)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: SoundService.wrapTap(
                      () => Navigator.of(context).pop(rank),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.textPrimary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.turnHighlight.withValues(alpha: .55),
                        ),
                      ),
                      child: Text(
                        rank,
                        style: theme.title.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ace counts as 1 (in order with 2).',
              textAlign: TextAlign.center,
              style: theme.caption.copyWith(
                color: theme.textPrimary.withValues(alpha: .65),
              ),
            ),
            const SizedBox(height: 4),
            CupertinoButton(
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(),
              ),
              child: Text('Cancel', style: theme.body),
            ),
          ],
        ),
      ),
    );
  }
}
