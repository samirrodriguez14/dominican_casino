import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Action hint while hovering a table card or stack during a board drag.
class TablePlayDropZone extends StatelessWidget {
  const TablePlayDropZone({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final hover = vm.dropHover;
    final showTargetHint =
        vm.isBoardDragging &&
        hover != null &&
        hover.actions.isNotEmpty &&
        !hover.isEmptyTablePlay;
    final label = hover?.hintLabel ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: child),
        if (showTargetHint)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppStyle.theme.suitBlack.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      hover.buildPreview?.label ?? label,
                      style: TextStyle(
                        color: AppStyle.theme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
