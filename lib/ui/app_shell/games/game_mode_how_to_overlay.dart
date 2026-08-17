import 'dart:async';
import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
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
  final vm = context.read<GamesViewModel>();
  final playable = vm.gamesInfo.any((g) => g.id == mode.name && g.enabled);
  final closed = Completer<void>();
  unawaited(
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: CupertinoColors.black.withValues(alpha: .55),
      transitionDuration: _flipDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void onStatus(AnimationStatus status) {
          if (status != AnimationStatus.dismissed) return;
          animation.removeStatusListener(onStatus);
          if (!closed.isCompleted) closed.complete();
        }

        animation.addStatusListener(onStatus);
        return GameModeHowToOverlay(
          mode: mode,
          animation: animation,
          cardWidth: cardWidth,
          anchor: anchor,
          onClose: () => Navigator.pop(dialogContext),
          onPlay: playable
              ? () {
                  Navigator.pop(dialogContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      showEnterGameDialog(context, vm, mode);
                    }
                  });
                }
              : null,
        );
      },
      transitionBuilder: (context, animation, secondary, child) => child,
    ).whenComplete(() {
      Future<void>.delayed(_flipDuration, () {
        if (!closed.isCompleted) closed.complete();
      });
    }),
  );
  return closed.future;
}

class GameModeHowToOverlay extends StatefulWidget {
  const GameModeHowToOverlay({
    super.key,
    required this.mode,
    required this.animation,
    required this.cardWidth,
    required this.onPlay,
    required this.onClose,
    this.anchor,
  });

  final GameMode mode;
  final Animation<double> animation;
  final double cardWidth;
  final Rect? anchor;
  final VoidCallback? onPlay;
  final VoidCallback onClose;

  @override
  State<GameModeHowToOverlay> createState() => _GameModeHowToOverlayState();
}

class _GameModeHowToOverlayState extends State<GameModeHowToOverlay>
    with SingleTickerProviderStateMixin {
  List<InstructionSection> _sections = const [];
  late final AnimationController _hintPulse;
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  bool _dismissing = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    widget.animation.addStatusListener(_onFlipStatus);
    _load();
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onFlipStatus);
    _hintPulse.dispose();
    super.dispose();
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _tryRevealBack();
    }
  }

  Future<void> _load() async {
    try {
      final data = await loadInstructions(widget.mode);
      if (!mounted) return;
      setState(() => _sections = data.sections);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryRevealBack();
      });
    } catch (_) {}
  }

  Future<void> _tryRevealBack() async {
    if (_dismissing || _revealed) return;
    if (!widget.animation.isCompleted) return;
    if (_sections.length < 2) return;
    final carousel = _carouselKey.currentState;
    if (carousel == null) return;
    _revealed = true;
    await carousel.revealBack();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _carouselKey.currentState?.collapseBack();
    if (!mounted) return;
    SoundService.instance.playLayered(GameSound.button);
    widget.onClose();
  }

  void _openPlay() {
    final play = widget.onPlay;
    if (_dismissing || play == null) return;
    _dismissing = true;
    play();
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: AnimatedBuilder(
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
                child: GestureDetector(
                  onTap: () {},
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
                                    transform: Matrix4.identity()
                                      ..rotateY(math.pi),
                                    child: _InstructionFace(
                                      carouselKey: _carouselKey,
                                      sections: _sections,
                                      cardWidth: cardWidth,
                                      stageWidth: stageWidth,
                                      stageHeight: stageHeight,
                                      firstPageFace: modeFace,
                                      onPlay: widget.onPlay == null
                                          ? null
                                          : _openPlay,
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
      ),
    );
  }
}

class _InstructionFace extends StatelessWidget {
  const _InstructionFace({
    required this.carouselKey,
    required this.sections,
    required this.cardWidth,
    required this.stageWidth,
    required this.stageHeight,
    required this.firstPageFace,
    required this.onPlay,
  });

  final GlobalKey<StackedCardCarouselState> carouselKey;
  final List<InstructionSection> sections;
  final double cardWidth;
  final double stageWidth;
  final double stageHeight;
  final Color firstPageFace;
  final VoidCallback? onPlay;

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
        key: carouselKey,
        itemCount: sections.length,
        widthFactor: 1,
        maxCardWidth: cardWidth,
        startBackCollapsed: true,
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
