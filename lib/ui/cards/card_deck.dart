import 'dart:math' as math;

import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

class CardDeck extends StatefulWidget {
  final List<PlayingCardModel> cards;
  final bool back;
  final bool showLabel;
  final bool titleBelow;
  final bool? selectedTopCard;
  final int extraPoints;
  final double cardWidth;
  final String title;
  final Function() onTap;

  /// When true, last-take / virao reveals wait until this becomes false
  /// (capture flights and the rest of the take motion have finished).
  final bool holdExtraReveal;

  /// Most recent capture for this pile. Flips and fans left, then tucks back.
  final List<PlayingCardModel> lastTakenCards;

  /// True when this pile's owner captured last (leftover table cards go here).
  final bool lastCapturer;

  const CardDeck({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.extraPoints,
    required this.title,
    required this.onTap,
    this.back = true,
    this.showLabel = true,
    this.titleBelow = false,
    this.selectedTopCard,
    this.holdExtraReveal = false,
    this.lastTakenCards = const [],
    this.lastCapturer = false,
  });

  @override
  State<CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck> with TickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 380);
  static const _fanDuration = Duration(milliseconds: 420);
  static const _tuckDuration = Duration(milliseconds: 380);
  static const _holdDuration = Duration(milliseconds: 1000);

  late final AnimationController _slide;
  late final Animation<double> _slideT;

  late final AnimationController _lastTake;

  /// Extra cards already fully peeked (before the current slide).
  int _settledExtra = 0;

  /// Count currently laid out (includes cards mid-slide).
  int _shownExtra = 0;

  /// True while tucking cards back under the deck (lose virao).
  bool _tucking = false;

  /// Face-up cards used for the peek strip (kept across a tuck if needed).
  List<PlayingCardModel> _extraFaces = const [];

  List<PlayingCardModel> _lastTakeFaces = const [];
  String _playedLastTakeSig = '';
  int _lastTakeGen = 0;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: _slideDuration);
    _slideT = CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic);
    _slide.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (_tucking) {
        setState(() {
          _shownExtra = widget.extraPoints;
          _settledExtra = _shownExtra;
          _tucking = false;
          _extraFaces = _facesFor(_shownExtra);
        });
      } else {
        setState(() => _settledExtra = _shownExtra);
      }
    });
    // Cold start / rejoin: show current virao without motion.
    _settledExtra = widget.extraPoints;
    _shownExtra = widget.extraPoints;
    _extraFaces = _facesFor(_shownExtra);
    _slide.value = 1;

    _lastTake = AnimationController(vsync: this, duration: _fanDuration);
    _lastTakeFaces = List<PlayingCardModel>.from(widget.lastTakenCards);
    _playedLastTakeSig = _signature(widget.lastTakenCards);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLastTakeReveal();
    });
  }

  List<PlayingCardModel> _facesFor(int count) {
    if (count <= 0 || widget.cards.isEmpty) return const [];
    final n = count.clamp(0, widget.cards.length);
    return List<PlayingCardModel>.from(widget.cards.take(n));
  }

  @override
  void didUpdateWidget(CardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extraPoints != oldWidget.extraPoints ||
        widget.holdExtraReveal != oldWidget.holdExtraReveal ||
        widget.cards != oldWidget.cards) {
      _syncExtraReveal();
    }
    if (widget.lastTakenCards != oldWidget.lastTakenCards ||
        widget.holdExtraReveal != oldWidget.holdExtraReveal ||
        widget.cards != oldWidget.cards) {
      _syncLastTakeReveal();
    }
  }

  void _syncExtraReveal() {
    final target = widget.extraPoints;

    // Shuffle clears the collected pile while motion still holds the reveal.
    // Drop the virao peek strip immediately so it does not flash when the
    // deck becomes visible again after the overlay.
    if (widget.cards.isEmpty &&
        (_shownExtra > 0 || _extraFaces.isNotEmpty || _tucking)) {
      _slide.stop();
      _slide.value = 1;
      setState(() {
        _tucking = false;
        _shownExtra = 0;
        _settledExtra = 0;
        _extraFaces = const [];
      });
      return;
    }

    if (widget.holdExtraReveal) {
      // Wait for collect-to-deck flights to finish before reveal or tuck.
      return;
    }

    if (target == _shownExtra && !_tucking) {
      // Keep faces in sync when the collected pile changes.
      if (_shownExtra > 0) {
        final faces = _facesFor(_shownExtra);
        if (!_listEqualsIds(faces, _extraFaces)) {
          setState(() => _extraFaces = faces);
        }
      }
      return;
    }

    if (target > _shownExtra) {
      setState(() {
        _tucking = false;
        _settledExtra = _shownExtra;
        _shownExtra = target;
        _extraFaces = _facesFor(_shownExtra);
      });
      _slide.forward(from: 0);
      return;
    }

    if (target < _shownExtra) {
      // Slide up under the deck, then drop the tucked cards.
      setState(() {
        _tucking = true;
        _settledExtra = target;
        // Keep _shownExtra at the old count until the tuck finishes.
        if (_extraFaces.length < _shownExtra) {
          _extraFaces = _facesFor(_shownExtra);
        }
      });
      _slide.forward(from: 0);
    }
  }

  void _syncLastTakeReveal() {
    if (widget.cards.isEmpty) {
      _resetLastTake();
      return;
    }
    if (widget.holdExtraReveal) return;
    if (!_lastTakeLandedInPile) return;

    final sig = _signature(widget.lastTakenCards);
    if (sig == _playedLastTakeSig) return;
    if (widget.lastTakenCards.isEmpty) {
      _resetLastTake();
      return;
    }

    _playedLastTakeSig = sig;
    setState(() {
      _lastTakeFaces = List<PlayingCardModel>.from(widget.lastTakenCards);
    });
    _playLastTakeReveal();
  }

  bool get _lastTakeLandedInPile {
    if (widget.lastTakenCards.isEmpty) return true;
    final pileIds = {for (final c in widget.cards) c.id};
    return widget.lastTakenCards.every((c) => pileIds.contains(c.id));
  }

  bool get _lastTakeVisible =>
      _lastTakeFaces.isNotEmpty && _lastTake.value > 0.001;

  void _handleTap() {
    if (_lastTakeVisible) {
      AppHaptics.selectionClick();
      _dismissLastTake();
    } else if (_replayLastTake()) {
      AppHaptics.selectionClick();
    }
    widget.onTap();
  }

  /// Replay the last-take fan even if it already played for this capture.
  bool _replayLastTake() {
    if (widget.cards.isEmpty ||
        widget.lastTakenCards.isEmpty ||
        widget.holdExtraReveal ||
        !_lastTakeLandedInPile) {
      return false;
    }
    _playedLastTakeSig = _signature(widget.lastTakenCards);
    setState(() {
      _lastTakeFaces = List<PlayingCardModel>.from(widget.lastTakenCards);
    });
    _playLastTakeReveal();
    return true;
  }

  void _dismissLastTake() {
    if (_lastTake.value <= 0.001) return;
    _lastTakeGen++;
    _lastTake.stop();
    _lastTake.duration = _tuckDuration;
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.45);
    _lastTake.reverse();
  }

  Future<void> _playLastTakeReveal() async {
    final gen = ++_lastTakeGen;
    _lastTake.stop();
    _lastTake.duration = _fanDuration;
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.7);
    await _lastTake.forward(from: 0);
    if (!mounted || gen != _lastTakeGen) return;
    await Future<void>.delayed(_holdDuration);
    if (!mounted || gen != _lastTakeGen) return;
    _lastTake.duration = _tuckDuration;
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.45);
    await _lastTake.reverse();
  }

  void _resetLastTake() {
    _lastTakeGen++;
    _lastTake.stop();
    _lastTake.value = 0;
    _playedLastTakeSig = '';
    if (_lastTakeFaces.isNotEmpty) {
      setState(() => _lastTakeFaces = const []);
    }
  }

  String _signature(List<PlayingCardModel> cards) =>
      cards.map((c) => c.id).join(',');

  bool _listEqualsIds(List<PlayingCardModel> a, List<PlayingCardModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _lastTakeGen++;
    _slide.dispose();
    _lastTake.dispose();
    super.dispose();
  }

  double _peekHeight(int i, int deckCount, int extraCount) {
    return (deckCount / 3) + 8 + ((extraCount - i) * 8);
  }

  double _extraT(int index) {
    if (_tucking) {
      return index < _settledExtra ? 1.0 : (1.0 - _slideT.value);
    }
    return index < _settledExtra ? 1.0 : _slideT.value;
  }

  double _extraPeekOut(int deckCount) {
    if (_shownExtra <= 0 || _extraFaces.isEmpty) return 0;
    var maxPeek = 0.0;
    for (var i = 0; i < _shownExtra; i++) {
      maxPeek = math.max(
        maxPeek,
        _peekHeight(i, deckCount, _shownExtra) * _extraT(i),
      );
    }
    return maxPeek;
  }

  TextStyle get _titleStyle {
    final theme = AppStyle.theme;
    if (!widget.lastCapturer) return theme.mutedText;
    return theme.mutedText.copyWith(
      color: theme.turnHighlight.withValues(alpha: .92),
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckCount = widget.cards.length;
    final cardWidth = widget.cardWidth;
    final cardHeight = cardWidth * 1.4;
    final layers = deckCount <= 0 ? 0 : (deckCount / 8).ceil();
    final radius = (cardWidth * 0.125).clamp(6.0, 14.0);
    final highlight = AppStyle.theme.turnHighlight;

    return GestureDetector(
      onTap: _handleTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        clipBehavior: Clip.none,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.titleBelow && widget.title.isNotEmpty)
              SizedBox(
                width: cardWidth,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 280),
                  style: _titleStyle,
                  child: Text(widget.title, textAlign: TextAlign.center),
                ),
              ),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([_lastTake, _slide]),
                builder: (_, _) {
                  final peekOut = _extraPeekOut(deckCount);
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        left: -3,
                        top: -3,
                        right: -3,
                        bottom: -3 - peekOut,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                radius + 2,
                              ),
                              color: widget.lastCapturer
                                  ? highlight.withValues(alpha: .10)
                                  : highlight.withValues(alpha: 0),
                              boxShadow: widget.lastCapturer
                                  ? [
                                      BoxShadow(
                                        color: highlight.withValues(
                                          alpha: .20,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 0.25,
                                      ),
                                    ]
                                  : const [],
                            ),
                          ),
                        ),
                      ),
                      if (_shownExtra > 0 && _extraFaces.isNotEmpty)
                        for (var i = 0; i < _shownExtra; i++)
                          if (i < _extraFaces.length)
                            _buildExtraCard(
                              index: i,
                              deckCount: deckCount,
                              cardWidth: cardWidth,
                              face: _extraFaces[i],
                            ),
                      if (deckCount == 0)
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: Icon(
                            CupertinoIcons.minus_circle_fill,
                            color: AppStyle.theme.muted.withValues(
                              alpha: .45,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < layers; i++)
                          Positioned(
                            top: -((layers - 1 - i) * 2.0),
                            left: 0,
                            child: (!widget.back)
                                ? PlayingCard(
                                    width: cardWidth,
                                    playingCardModel: widget.cards.last,
                                    isSelected:
                                        widget.selectedTopCard ?? false,
                                  )
                                : PlayingCardBack(width: cardWidth),
                          ),
                      if (widget.cards.isNotEmpty && widget.showLabel)
                        Padding(
                          padding: EdgeInsets.only(top: cardWidth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyle.theme.muted.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppStyle.theme.border.withValues(
                                  alpha: .35,
                                ),
                              ),
                            ),
                            child: Text(
                              "x${widget.cards.length}",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppStyle.theme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      if (_lastTakeFaces.isNotEmpty &&
                          _lastTake.value > 0.001)
                        _buildLastTakeFan(cardWidth, cardHeight),
                    ],
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _slide,
              builder: (_, _) {
                return SizedBox(height: _extraPeekOut(deckCount));
              },
            ),
            if (widget.titleBelow && widget.title.isNotEmpty)
              SizedBox(
                width: cardWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    style: _titleStyle,
                    child: Text(widget.title, textAlign: TextAlign.center),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastTakeFan(double cardWidth, double cardHeight) {
    final n = _lastTakeFaces.length;
    final t = Curves.easeOutCubic.transform(_lastTake.value);
    final step = (cardWidth * 0.42).clamp(14.0, 22.0);
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              top: 0,
              right: (i + 1) * step * t,
              child: IgnorePointer(
                child: _flippingTakeCard(_lastTakeFaces[i], t, cardWidth),
              ),
            ),
        ],
      ),
    );
  }

  Widget _flippingTakeCard(
    PlayingCardModel card,
    double t,
    double width,
  ) {
    final angle = t * math.pi;
    final showFace = angle > math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      child: showFace
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: PlayingCard(
                playingCardModel: card,
                isSelected: false,
                width: width,
                showCoinHint: false,
              ),
            )
          : PlayingCardBack(width: width),
    );
  }

  Widget _buildExtraCard({
    required int index,
    required int deckCount,
    required double cardWidth,
    required PlayingCardModel face,
  }) {
    final peek = _peekHeight(index, deckCount, _shownExtra);
    final t = _extraT(index);

    return Positioned(
      top: peek * t,
      left: 1,
      child: PlayingCard(
        playingCardModel: face,
        isSelected: false,
        width: cardWidth - 2,
      ),
    );
  }
}
