import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/home/home_instruction_card.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

const _flipDuration = Duration(milliseconds: 420);
const _overlayScale = 1.16;

Future<void> showGameModeHowTo(
  BuildContext context,
  GameMode mode, {
  required double cardWidth,
  Rect? anchor,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: _flipDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return GameModeHowToOverlay(
        mode: mode,
        animation: animation,
        cardWidth: cardWidth,
        anchor: anchor,
      );
    },
    transitionBuilder: (context, animation, secondary, child) => child,
  );
}

class GameModeHowToOverlay extends StatefulWidget {
  const GameModeHowToOverlay({
    super.key,
    required this.mode,
    required this.animation,
    required this.cardWidth,
    this.anchor,
  });

  final GameMode mode;
  final Animation<double> animation;
  final double cardWidth;
  final Rect? anchor;

  @override
  State<GameModeHowToOverlay> createState() => _GameModeHowToOverlayState();
}

class _GameModeHowToOverlayState extends State<GameModeHowToOverlay>
    with SingleTickerProviderStateMixin {
  List<InstructionSection> _sections = const [];
  late final AnimationController _hintPulse;

  @override
  void initState() {
    super.initState();
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _hintPulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await loadInstructions(widget.mode);
      if (!mounted) return;
      setState(() => _sections = data.sections);
    } catch (_) {}
  }

  void _openPlay() {
    final vm = context.read<GamesViewModel>();
    showEnterGameDialog(context, vm, widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final screenCenter = Offset(media.size.width / 2, media.size.height / 2);
    final anchorCenter = widget.anchor?.center ?? screenCenter;
    final positionOffset = anchorCenter - screenCenter;
    final modeFace = GameModeCard.pickerFaceFor(theme, widget.mode);
    final cardWidth = widget.cardWidth;
    final stageWidth = cardWidth + 48;
    final stageHeight = cardWidth * (3.5 / 2.5) + 36;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _hintPulse]),
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(
          widget.animation.value.clamp(0.0, 1.0),
        );
        final angle = t * math.pi;
        final showBack = t >= 0.5;
        final backOpacity = ((t - 0.5) * 2).clamp(0.0, 1.0);
        // Grow only while the instruction back is visible; front stays carousel size.
        final scale = 1.0 + (_overlayScale - 1.0) * backOpacity;
        final hintOpacity = backOpacity * (0.35 + 0.55 * _hintPulse.value);
        final grownBottom = widget.anchor != null
            ? widget.anchor!.bottom + widget.anchor!.height * (scale - 1) / 2
            : anchorCenter.dy + (stageHeight * scale) / 2;
        final footerTop = grownBottom + 20;

        return Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: positionOffset,
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: SizedBox(
                      width: stageWidth,
                      height: stageHeight,
                      child: Center(
                        child: showBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _InstructionFace(
                                  sections: _sections,
                                  cardWidth: cardWidth,
                                  stageWidth: stageWidth,
                                  stageHeight: stageHeight,
                                  firstPageFace: modeFace,
                                  onPlay: _openPlay,
                                ),
                              )
                            : SizedBox(
                                width: cardWidth,
                                child: GameModeCard(
                                  mode: widget.mode,
                                  showActions: false,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: footerTop,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: Opacity(
                  opacity: hintOpacity,
                  child: Text(
                    l10n.tapAnywhereToExit,
                    textAlign: TextAlign.center,
                    style: theme.caption.copyWith(
                      color: theme.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstructionFace extends StatelessWidget {
  const _InstructionFace({
    required this.sections,
    required this.cardWidth,
    required this.stageWidth,
    required this.stageHeight,
    required this.firstPageFace,
    required this.onPlay,
  });

  final List<InstructionSection> sections;
  final double cardWidth;
  final double stageWidth;
  final double stageHeight;
  final Color firstPageFace;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    if (sections.isEmpty) {
      return SizedBox(
        width: cardWidth,
        child: AspectRatio(
          aspectRatio: 2.5 / 3.5,
          child: Center(
            child: CupertinoActivityIndicator(color: theme.textPrimary),
          ),
        ),
      );
    }

    return SizedBox(
      width: stageWidth,
      height: stageHeight,
      child: StackedCardCarousel(
        itemCount: sections.length,
        widthFactor: 1,
        maxCardWidth: cardWidth,
        itemBuilder: (context, index) {
          return HomeInstructionCard(
            section: sections[index],
            pageNumber: index + 1,
            totalPages: sections.length,
            firstPageFace: index == 0 ? firstPageFace : null,
            onPlay: onPlay,
          );
        },
      ),
    );
  }
}
