import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

class CardDeck extends StatefulWidget {
  final List<PlayingCardModel> cards;
  final bool back;
  final bool showLabel;
  final bool? selectedTopCard;
  final int extraPoints;
  final double cardWidth;
  final String title;
  final Function() onTap;

  /// When true, virao count changes wait until this becomes false
  /// (e.g. while capture flights to a deck are still running).
  final bool holdExtraReveal;

  const CardDeck({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.extraPoints,
    required this.title,
    required this.onTap,
    this.back = true,
    this.showLabel = true,
    this.selectedTopCard,
    this.holdExtraReveal = false,
  });

  @override
  State<CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 380);

  late final AnimationController _slide;
  late final Animation<double> _slideT;

  /// Extra cards already fully peeked (before the current slide).
  int _settledExtra = 0;

  /// Count currently laid out (includes cards mid-slide).
  int _shownExtra = 0;

  /// True while tucking cards back under the deck (lose virao).
  bool _tucking = false;

  /// Face-up cards used for the peek strip (kept across a tuck if needed).
  List<PlayingCardModel> _extraFaces = const [];

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
    _slide.dispose();
    super.dispose();
  }

  double _peekHeight(int i, int deckCount, int extraCount) {
    return (deckCount / 3) + 8 + ((extraCount - i) * 8);
  }

  @override
  Widget build(BuildContext context) {
    final deckCount = widget.cards.length;
    final cardWidth = widget.cardWidth;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            children: [
              Text(widget.title, style: AppStyle.theme.mutedText),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (_shownExtra > 0 && _extraFaces.isNotEmpty)
                    AnimatedBuilder(
                      animation: _slideT,
                      builder: (_, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            for (var i = 0; i < _shownExtra; i++)
                              if (i < _extraFaces.length)
                                _buildExtraCard(
                                  index: i,
                                  deckCount: deckCount,
                                  cardWidth: cardWidth,
                                  face: _extraFaces[i],
                                ),
                          ],
                        );
                      },
                    ),
                  SizedBox(
                    width: cardWidth,
                    height: cardWidth * 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(CupertinoIcons.minus_circle_fill),
                    ),
                  ),
                  ...List.generate((deckCount / 8).ceil(), (i) {
                    return Column(
                      children: [
                        SizedBox(height: ((deckCount / 8).ceil() - i) * 2),
                        (!widget.back)
                            ? PlayingCard(
                                width: cardWidth,
                                playingCardModel:
                                    widget.cards[widget.cards.length - 2],
                                isSelected: widget.selectedTopCard ?? false,
                              )
                            : PlayingCardBack(width: cardWidth),
                      ],
                    );
                  }),
                  if (widget.cards.isNotEmpty && widget.showLabel)
                    Padding(
                      padding: EdgeInsetsGeometry.only(top: cardWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppStyle.theme.muted.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppStyle.theme.border.withValues(alpha: .35),
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraCard({
    required int index,
    required int deckCount,
    required double cardWidth,
    required PlayingCardModel face,
  }) {
    final peek = _peekHeight(index, deckCount, _shownExtra);
    final double t;
    if (_tucking) {
      // Cards that remain stay fully peeked; tucked ones slide up (1 → 0).
      t = index < _settledExtra ? 1.0 : (1.0 - _slideT.value);
    } else {
      // Already-settled cards stay fully peeked; new ones slide out (0 → 1).
      t = index < _settledExtra ? 1.0 : _slideT.value;
    }

    return Column(
      children: [
        SizedBox(height: peek * t),
        PlayingCard(
          playingCardModel: face,
          isSelected: false,
          width: cardWidth - 2,
        ),
      ],
    );
  }
}
