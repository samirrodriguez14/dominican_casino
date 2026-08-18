import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_card.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late final PageController _pageController;
  double _page = 0;
  int _settledPage = 0;
  bool _playedSlideSound = false;

  static const _tabBarClearance = 110.0;
  static const _pageDuration = Duration(milliseconds: 320);
  static const _pageCurve = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPage);
  }

  void _onPage() {
    if (!_pageController.hasClients) return;
    final next = _pageController.page ?? 0;
    if ((next - _page).abs() > 0.01) {
      setState(() => _page = next);
    }
    if (!_playedSlideSound) {
      if (_settledPage == 0 && next > 0.08) {
        _playedSlideSound = true;
        SoundService.instance.playLayered(GameSound.softCard);
      } else if (_settledPage == 1 && next < 0.92) {
        _playedSlideSound = true;
        SoundService.instance.playLayered(GameSound.softCard);
      }
    }
    final rounded = next.round().clamp(0, 1);
    if ((next - rounded).abs() < 0.02) {
      _settledPage = rounded;
      _playedSlideSound = false;
    }
  }

  void goToInitial() {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      0,
      duration: _pageDuration,
      curve: _pageCurve,
    );
  }

  void _goToSettings() {
    _pageController.animateToPage(
      1,
      duration: _pageDuration,
      curve: _pageCurve,
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPage);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final profileHintOpacity = (1.0 - _page).clamp(0.0, 1.0);
    final settingsHintOpacity = _page.clamp(0.0, 1.0);
    final topBar = shellTopBarHeight(context);

    return PageView(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, topBar, 12, _tabBarClearance),
          child: Column(
            children: [
              const Expanded(child: ProfileCard()),
              Opacity(
                opacity: profileHintOpacity,
                child: GestureDetector(
                  onTap: profileHintOpacity > 0.2 ? _goToSettings : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 18,
                          color: theme.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.scrollForSettings,
                          textAlign: TextAlign.center,
                          style: theme.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, topBar, 12, _tabBarClearance),
          child: Column(
            children: [
              Opacity(
                opacity: settingsHintOpacity,
                child: GestureDetector(
                  onTap: settingsHintOpacity > 0.2 ? goToInitial : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.chevron_up,
                          size: 18,
                          color: theme.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.scrollForProfile,
                          textAlign: TextAlign.center,
                          style: theme.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(child: ProfileSettingsBody()),
            ],
          ),
        ),
      ],
    );
  }
}
