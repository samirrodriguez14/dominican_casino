import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_card.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/app_shell/profile/theme_pack_carousel.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  bool _looksMode = false;
  bool _looksGrid = false;
  int _looksIndex = 0;

  void goToInitial() {
    if (_looksMode) {
      setState(() {
        _looksMode = false;
        _looksGrid = false;
      });
      return;
    }
    _carouselKey.currentState?.goToIndex(0);
  }

  void _toggleLooks() {
    if (_looksMode) {
      setState(() {
        _looksMode = false;
        _looksGrid = false;
      });
      return;
    }
    final current = context.read<AppRepo>().appTheme;
    final index = themePackCatalog.indexWhere((pack) => pack.id == current);
    setState(() {
      _looksIndex = index < 0 ? 0 : index;
      _looksMode = true;
      _looksGrid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            shellTopBarHeight(context),
            12,
            _looksMode ? 0 : 140,
          ),
          child: _looksMode
              ? ThemePackCarousel(
                  key: ValueKey(_looksIndex),
                  initialIndex: _looksIndex,
                  grid: _looksGrid,
                  onOpenStackedAt: (index) {
                    setState(() {
                      _looksIndex = index;
                      _looksGrid = false;
                    });
                  },
                )
              : StackedCardCarousel(
                  key: _carouselKey,
                  itemCount: 2,
                  peekStyle: CardPeekStyle.stack,
                  animateBackIn: true,
                  widthFactor: homeCardWidthFactor,
                  maxCardWidth: homeCardMaxWidth,
                  fitToHeight: true,
                  itemBuilder: (context, index) {
                    return index == 0
                        ? const ProfileCard()
                        : const ProfileSettingsBody();
                  },
                ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 140,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_looksMode) ...[
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    minimumSize: Size.zero,
                    onPressed: SoundService.wrapTap(() {
                      setState(() => _looksGrid = !_looksGrid);
                    }),
                    child: Icon(
                      _looksGrid
                          ? CupertinoIcons.rectangle_stack
                          : CupertinoIcons.square_grid_2x2,
                      size: 22,
                      color: theme.textPrimary,
                      semanticLabel: _looksGrid ? 'Stacked view' : 'Grid view',
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  onPressed: SoundService.wrapTap(_toggleLooks),
                  child: Icon(
                    _looksMode
                        ? CupertinoIcons.check_mark
                        : CupertinoIcons.paintbrush,
                    size: 22,
                    color: theme.textPrimary,
                    semanticLabel: _looksMode ? l10n.done : l10n.themes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
