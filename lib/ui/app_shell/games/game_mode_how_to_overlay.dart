import 'dart:async';
import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/home/home_instruction_card.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const _flipDuration = Duration(milliseconds: 420);
const _liftDuration = Duration(milliseconds: 340);
const _overlayScale = 1.16;
const _barrierDuration = Duration(milliseconds: 200);

Future<void> showGameModeHowTo(
  BuildContext context,
  GameMode mode, {
  required double cardWidth,
  Rect? anchor,
  bool expandFromAnchor = false,
  bool showPlay = true,
}) {
  final gamesVm = showPlay ? context.read<GamesViewModel>() : null;
  final playable =
      gamesVm != null &&
      gamesVm.gamesInfo.any((g) => g.id == mode.name && g.enabled);
  final closed = Completer<void>();
  unawaited(
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: CupertinoColors.black.withValues(alpha: .55),
      transitionDuration: _barrierDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void onStatus(AnimationStatus status) {
          if (status != AnimationStatus.dismissed) return;
          animation.removeStatusListener(onStatus);
          if (!closed.isCompleted) closed.complete();
        }

        animation.addStatusListener(onStatus);
        return GameModeHowToOverlay(
          mode: mode,
          cardWidth: cardWidth,
          anchor: anchor,
          expandFromAnchor: expandFromAnchor,
          onClose: () => Navigator.pop(dialogContext),
          onPlay: playable
              ? () {
                  Navigator.pop(dialogContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      showEnterGameDialog(context, gamesVm, mode);
                    }
                  });
                }
              : null,
          onTutorial: showPlay && mode == GameMode.casino
              ? () {
                  Navigator.pop(dialogContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    context.go(
                      GameRoutes.game(
                        gameId: Uuid().v4().substring(0, 6),
                        gameMode: GameMode.casino.name,
                        tutorial: true,
                      ),
                    );
                  });
                }
              : null,
        );
      },
      transitionBuilder: (context, animation, secondary, child) => child,
    ).whenComplete(() {
      Future<void>.delayed(_flipDuration + _liftDuration, () {
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
    required this.cardWidth,
    required this.onPlay,
    required this.onClose,
    this.onTutorial,
    this.anchor,
    this.expandFromAnchor = false,
  });

  final GameMode mode;
  final double cardWidth;
  final Rect? anchor;
  final bool expandFromAnchor;
  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;
  final VoidCallback onClose;

  @override
  State<GameModeHowToOverlay> createState() => _GameModeHowToOverlayState();
}

class _GameModeHowToOverlayState extends State<GameModeHowToOverlay>
    with TickerProviderStateMixin {
  List<InstructionSection> _sections = const [];
  late final AnimationController _hintPulse;
  late final AnimationController _lift;
  late final AnimationController _flip;
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
    _lift = AnimationController(vsync: this, duration: _liftDuration)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _flip = AnimationController(vsync: this, duration: _flipDuration)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _tryRevealBack();
      });
    _load();
    _open();
  }

  Future<void> _open() async {
    if (widget.expandFromAnchor && widget.anchor != null) {
      await _lift.forward();
    } else {
      _lift.value = 1;
    }
    if (!mounted || _dismissing) return;
    await _flip.forward();
  }

  @override
  void dispose() {
    _hintPulse.dispose();
    _lift.dispose();
    _flip.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await loadInstructions(
        widget.mode,
        locale: Localizations.localeOf(context),
      );
      if (!mounted) return;
      setState(() => _sections = data.sections);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryRevealBack();
      });
    } catch (_) {}
  }

  Future<void> _tryRevealBack() async {
    if (_dismissing || _revealed) return;
    if (!_flip.isCompleted) return;
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
    if (_flip.value > 0) {
      await _flip.reverse();
      if (!mounted) return;
    }
    if (widget.expandFromAnchor && _lift.value > 0) {
      await _lift.reverse();
      if (!mounted) return;
    }
    widget.onClose();
  }

  void _openPlay() {
    final play = widget.onPlay;
    if (_dismissing || play == null) return;
    _dismissing = true;
    play();
  }

  void _openTutorial() {
    final tutorial = widget.onTutorial;
    if (_dismissing || tutorial == null) return;
    _dismissing = true;
    tutorial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final screenCenter = Offset(media.size.width / 2, media.size.height / 2);
    final modeFace = GameModeCard.pickerFaceFor(theme, widget.mode);
    final targetWidth = widget.cardWidth;
    final targetHeight = targetWidth * (3.5 / 2.5);
    final endRect = Rect.fromCenter(
      center: screenCenter,
      width: targetWidth,
      height: targetHeight,
    );
    final startRect = widget.anchor ?? endRect;
    final liftT = Curves.easeInOutCubic.transform(_lift.value.clamp(0.0, 1.0));
    final flipT = Curves.easeInOutCubic.transform(_flip.value.clamp(0.0, 1.0));
    final rect = widget.expandFromAnchor
        ? Rect.lerp(startRect, endRect, liftT)!
        : (widget.anchor ?? endRect);
    final cardWidth = widget.expandFromAnchor ? rect.width : targetWidth;
    final stageWidth = targetWidth + 48;
    final stageHeight = targetHeight + 36;
    final angle = flipT * math.pi;
    final showBack = flipT >= 0.5;
    final backOpacity = ((flipT - 0.5) * 2).clamp(0.0, 1.0);
    final scale = 1.0 + (_overlayScale - 1.0) * backOpacity;
    final hintOpacity = backOpacity * (0.35 + 0.55 * _hintPulse.value);
    final grownBottom = rect.bottom + rect.height * (scale - 1) / 2;
    final footerTop = grownBottom + 20;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _hintPulse,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: showBack ? rect.center.dx - stageWidth / 2 : rect.left,
                top: showBack ? rect.center.dy - stageHeight / 2 : rect.top,
                width: showBack ? stageWidth : rect.width,
                height: showBack ? stageHeight : rect.height,
                child: GestureDetector(
                  onTap: () {},
                  child: Transform.scale(
                    scale: scale,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _InstructionFace(
                                carouselKey: _carouselKey,
                                sections: _sections,
                                cardWidth: targetWidth,
                                stageWidth: stageWidth,
                                stageHeight: stageHeight,
                                firstPageFace: modeFace,
                                onPlay: widget.onPlay == null
                                    ? null
                                    : _openPlay,
                                onTutorial: widget.onTutorial == null
                                    ? null
                                    : _openTutorial,
                              ),
                            )
                          : GameModeCard(
                              mode: widget.mode,
                              compact: cardWidth < 180,
                              showActions: false,
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
    this.onTutorial,
  });

  final GlobalKey<StackedCardCarouselState> carouselKey;
  final List<InstructionSection> sections;
  final double cardWidth;
  final double stageWidth;
  final double stageHeight;
  final Color firstPageFace;
  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;

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
            onTutorial: onTutorial,
          );
        },
      ),
    );
  }
}
