import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

enum ReactionBubbleTail { right, top, bottom }

/// Chat-style emoji bubble. [tail] points at the speaker.
class ReactionBubble extends StatelessWidget {
  const ReactionBubble({
    super.key,
    required this.emoji,
    this.tail = ReactionBubbleTail.right,
  });

  final String emoji;
  final ReactionBubbleTail tail;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final fill = theme.surface.withValues(alpha: .96);
    final stroke = theme.border.withValues(alpha: .5);
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 28, height: 1.1)),
    );

    if (tail == ReactionBubbleTail.top) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(14, 8),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.top,
            ),
          ),
          body,
        ],
      );
    }

    if (tail == ReactionBubbleTail.bottom) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          CustomPaint(
            size: const Size(14, 8),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.bottom,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        CustomPaint(
          size: const Size(8, 14),
          painter: _BubbleTailPainter(
            fill: fill,
            stroke: stroke,
            direction: ReactionBubbleTail.right,
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({
    required this.fill,
    required this.stroke,
    required this.direction,
  });

  final Color fill;
  final Color stroke;
  final ReactionBubbleTail direction;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (direction == ReactionBubbleTail.top) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else if (direction == ReactionBubbleTail.bottom) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      stroke != oldDelegate.stroke ||
      direction != oldDelegate.direction;
}

/// Animated in/out wrapper so a new reaction retriggers the pop.
class ReactionBubblePopup extends StatelessWidget {
  const ReactionBubblePopup({
    super.key,
    required this.emoji,
    this.reactionId,
    this.tail = ReactionBubbleTail.right,
  });

  final String? emoji;
  final String? reactionId;
  final ReactionBubbleTail tail;

  @override
  Widget build(BuildContext context) {
    final scaleAlignment = switch (tail) {
      ReactionBubbleTail.top => Alignment.topCenter,
      ReactionBubbleTail.bottom => Alignment.bottomCenter,
      ReactionBubbleTail.right => Alignment.centerRight,
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.55, end: 1).animate(animation),
            alignment: scaleAlignment,
            child: child,
          ),
        );
      },
      child: emoji == null
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : ReactionBubble(
              key: ValueKey(reactionId ?? emoji),
              emoji: emoji!,
              tail: tail,
            ),
    );
  }
}

class GameReactionPicker extends StatelessWidget {
  const GameReactionPicker({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _cell = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final fill = theme.surface.withValues(alpha: .96);
    final stroke = theme.border.withValues(alpha: .5);
    final emojis = GameReaction.options;
    const cols = GameReaction.columns;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: stroke),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < emojis.length; r += cols)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final emoji in emojis.skip(r).take(cols))
                      SizedBox(
                        width: _cell,
                        height: _cell,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(_cell, _cell),
                          onPressed: SoundService.wrapTap(
                            () => onSelected(emoji),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24, height: 1.1),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 19),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.bottom,
            ),
          ),
        ),
      ],
    );
  }
}
