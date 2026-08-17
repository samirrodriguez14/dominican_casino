import 'package:flutter/cupertino.dart';

/// Owns a single bounce ticker for every [CardCoinHint] under [child].
///
/// Without this, each coin hint ran its own forever-repeating controller.
class CoinHintTickerScope extends StatefulWidget {
  const CoinHintTickerScope({super.key, required this.child});

  final Widget child;

  /// Shared bounce controller, or null outside a [CoinHintTickerScope].
  static AnimationController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_CoinHintTicker>()
        ?.controller;
  }

  @override
  State<CoinHintTickerScope> createState() => _CoinHintTickerScopeState();
}

class _CoinHintTickerScopeState extends State<CoinHintTickerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CoinHintTicker(controller: _controller, child: widget.child);
  }
}

class _CoinHintTicker extends InheritedWidget {
  const _CoinHintTicker({required this.controller, required super.child});

  final AnimationController controller;

  @override
  bool updateShouldNotify(_CoinHintTicker oldWidget) =>
      controller != oldWidget.controller;
}
