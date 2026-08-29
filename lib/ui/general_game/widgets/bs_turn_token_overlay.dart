import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Floating turn chip that slides between seat avatars when the turn changes.
///
/// One persistent widget — position animates; it is not recreated per seat.
class BsTurnTokenOverlay extends StatefulWidget {
  const BsTurnTokenOverlay({super.key, required this.stackKey});

  final GlobalKey stackKey;

  @override
  State<BsTurnTokenOverlay> createState() => _BsTurnTokenOverlayState();
}

class _BsTurnTokenOverlayState extends State<BsTurnTokenOverlay>
    with SingleTickerProviderStateMixin {
  static const _tokenSize = 22.0;
  static const _moveDuration = Duration(milliseconds: 420);

  late final AnimationController _move;
  Offset? _from;
  Offset? _to;
  String? _pid;
  bool _settled = true;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this, duration: _moveDuration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _from = _to;
          _settled = true;
          setState(() {});
        }
      });
    _scheduleSync();
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      _sync();
    });
  }

  Offset? _anchorFor(String pid, GeneralGameViewModel vm) {
    final key = pid == vm.me
        ? vm.scoreKey
        : vm.celebrationAvatarKeyForPid(pid);
    final seatBox = key.currentContext?.findRenderObject() as RenderBox?;
    final stackBox =
        widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (seatBox == null ||
        stackBox == null ||
        !seatBox.hasSize ||
        !stackBox.hasSize) {
      return null;
    }
    // Top-right of the seat widget, nudged so the chip sits on the rim.
    final global = seatBox.localToGlobal(
      Offset(seatBox.size.width - 2, 2),
    );
    final local = stackBox.globalToLocal(global);
    return local - const Offset(_tokenSize * 0.55, _tokenSize * 0.35);
  }

  void _sync() {
    if (!mounted) return;
    final vm = context.read<GeneralGameViewModel>();
    if (!vm.isLiveTurn) {
      if (_pid != null || _to != null) {
        setState(() {
          _pid = null;
          _from = null;
          _to = null;
          _settled = true;
        });
      }
      return;
    }
    final pid = vm.gameState.currentTurnPlayerId;
    if (pid == null || pid.isEmpty) return;

    final target = _anchorFor(pid, vm);
    if (target == null) {
      _scheduleSync();
      return;
    }

    if (_pid == null || _to == null) {
      setState(() {
        _pid = pid;
        _from = target;
        _to = target;
        _settled = true;
      });
      return;
    }

    if (pid == _pid) {
      // Layout can shift; keep the chip glued without replaying the flight.
      if (_settled && (_to! - target).distance > 1.5) {
        setState(() {
          _from = target;
          _to = target;
        });
      }
      return;
    }

    final start = _settled ? _to! : _currentPos();
    setState(() {
      _pid = pid;
      _from = start;
      _to = target;
      _settled = false;
    });
    _move
      ..duration = _moveDuration
      ..forward(from: 0);
  }

  Offset _currentPos() {
    final a = _from ?? Offset.zero;
    final b = _to ?? a;
    if (_settled) return b;
    final t = Curves.easeInOutCubic.transform(_move.value);
    return Offset.lerp(a, b, t)!;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GeneralGameViewModel>();
    _scheduleSync();

    if (_to == null) {
      return const SizedBox.shrink();
    }

    final pos = _currentPos();
    final gold = AppStyle.theme.turnHighlight;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: pos.dx,
            top: pos.dy,
            child: _TurnTokenChip(color: gold, size: _tokenSize),
          ),
        ],
      ),
    );
  }
}

class _TurnTokenChip extends StatefulWidget {
  const _TurnTokenChip({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_TurnTokenChip> createState() => _TurnTokenChipState();
}

class _TurnTokenChipState extends State<_TurnTokenChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Transform.scale(
          scale: 0.94 + t * 0.08,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(widget.color, CupertinoColors.white, 0.35)!,
                  widget.color,
                ],
              ),
              border: Border.all(color: theme.background, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35 + t * 0.35),
                  blurRadius: 6 + t * 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.flame_fill,
              size: widget.size * 0.55,
              color: theme.background.withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}
