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
  int _frontIndex = 0;

  void toggleProfileSettings() {
    if (_looksMode) {
      setState(() {
        _looksMode = false;
        _looksGrid = false;
      });
      return;
    }
    _carouselKey.currentState?.toggleFront();
  }

  void _toggleLooks() {
    if (_looksMode) {
      setState(() {
        _looksMode = false;
        _looksGrid = false;
      });
      return;
    }
    final repo = context.read<AppRepo>();
    final current = repo.appTheme;
    final packs = visibleThemePacksForProfile(repo.ownedPacks);
    final index = packs.indexWhere((pack) => pack.id == current);
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
            _looksMode ? 0 : 108,
          ),
          child: _looksMode
              ? ThemePackCarousel(
                  key: ValueKey(_looksIndex),
                  initialIndex: _looksIndex,
                  grid: _looksGrid,
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
                        ? ProfileCard(onToggleLooks: _toggleLooks)
                        : const ProfileSettingsBody();
                  },
                  onIndexChanged: (index) {
                    if (_frontIndex == index) return;
                    setState(() => _frontIndex = index);
                  },
                ),
        ),
        Positioned(
          left: 0,
          right: 0,
          // Lift the slide hint above the floating tab bar.
          bottom: 124,
          child: Center(
            child: _looksMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          semanticLabel: _looksGrid
                              ? 'Stacked view'
                              : 'Grid view',
                        ),
                      ),
                      const SizedBox(width: 20),
                      CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                        onPressed: SoundService.wrapTap(_toggleLooks),
                        child: Icon(
                          CupertinoIcons.check_mark,
                          size: 22,
                          color: theme.textPrimary,
                          semanticLabel: l10n.done,
                        ),
                      ),
                    ],
                  )
                : _SlideHint(
                    text: _frontIndex == 0
                        ? l10n.slideForSettings
                        : l10n.slideForProfile,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SlideHint extends StatefulWidget {
  const _SlideHint({required this.text});

  final String text;

  @override
  State<_SlideHint> createState() => _SlideHintState();
}

class _SlideHintState extends State<_SlideHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
        return Opacity(opacity: 0.35 + 0.65 * _pulse.value, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            widget.text,
            key: ValueKey(widget.text),
            textAlign: TextAlign.center,
            style: theme.mutedText.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
