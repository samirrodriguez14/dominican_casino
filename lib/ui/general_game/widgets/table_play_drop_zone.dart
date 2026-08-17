import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Table-wide drop target for [PlayCardAction] only (not Take / Pair / Add).
class TablePlayDropZone extends StatelessWidget {
  const TablePlayDropZone({super.key, required this.child});

  final Widget child;

  static const Size _feedbackSize = Size(100, 140);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final dragging = vm.draggingHandCard;
    final showHint = dragging != null && vm.canDropPlay(dragging);

    return DragTarget<PlayingCardModel>(
      onWillAcceptWithDetails: (details) => vm.canDropPlay(details.data),
      onAcceptWithDetails: (details) {
        final center = details.offset.translate(
          _feedbackSize.width / 2,
          _feedbackSize.height / 2,
        );
        vm.playCardViaDrop(details.data, center);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final highlight = showHint || hovering;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Fill the table area so game layouts keep their own centering
            // (Tres y Dos Stack, Casino SlidingCardLayout rows).
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: highlight ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppStyle.theme.turnHighlight.withValues(
                        alpha: hovering ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppStyle.theme.radius,
                      ),
                      border: Border.all(
                        color: AppStyle.theme.turnHighlight.withValues(
                          alpha: hovering ? 0.55 : 0.28,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: showHint ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        child: Text(
                          'Drop here to play',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppStyle.theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: AppStyle.theme.suitBlack.withValues(
                                  alpha: 0.65,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
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
}
