import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/profile/theme_pack_card.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';

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
    _frontIndex = widget.initialIndex.clamp(0, themePackCatalog.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.grid
          ? const _ThemePackGrid(key: ValueKey('grid'))
          : StackedCardCarousel(
              key: const ValueKey('stack'),
              itemCount: themePackCatalog.length,
              initialIndex: _frontIndex,
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
                  pack: themePackCatalog[index],
                  compact: false,
                  showActions: index == _frontIndex,
                );
              },
            ),
    );
  }
}

class _ThemePackGrid extends StatelessWidget {
  const _ThemePackGrid({super.key});

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
      itemCount: themePackCatalog.length,
      itemBuilder: (context, index) {
        final pack = themePackCatalog[index];
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
