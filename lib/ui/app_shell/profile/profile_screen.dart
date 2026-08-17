import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final hintOpacity = (1.0 - _page).clamp(0.0, 1.0);
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
                child: GestureDetector(
                  onTap: () => _changeName(context, vm),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Icon(
                            CupertinoIcons.profile_circled,
                            size: 200,
                            color: theme.muted,
                          ),
                          Icon(
                            CupertinoIcons.pencil_circle,
                            size: 44,
                            color: theme.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildNameSelectionButton(vm),
                    ],
                  ),
                ),
              ),
              Opacity(
                opacity: hintOpacity,
                child: GestureDetector(
                  onTap: hintOpacity > 0.2 ? _goToSettings : null,
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
          child: const ProfileSettingsBody(),
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

Future<void> _changeName(BuildContext context, ProfileViewModel vm) async {
  final controller = TextEditingController(text: vm.player?.name);

  final newName =
      await showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return _showCupertinoDialog(context, controller);
        },
      ) ??
      vm.player?.name ??
      '';

  if (newName != vm.player?.name) {
    await vm.updatePlayerName(newName);
  }
}

CupertinoAlertDialog _showCupertinoDialog(
  BuildContext context,
  TextEditingController controller,
) {
  return CupertinoAlertDialog(
    title: const Text('Edit name'),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CupertinoTextField(
        controller: controller,
        maxLength: 10,
        placeholder: 'Enter your name',
        autofocus: true,
      ),
    ),
    actions: [
      CupertinoDialogAction(
        child: Text('Cancel', style: AppStyle.theme.mutedText),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text('Save', style: AppStyle.theme.title),
        onPressed: () {
          Navigator.pop(context, controller.text.trim());
        },
      ),
    ],
  );
}
