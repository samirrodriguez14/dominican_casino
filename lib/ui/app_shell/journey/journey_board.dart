import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_active_stage.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_defeated_row.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_world_piles.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Three-band Journey board: piles / active stage / defeated.
class JourneyBoard extends StatefulWidget {
  const JourneyBoard({super.key, this.onWorldThemeEquipped});

  final ValueChanged<JourneyWorld>? onWorldThemeEquipped;

  @override
  State<JourneyBoard> createState() => JourneyBoardState();
}

class JourneyBoardState extends State<JourneyBoard>
    with SingleTickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 400);

  final _snapshot = journeyBoardSnapshot;
  JourneyWorld _activeWorld = JourneyWorld.diamonds;
  JourneyCardDef? _selected;
  late final AnimationController _selectAnim;

  @override
  void initState() {
    super.initState();
    _selectAnim = AnimationController(vsync: this, duration: _flipDuration);
  }

  @override
  void dispose() {
    _selectAnim.dispose();
    super.dispose();
  }

  JourneyWorld get activeWorld => _activeWorld;

  Future<void> equipActiveWorldTheme() async {
    await _equipWorld(_activeWorld);
  }

  Future<void> _equipWorld(JourneyWorld world) async {
    final repo = context.read<AppRepo>();
    await repo.unlockAndEquipPack(world.themeId);
    widget.onWorldThemeEquipped?.call(world);
  }

  Future<void> _onWorldTap(JourneyWorld world) async {
    final def = _snapshot.worldOf(world);
    SoundService.instance.playLayered(GameSound.softCard);
    if (!def.unlocked) {
      AppHaptics.selectionClick();
      return;
    }
    AppHaptics.lightImpact();
    setState(() {
      _activeWorld = world;
      if (_selected != null && _selected!.world != world) {
        _selected = null;
        _selectAnim.value = 0;
      }
    });
    await _equipWorld(world);
  }

  Future<void> _onTopCardTap(JourneyCardDef card) async {
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || !card.isSelectable) {
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.selectionClick();
      return;
    }

    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    if (_selected?.world == card.world && _selected?.rank == card.rank) {
      await _selectAnim.reverse();
      if (!mounted) return;
      setState(() => _selected = null);
      return;
    }

    setState(() {
      _activeWorld = card.world;
      _selected = card;
    });
    await _equipWorld(card.world);
    if (!mounted) return;
    await _selectAnim.forward(from: 0);
  }

  void _onChallenge() {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();
  }

  Future<void> _onDismissSelected() async {
    if (_selected == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    await _selectAnim.reverse();
    if (!mounted) return;
    setState(() => _selected = null);
  }

  void _onDefeatedTap(JourneyCardDef card) {
    _onTopCardTap(card);
  }

  @override
  Widget build(BuildContext context) {
    final worldDef = _snapshot.worldOf(_activeWorld);
    final hasAvailable = worldDef.nextSelectable != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(
            flex: 22,
            child: JourneyWorldPiles(
              snapshot: _snapshot,
              activeWorld: _activeWorld,
              selectedCard: _selected,
              onWorldTap: _onWorldTap,
              onTopCardTap: _onTopCardTap,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 52,
            child: AnimatedBuilder(
              animation: _selectAnim,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_selectAnim.value);
                return Opacity(
                  opacity: _selected == null ? 1 : (0.35 + 0.65 * t),
                  child: Transform.scale(
                    scale: _selected == null ? 1 : (0.92 + 0.08 * t),
                    child: JourneyActiveStage(
                      selected: _selected,
                      hasAvailableChallenger: hasAvailable,
                      onChallenge: _onChallenge,
                      onDismiss: _onDismissSelected,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 26,
            child: JourneyDefeatedRow(
              snapshot: _snapshot,
              onDefeatedTap: _onDefeatedTap,
            ),
          ),
        ],
      ),
    );
  }
}
