import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

/// Short-press drag that drives [GeneralGameViewModel] board drop resolve.
class BoardDragHandle extends StatefulWidget {
  const BoardDragHandle({
    super.key,
    required this.source,
    required this.child,
    this.enabled = true,
    this.feedbackWidth = 60,
    /// Size used while the pointer is over the table (hand cards shrink to this).
    this.tableFeedbackWidth = 60,
    this.onTap,
    /// When true (hand fan), reorder while dragging over the fan.
    this.onHandReorder,
  });

  final BoardDragSource source;
  final Widget child;
  final bool enabled;
  final double feedbackWidth;
  final double tableFeedbackWidth;
  final VoidCallback? onTap;
  final void Function(Offset global)? onHandReorder;

  @override
  State<BoardDragHandle> createState() => _BoardDragHandleState();
}

class _BoardDragHandleState extends State<BoardDragHandle> {
  static const _armDelay = Duration(milliseconds: 120);

  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();

  Timer? _armTimer;
  int? _pointer;
  Offset? _pressGlobal;
  bool _dragging = false;
  Offset _dragGlobal = Offset.zero;
  Offset _dragStartGlobal = Offset.zero;
  FlightLayerController? _flightLayer;
  FlightSprite? _dragSprite;
  final ValueNotifier<int> _dragTick = ValueNotifier<int>(0);
  bool _globalRouteAdded = false;

  /// 0 = hand/source size, 1 = table size (and optionally merged into target).
  double _tableBlend = 0;

  @override
  void dispose() {
    _armTimer?.cancel();
    _removeGlobalRoute();
    _teardownSprite();
    _dragTick.dispose();
    super.dispose();
  }

  void _teardownSprite() {
    final sprite = _dragSprite;
    _dragSprite = null;
    final layer = _flightLayer;
    if (sprite != null && layer != null) layer.detach(sprite);
  }

  void _addGlobalRoute() {
    if (_globalRouteAdded) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
    _globalRouteAdded = true;
  }

  void _removeGlobalRoute() {
    if (!_globalRouteAdded) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
    _globalRouteAdded = false;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!widget.enabled || vm.isAnimating || vm.hasDropPending) return;
    _armTimer?.cancel();
    _pointer = e.pointer;
    _pressGlobal = e.position;
    _armTimer = Timer(_armDelay, () {
      if (!mounted || _pointer == null) return;
      _beginDrag(_pressGlobal ?? e.position);
    });
    _addGlobalRoute();
  }

  void _onGlobalPointer(PointerEvent event) {
    if (event.pointer != _pointer) return;

    if (event is PointerMoveEvent) {
      _pressGlobal = event.position;
      if (_dragging) _onDragMove(event.position);
      return;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      final pos = event.position;
      final wasDragging = _dragging;
      _armTimer?.cancel();
      _armTimer = null;
      _pointer = null;
      _removeGlobalRoute();

      if (wasDragging) {
        _endDrag(pos);
      } else if (event is PointerUpEvent) {
        widget.onTap?.call();
        _pressGlobal = null;
      } else {
        _pressGlobal = null;
      }
    }
  }

  void _beginDrag(Offset global) {
    if (_dragging || vm.isAnimating || vm.hasDropPending) return;
    _dragging = true;
    _dragGlobal = global;
    _dragStartGlobal = global;
    _tableBlend = 0;
    vm.beginBoardDrag(widget.source);
    AppHaptics.selectionClick();

    _teardownSprite();
    _flightLayer = FlightLayerScope.maybeOf(context);
    final layer = _flightLayer;
    if (layer != null) {
      _dragSprite = FlightSprite(
        listenable: _dragTick,
        builder: (_) => _buildSprite(layer),
      );
      layer.attach(_dragSprite!);
    }
  }

  void _onDragMove(Offset global) {
    _dragGlobal = global;
    final overTable = vm.hitTestDropTarget(global) != null;
    final target = overTable ? 1.0 : 0.0;
    _tableBlend = lerpDouble(_tableBlend, target, 0.35) ?? target;
    if ((_tableBlend - target).abs() < 0.02) _tableBlend = target;
    _dragTick.value++;
    vm.updateDropHover(global);
    widget.onHandReorder?.call(global);
  }

  Future<void> _endDrag(Offset global) async {
    _teardownSprite();
    _dragging = false;
    _pressGlobal = null;
    _tableBlend = 0;

    final accepted = await vm.finishBoardDrop(global);
    if (!accepted && (global - _dragStartGlobal).distance < 14) {
      widget.onTap?.call();
    }
  }

  Widget _buildSprite(FlightLayerController layer) {
    final local = layer.toLocal(_dragGlobal);
    if (local == null) return const SizedBox.shrink();

    final w = lerpDouble(
          widget.feedbackWidth,
          widget.tableFeedbackWidth,
          _tableBlend,
        ) ??
        widget.feedbackWidth;
    final h = w * 1.4;

    // When the target shows a merge preview, hide the ghost so the card
    // reads as the same piece sitting in the stack — not a duplicate.
    final merging = vm.dropHover?.buildPreview != null;
    final opacity = merging ? 0.0 : 1.0;

    Widget face;
    switch (widget.source.kind) {
      case BoardDragKind.handCard:
      case BoardDragKind.tableCard:
        face = PlayingCard(
          playingCardModel: widget.source.card!,
          width: w,
          isSelected: true,
        );
      case BoardDragKind.tableStack:
        final stack = widget.source.stack!;
        face = _StackDragFace(stack: stack, width: w);
    }

    return Positioned(
      left: local.dx - w / 2,
      top: local.dy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(opacity: opacity, child: face),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      child: widget.child,
    );
  }
}

class _StackDragFace extends StatelessWidget {
  const _StackDragFace({required this.stack, required this.width});

  final PlayingAreaStackModel stack;
  final double width;

  @override
  Widget build(BuildContext context) {
    final top = stack.cards.isNotEmpty ? stack.cards.last : null;
    if (top == null) return SizedBox(width: width, height: width * 1.4);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PlayingCard(playingCardModel: top, width: width, isSelected: true),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xF216120F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stack.stackValue}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF3ECE2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
