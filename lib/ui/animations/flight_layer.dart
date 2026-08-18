import 'package:flutter/cupertino.dart';

/// Board-local coordinate space for card / shuffle flyers.
///
/// Flyers are [Positioned] children of the same [Stack] as the game UI, and all
/// slot centers are converted with [toLocal] / [centerOf]. That keeps flight
/// endpoints in the same space as the painted cards.
class FlightLayerController extends ChangeNotifier {
  final GlobalKey layerKey = GlobalKey();

  final List<FlightSprite> _sprites = <FlightSprite>[];
  List<FlightSprite> get sprites => _sprites;

  RenderBox? get _layerBox {
    final box = layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box;
  }

  /// Global (screen) point → layer-local point for [Positioned].
  Offset? toLocal(Offset global) {
    final layer = _layerBox;
    if (layer == null) return null;
    return layer.globalToLocal(global);
  }

  /// Center of [key]'s render box, in layer-local coordinates.
  Offset? centerOf(GlobalKey? key) {
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return toLocal(global);
  }

  /// Laid-out width of [key], so flights can land at the real card size.
  double? widthOf(GlobalKey? key) {
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;
    return box.size.width;
  }

  void attach(FlightSprite sprite) {
    _sprites.add(sprite);
    notifyListeners();
  }

  void detach(FlightSprite sprite) {
    if (_sprites.remove(sprite)) notifyListeners();
  }

  void detachAll(Iterable<FlightSprite> sprites) {
    var changed = false;
    for (final s in sprites) {
      changed = _sprites.remove(s) || changed;
    }
    if (changed) notifyListeners();
  }

  /// Rebuild flyer widgets (e.g. after destination centers resolve).
  void poke() => notifyListeners();
}

/// One animated flyer drawn inside [FlightLayer].
class FlightSprite {
  FlightSprite({required this.listenable, required this.builder});

  final Listenable listenable;
  final Widget Function(BuildContext context) builder;
}

class FlightLayerScope extends InheritedWidget {
  const FlightLayerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final FlightLayerController controller;

  static FlightLayerController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlightLayerScope>();
    assert(scope != null, 'FlightLayerScope not found');
    return scope!.controller;
  }

  static FlightLayerController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlightLayerScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(FlightLayerScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Stack host: [child] is the board; sprites paint above it in the same space.
class FlightLayer extends StatelessWidget {
  const FlightLayer({super.key, required this.controller, required this.child});

  final FlightLayerController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FlightLayerScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Stack(
            key: controller.layerKey,
            clipBehavior: Clip.none,
            children: [
              child,
              for (final sprite in controller.sprites)
                ListenableBuilder(
                  listenable: sprite.listenable,
                  builder: (context, _) => sprite.builder(context),
                ),
            ],
          );
        },
      ),
    );
  }
}
