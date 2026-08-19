import 'dart:async';
import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_list.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Peeking playing card in the shell corner. Swipe up to expand; bottom link
/// flips between current games and history like other playing-card faces.
class CurrentGamesPeekCard extends StatefulWidget {
  const CurrentGamesPeekCard({super.key});

  @override
  State<CurrentGamesPeekCard> createState() => _CurrentGamesPeekCardState();
}

class _CurrentGamesPeekCardState extends State<CurrentGamesPeekCard>
    with TickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 380);
  static const _flipDuration = Duration(milliseconds: 420);
  static const _nudgeDuration = Duration(milliseconds: 2400);
  static const _peekVisible = 78.0;
  static const _peekAngle = -0.22;
  static const _dragRange = 280.0;
  static const _cardRadius = 18.0;

  late final AnimationController _expand;
  late final AnimationController _flip;
  late final AnimationController _nudge;
  bool _draggingExpand = false;
  GamesViewModel? _gamesVm;
  int _lastTurnCount = -1;
  Timer? _nudgeHaptic;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(vsync: this, duration: _expandDuration)
      ..addStatusListener(_onExpandStatus)
      ..addListener(_onExpandTick);
    _flip = AnimationController(vsync: this, duration: _flipDuration)
      ..addListener(_tick);
    _nudge = AnimationController(vsync: this, duration: _nudgeDuration)
      ..addListener(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<GamesViewModel>();
    if (identical(_gamesVm, vm)) return;
    _gamesVm?.removeListener(_onGamesChanged);
    _gamesVm = vm;
    _lastTurnCount = vm.yourTurnCount;
    _gamesVm!.addListener(_onGamesChanged);
    _syncNudge();
  }

  @override
  void dispose() {
    _nudgeHaptic?.cancel();
    _gamesVm?.removeListener(_onGamesChanged);
    _expand.removeStatusListener(_onExpandStatus);
    _expand.removeListener(_onExpandTick);
    _flip.removeListener(_tick);
    _nudge.removeListener(_tick);
    _expand.dispose();
    _flip.dispose();
    _nudge.dispose();
    super.dispose();
  }

  bool get _shouldNudge {
    final count = _gamesVm?.yourTurnCount ?? 0;
    return count > 0 && _expand.value <= 0.08 && !_draggingExpand;
  }

  void _onGamesChanged() {
    final count = _gamesVm?.yourTurnCount ?? 0;
    final grew = _lastTurnCount >= 0 && count > _lastTurnCount;
    _lastTurnCount = count;
    if (!mounted) return;
    _syncNudge(restart: grew && _shouldNudge, cue: grew && _shouldNudge);
  }

  void _syncNudge({bool restart = false, bool cue = false}) {
    if (!_shouldNudge) {
      if (_nudge.isAnimating) _nudge.stop();
      if (_nudge.value != 0) _nudge.value = 0;
      return;
    }
    if (cue) _cueNudgeFeedback();
    if (restart && _nudge.isAnimating) {
      _nudge.stop();
      _nudge.value = 0;
    }
    if (!_nudge.isAnimating) {
      _nudge.repeat(min: 0, max: 1, period: _nudgeDuration);
    }
  }

  void _cueNudgeFeedback() {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();
    _nudgeHaptic?.cancel();
    _nudgeHaptic = Timer(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      AppHaptics.lightImpact();
    });
  }

  /// Decaying hops, then a rest until the cycle repeats.
  static double _nudgeLift(double t) {
    final ms = t * _nudgeDuration.inMilliseconds;
    const hops = <(double, double, double)>[
      (0, 294, 1.00),
      (294, 510, 0.52),
      (510, 686, 0.28),
      (686, 823, 0.12),
    ];
    for (final h in hops) {
      if (ms >= h.$1 && ms < h.$2) {
        final local = (ms - h.$1) / (h.$2 - h.$1);
        return h.$3 * math.sin(local * math.pi);
      }
    }
    return 0;
  }

  void _onExpandTick() {
    _syncNudge();
    _tick();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _onExpandStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _flip.value != 0) {
      _flip.value = 0;
    }
  }

  bool get _open => _expand.value >= 0.5;

  Future<void> _snap({required bool open}) async {
    if (_expand.isAnimating || _flip.isAnimating) return;

    var cued = false;
    void cue() {
      if (cued) return;
      cued = true;
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.lightImpact();
    }

    if (!open && _flip.value > 0) {
      cue();
      if (_expand.value < 0.98) {
        _flip.value = 0;
      } else {
        await _flip.animateTo(
          0,
          duration: _flipDuration,
          curve: Curves.easeInOutCubic,
        );
        if (!mounted) return;
      }
    }

    final target = open ? 1.0 : 0.0;
    if ((_expand.value - target).abs() < 0.001) return;
    cue();
    await _expand.animateTo(
      target,
      duration: _expandDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleFromPeek() {
    if (_expand.isAnimating || _flip.isAnimating) return;
    if (_expand.value < 0.5) {
      _snap(open: true);
    }
  }

  void _close() {
    if (_expand.isAnimating || _flip.isAnimating) return;
    _snap(open: false);
  }

  void _onDragStart(DragStartDetails details) {
    if (_expand.isAnimating || _flip.isAnimating) return;
    setState(() => _draggingExpand = true);
    _syncNudge();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_draggingExpand || _expand.isAnimating || _flip.isAnimating) return;
    _expand.value = (_expand.value - details.delta.dy / _dragRange).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_draggingExpand) return;
    if (_expand.isAnimating || _flip.isAnimating) {
      setState(() => _draggingExpand = false);
      return;
    }
    final v = details.velocity.pixelsPerSecond.dy;
    final shouldOpen = v < -650 || (v.abs() < 650 && _expand.value >= 0.4);
    setState(() => _draggingExpand = false);
    _snap(open: shouldOpen);
    _syncNudge();
  }

  static Color _faceFor(AppTheme theme, {required bool history}) {
    return history ? theme.pickerFaceEdge : theme.pickerFaceAlt;
  }

  void _openHistory() {
    if (!_open || _flip.isAnimating || _expand.isAnimating) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
    _flip.forward();
  }

  void _openCurrent() {
    if (!_open || _flip.isAnimating || _expand.isAnimating) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
    _flip.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final yourTurnCount = context.watch<GamesViewModel>().yourTurnCount;
    final currentFace = _faceFor(theme, history: false);
    final historyFace = _faceFor(theme, history: true);
    final bottomInset = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final t = _expand.value;
        final size = constraints.biggest;
        final cardW = homeCardWidth(
          BoxConstraints(
            maxWidth: math.max(220, size.width - 20),
            maxHeight: size.height - 28,
          ),
        );
        final cardH = cardW / homeCardAspect;
        final expandedLeft = (size.width - cardW) / 2;
        final expandedTop = (size.height - cardH) / 2;
        final collapsedLeft = size.width - _peekVisible;
        final collapsedTop = size.height - bottomInset.bottom - _peekVisible;
        final left = collapsedLeft + (expandedLeft - collapsedLeft) * t;
        final top = collapsedTop + (expandedTop - collapsedTop) * t;
        final angle = _peekAngle * (1 - t);
        final contentOpacity = Interval(
          0.18,
          0.62,
          curve: Curves.easeOut,
        ).transform(t);
        final peekOpacity = (1 - t * 1.8).clamp(0.0, 1.0);
        final showingHistory = _flip.value >= 0.5;
        final flipT = Curves.easeInOutCubic.transform(
          _flip.value.clamp(0.0, 1.0),
        );
        final flipAngle = flipT * math.pi;
        final nudgeLift = _nudgeLift(_nudge.value);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: t <= 0.02 && !_draggingExpand,
                child: GestureDetector(
                  onTap: _close,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: CupertinoColors.black.withValues(alpha: 0.5 * t),
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: cardW,
              height: cardH,
              child: Transform.translate(
                offset: Offset(-26 * nudgeLift, -22 * nudgeLift),
                child: Transform.scale(
                  scale: 1 + 0.05 * nudgeLift,
                  alignment: Alignment.topLeft,
                  filterQuality: FilterQuality.medium,
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.topLeft,
                    filterQuality: FilterQuality.medium,
                    child: Transform(
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(flipAngle),
                      child: showingHistory
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _cardShell(
                                face: historyFace,
                                theme: theme,
                                child: _cardInterior(
                                  l10n: l10n,
                                  theme: theme,
                                  contentOpacity: contentOpacity,
                                  peekOpacity: peekOpacity,
                                  yourTurnCount: yourTurnCount,
                                  expandT: t,
                                  history: true,
                                ),
                              ),
                            )
                          : _cardShell(
                              face: currentFace,
                              theme: theme,
                              child: _cardInterior(
                                l10n: l10n,
                                theme: theme,
                                contentOpacity: contentOpacity,
                                peekOpacity: peekOpacity,
                                yourTurnCount: yourTurnCount,
                                expandT: t,
                                history: false,
                              ),
                            ),
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

  Widget _cardInterior({
    required AppLocalizations l10n,
    required AppTheme theme,
    required double contentOpacity,
    required double peekOpacity,
    required int yourTurnCount,
    required double expandT,
    required bool history,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: contentOpacity,
          child: IgnorePointer(
            ignoring:
                _flip.isAnimating ||
                (contentOpacity < 0.35 && !_draggingExpand),
            child: _faceBody(
              l10n: l10n,
              theme: theme,
              title: history ? l10n.gameHistory : l10n.currentGames,
              history: history,
              flipLabel: history ? l10n.currentGames : l10n.gameHistory,
              onFlip: history ? _openCurrent : _openHistory,
            ),
          ),
        ),
        if (!history)
          Positioned(
            top: 10,
            left: 10,
            child: Opacity(
              opacity: peekOpacity,
              child: _PeekBadge(count: yourTurnCount, theme: theme),
            ),
          ),
        if (expandT < 0.55 || _draggingExpand)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: expandT < 0.45 && !_draggingExpand ? _toggleFromPeek : null,
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
            ),
          ),
      ],
    );
  }

  Widget _faceBody({
    required AppLocalizations l10n,
    required AppTheme theme,
    required String title,
    required bool history,
    required String flipLabel,
    required VoidCallback onFlip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Text(
              title,
              style: theme.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
          ),
        ),
        Expanded(
          child: CurrentGamesList(
            history: history,
            onBeforeEnter: _close,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            embeddedInCard: true,
          ),
        ),
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            onPressed: SoundService.wrapTap(onFlip),
            child: Text(
              flipLabel,
              style: theme.mutedText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: theme.muted.withValues(alpha: .45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: const SizedBox(height: 12),
        ),
      ],
    );
  }

  Widget _cardShell({
    required Color face,
    required AppTheme theme,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(_cardRadius),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: child,
      ),
    );
  }
}

class _PeekBadge extends StatelessWidget {
  const _PeekBadge({required this.count, required this.theme});

  final int count;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: count > 0 ? '${l10n.yourTurn}: $count' : l10n.currentGames,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.play_fill, color: theme.textPrimary, size: 22),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.background, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
