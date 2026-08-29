import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Where the bubble tip points (toward the speaker).
enum ReactionBubbleTail { left, right, top, bottom }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 40, height: 1)),
    );

    return _BubbleShell(tail: tail, fill: fill, stroke: stroke, child: body);
  }
}

/// Large text callout for BS claims / Call Bluff. Coexists with emoji reactions.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.message,
    this.tail = ReactionBubbleTail.right,
    this.emphasized = false,
  });

  final String message;
  final ReactionBubbleTail tail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final fill = emphasized
        ? theme.turnHighlight.withValues(alpha: .95)
        : theme.surface.withValues(alpha: .97);
    final stroke = emphasized
        ? theme.turnHighlight
        : theme.border.withValues(alpha: .55);
    final fg = emphasized ? theme.background : theme.textPrimary;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stroke, width: emphasized ? 1.6 : 1),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.title.copyWith(
            fontSize: emphasized ? 20 : 16,
            fontWeight: FontWeight.w800,
            color: fg,
            height: 1.15,
          ),
        ),
      ),
    );

    return _BubbleShell(tail: tail, fill: fill, stroke: stroke, child: body);
  }
}

class _BubbleShell extends StatelessWidget {
  const _BubbleShell({
    required this.tail,
    required this.fill,
    required this.stroke,
    required this.child,
  });

  final ReactionBubbleTail tail;
  final Color fill;
  final Color stroke;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tail == ReactionBubbleTail.top) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(16, 9),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.top,
            ),
          ),
          child,
        ],
      );
    }

    if (tail == ReactionBubbleTail.bottom) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          CustomPaint(
            size: const Size(16, 9),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.bottom,
            ),
          ),
        ],
      );
    }

    if (tail == ReactionBubbleTail.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(10, 16),
            painter: _BubbleTailPainter(
              fill: fill,
              stroke: stroke,
              direction: ReactionBubbleTail.left,
            ),
          ),
          child,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        CustomPaint(
          size: const Size(10, 16),
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
    switch (direction) {
      case ReactionBubbleTail.top:
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close();
      case ReactionBubbleTail.bottom:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();
      case ReactionBubbleTail.left:
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height)
          ..close();
      case ReactionBubbleTail.right:
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
      ReactionBubbleTail.left => Alignment.centerLeft,
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
      child: emoji == null || emoji!.isEmpty
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : ReactionBubble(
              key: ValueKey(reactionId ?? emoji),
              emoji: emoji!,
              tail: tail,
            ),
    );
  }
}

/// Animated speech callout for BS play / Call Bluff lines.
class SpeechBubblePopup extends StatelessWidget {
  const SpeechBubblePopup({
    super.key,
    required this.message,
    this.messageId,
    this.tail = ReactionBubbleTail.right,
    this.emphasized = false,
  });

  final String? message;
  final String? messageId;
  final ReactionBubbleTail tail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scaleAlignment = switch (tail) {
      ReactionBubbleTail.top => Alignment.topCenter,
      ReactionBubbleTail.bottom => Alignment.bottomCenter,
      ReactionBubbleTail.left => Alignment.centerLeft,
      ReactionBubbleTail.right => Alignment.centerRight,
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            alignment: scaleAlignment,
            child: child,
          ),
        );
      },
      child: message == null || message!.isEmpty
          ? const SizedBox.shrink(key: ValueKey('speech_empty'))
          : SpeechBubble(
              key: ValueKey(messageId ?? message),
              message: message!,
              tail: tail,
              emphasized: emphasized,
            ),
    );
  }
}

class GameReactionPicker extends StatelessWidget {
  const GameReactionPicker({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _cell = 54.0;

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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(22),
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
                            style: const TextStyle(fontSize: 34, height: 1),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: CustomPaint(
            size: const Size(16, 9),
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
