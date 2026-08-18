import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
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
    this.onTutorial,
  });

  final InstructionSection section;
  final int pageNumber;
  final int totalPages;
  final Color? firstPageFace;
  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;

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
                onTutorial != null ? 44 : 16,
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
            if (onTutorial != null)
              Positioned(
                top: 10,
                right: 10,
                child: _CardCircleButton(
                  icon: CupertinoIcons.lightbulb_fill,
                  label: AppLocalizations.of(context).startTutorial,
                  onPressed: onTutorial!,
                  size: 32,
                  iconSize: 15,
                ),
              ),
            if (onPlay != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: _CardCircleButton(
                  icon: CupertinoIcons.play_fill,
                  label: AppLocalizations.of(context).play,
                  onPressed: onPlay!,
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
    return [theme.pickerFace, theme.pickerFaceAlt, theme.pickerFaceEdge][i];
  }
}

class _CardCircleButton extends StatelessWidget {
  const _CardCircleButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.size = 52,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onPressed),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.textPrimary.withValues(alpha: .14),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.textPrimary.withValues(alpha: .18),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: theme.textPrimary),
        ),
      ),
    );
  }
}

/// Default how-to on the home instructions pane is Casino.
const homeInstructionMode = GameMode.casino;
