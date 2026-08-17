import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/sage_theme.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';

/// Game-picker face used on the home How to play stack.
class HomeInstructionCard extends StatelessWidget {
  const HomeInstructionCard({
    super.key,
    required this.section,
    required this.pageNumber,
    required this.totalPages,
    this.firstPageFace,
    this.onPlay,
  });

  final InstructionSection section;
  final int pageNumber;
  final int totalPages;
  final Color? firstPageFace;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final face = _faceFor(theme, pageNumber, firstPageFace: firstPageFace);

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                onPlay != null ? 18 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: theme.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final paragraph in section.body) ...[
                            Text(
                              paragraph,
                              style: theme.body.copyWith(
                                fontSize: 14,
                                height: 1.35,
                                color: theme.textPrimary.withValues(alpha: .9),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (section.specialCards.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: section.specialCards.map((special) {
                                return SizedBox(
                                  width: 72,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 72,
                                        child: PlayingCard(
                                          playingCardModel: PlayingCardModel(
                                            id: 'home-${special.rank}-${special.suit}',
                                            rank: special.rank,
                                            suit: special.suit,
                                          ),
                                          width: 48,
                                          isSelected: false,
                                        ),
                                      ),
                                      Text(
                                        special.points,
                                        textAlign: TextAlign.center,
                                        style: theme.caption.copyWith(
                                          color: theme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: onPlay != null ? 56 : 0),
                    child: Center(
                      child: Text(
                        '$pageNumber / $totalPages',
                        style: theme.caption.copyWith(
                          color: theme.textPrimary.withValues(alpha: .7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onPlay != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onPlay,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.textPrimary.withValues(alpha: .14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.textPrimary.withValues(alpha: .18),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.play_fill,
                      size: 22,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _faceFor(AppTheme theme, int page, {Color? firstPageFace}) {
    if (page == 1 && firstPageFace != null) return firstPageFace;
    final i = (page - 1) % 3;
    if (theme is SageTheme) {
      return [theme.pickerFace, theme.pickerFaceAlt, theme.pickerFaceEdge][i];
    }
    return const [Color(0xFF3A634F), Color(0xFF3D4F58), Color(0xFF2E3A36)][i];
  }
}

/// Default how-to on the home instructions pane is Casino.
const homeInstructionMode = GameMode.casino;
