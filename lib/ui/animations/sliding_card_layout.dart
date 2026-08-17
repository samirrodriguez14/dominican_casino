import 'package:flutter/cupertino.dart';

class SlidingSlot {
  const SlidingSlot({
    required this.key,
    required this.width,
    required this.child,
  });

  final Key key;
  final double width;
  final Widget child;
}

/// Wrap-style layout with per-slot widths so stacks can expand in place.
class SlidingCardLayout extends StatelessWidget {
  const SlidingCardLayout({
    super.key,
    required this.slots,
    required this.itemHeight,
    this.spacing = 10,
    this.runSpacing = 10,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
  });

  final List<SlidingSlot> slots;
  final double itemHeight;
  final double spacing;
  final double runSpacing;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (maxW <= 0 || slots.isEmpty) {
          return SizedBox(height: itemHeight);
        }

        final positions = <Offset>[];
        var x = 0.0;
        var y = 0.0;
        var rowWidth = 0.0;
        final rowStarts = <int>[0];

        for (var i = 0; i < slots.length; i++) {
          final w = slots[i].width;
          if (x > 0 && x + w > maxW) {
            rowStarts.add(i);
            x = 0;
            y += itemHeight + runSpacing;
          }
          positions.add(Offset(x, y));
          x += w + spacing;
          rowWidth = x > rowWidth ? x : rowWidth;
        }

        // Center each row independently.
        final rowEndExclusive = [...rowStarts.skip(1), slots.length];
        for (var r = 0; r < rowStarts.length; r++) {
          final start = rowStarts[r];
          final end = rowEndExclusive[r];
          var used = 0.0;
          for (var i = start; i < end; i++) {
            used += slots[i].width;
            if (i < end - 1) used += spacing;
          }
          final pad = ((maxW - used) / 2).clamp(0.0, maxW);
          for (var i = start; i < end; i++) {
            positions[i] = Offset(positions[i].dx + pad, positions[i].dy);
          }
        }

        final height = y + itemHeight;

        return SizedBox(
          width: maxW,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < slots.length; i++)
                AnimatedPositioned(
                  key: ValueKey('slide_${slots[i].key}'),
                  duration: duration,
                  curve: curve,
                  left: positions[i].dx,
                  top: positions[i].dy,
                  width: slots[i].width,
                  height: itemHeight,
                  child: slots[i].child,
                ),
            ],
          ),
        );
      },
    );
  }
}
