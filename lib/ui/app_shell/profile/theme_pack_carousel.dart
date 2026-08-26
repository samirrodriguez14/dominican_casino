import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/profile/theme_pack_card.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ThemePackCarousel extends StatefulWidget {
  const ThemePackCarousel({
    super.key,
    this.initialIndex = 0,
    this.grid = false,
  });

  final int initialIndex;
  final bool grid;

  @override
  State<ThemePackCarousel> createState() => _ThemePackCarouselState();
}

class _ThemePackCarouselState extends State<ThemePackCarousel> {
  late int _frontIndex;

  @override
  void initState() {
    super.initState();
    _frontIndex = widget.initialIndex;
  }

  List<ThemePack> _packs(AppRepo repo) =>
      visibleThemePacksForProfile(repo.ownedPacks);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final packs = _packs(repo);
    final safeFront = _frontIndex.clamp(0, packs.isEmpty ? 0 : packs.length - 1);
    if (safeFront != _frontIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _frontIndex = safeFront);
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.grid
          ? _ThemePackGrid(key: const ValueKey('grid'), packs: packs)
          : StackedCardCarousel(
              key: ValueKey('stack-${packs.length}'),
              itemCount: packs.length,
              initialIndex: safeFront,
              peekStyle: CardPeekStyle.fan,
              animateBackIn: true,
              wrap: false,
              widthFactor: 0.70,
              maxCardWidth: 280,
              onIndexChanged: (index) {
                if (_frontIndex != index) {
                  setState(() => _frontIndex = index);
                }
              },
              itemBuilder: (context, index) {
                return ThemePackCard(
                  pack: packs[index],
                  compact: false,
                  showActions: index == safeFront,
                );
              },
            ),
    );
  }
}

class _ThemePackGrid extends StatelessWidget {
  const _ThemePackGrid({super.key, required this.packs});

  final List<ThemePack> packs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 188),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5 / 3.5,
      ),
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final pack = packs[index];
        return GestureDetector(
          onTap: SoundService.wrapTap(() => handleThemePackTap(context, pack)),
          child: ThemePackCard(
            pack: pack,
            compact: true,
            showActions: false,
          ),
        );
      },
    );
  }
}
