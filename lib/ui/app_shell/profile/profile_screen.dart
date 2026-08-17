import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/avatar_picker_popup.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_wallet_cards.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late final PageController _pageController;
  double _page = 0;

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
    final vm = context.watch<ProfileViewModel>();
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
          padding: EdgeInsets.fromLTRB(16, topBar, 16, _tabBarClearance),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: SoundService.wrapTap(
                                () => _changeAvatar(context, vm),
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  PlayerAvatarView(
                                    avatarId: vm.player?.avatarId,
                                    size: 168,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.surface,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.pencil_circle_fill,
                                      size: 40,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: SoundService.wrapTap(
                                () => _changeName(context, vm),
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: _buildNameSelectionButton(vm),
                            ),
                            const SizedBox(height: 28),
                            const ProfileWalletCards(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Opacity(
                opacity: profileHintOpacity,
                child: GestureDetector(
                  onTap: profileHintOpacity > 0.2
                      ? SoundService.wrapTap(_goToSettings)
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                  onTap: settingsHintOpacity > 0.2
                      ? SoundService.wrapTap(goToInitial)
                      : null,
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

Widget _buildNameSelectionButton(ProfileViewModel vm) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        vm.player?.name ?? '',
        style: AppStyle.theme.title.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 8),
      Icon(CupertinoIcons.pencil, size: 20, color: AppStyle.theme.muted),
    ],
  );
}

Future<void> _changeAvatar(BuildContext context, ProfileViewModel vm) async {
  final picked = await showAvatarPickerPopup(
    context,
    selectedId: vm.player?.avatarId,
  );
  if (picked == null || picked == vm.player?.avatarId) return;
  await vm.updatePlayerAvatar(picked);
}

Future<void> _changeName(BuildContext context, ProfileViewModel vm) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: vm.player?.name);

  try {
    final newName =
        await showCupertinoDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return _showCupertinoDialog(context, controller, l10n);
          },
        ) ??
        vm.player?.name ??
        '';

    if (newName.isNotEmpty && newName != vm.player?.name) {
      await vm.updatePlayerName(newName);
    }
  } finally {
    controller.dispose();
  }
}

CupertinoAlertDialog _showCupertinoDialog(
  BuildContext context,
  TextEditingController controller,
  AppLocalizations l10n,
) {
  return CupertinoAlertDialog(
    title: Text(l10n.editName),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CupertinoTextField(
        controller: controller,
        maxLength: 10,
        placeholder: l10n.enterYourName,
        autofocus: true,
      ),
    ),
    actions: [
      CupertinoDialogAction(
        child: Text(l10n.cancel, style: AppStyle.theme.mutedText),
        onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text(l10n.save, style: AppStyle.theme.title),
        onPressed: SoundService.wrapTap(() {
          Navigator.pop(context, controller.text.trim());
        }),
      ),
    ],
  );
}
