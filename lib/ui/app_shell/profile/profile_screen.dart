import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  double _collapse = 0;

  static const _collapseRange = 160.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final next = (_scrollController.offset / _collapseRange).clamp(0.0, 1.0);
    if ((next - _collapse).abs() > 0.01) {
      setState(() => _collapse = next);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final screenHeight = MediaQuery.of(context).size.height;
    final showTopCurrency = _collapse > 0.55;
    final avatarSize = 160.0 - (80.0 * _collapse);
    final pencilSize = 44.0 - (20.0 * _collapse);
    final hintOpacity = (1.0 - _collapse * 1.5).clamp(0.0, 1.0);
    final headerCurrencyOpacity = (1.0 - _collapse * 1.6).clamp(0.0, 1.0);
    // Push avatar + name toward vertical center; shrinks away on scroll.
    final topInset =
        (screenHeight * 0.14) * (1.0 - _collapse) + (showTopCurrency ? 36 : 8);

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              SizedBox(height: topInset),
              GestureDetector(
                onTap: () => _changeName(context, vm),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Icon(
                          CupertinoIcons.profile_circled,
                          size: avatarSize,
                          color: theme.muted,
                        ),
                        Icon(
                          CupertinoIcons.pencil_circle,
                          size: pencilSize,
                          color: theme.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNameSelectionButton(vm),
                  ],
                ),
              ),
              SizedBox(height: 20 + (screenHeight * 0.04) * (1.0 - _collapse)),
              Opacity(
                opacity: headerCurrencyOpacity,
                child: IgnorePointer(
                  ignoring: headerCurrencyOpacity < 0.2,
                  child: const Center(child: CurrencyBar(compact: false)),
                ),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: hintOpacity,
                child: Text(
                  l10n.scrollForSettings,
                  textAlign: TextAlign.center,
                  style: theme.mutedText,
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.settings, style: theme.title.copyWith(fontSize: 22)),
              const SizedBox(height: 12),
              const ProfileSettingsBody(),
            ],
          ),
          if (showTopCurrency)
            const Positioned(
              top: 8,
              right: 16,
              child: CurrencyBar(),
            ),
        ],
      ),
    );
  }
}

Widget _buildNameSelectionButton(ProfileViewModel vm) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: AppStyle.theme.raisedSurfaceBox(),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.person, size: 30, color: AppStyle.theme.border),
        const SizedBox(width: 10),
        Text(
          vm.player?.name ?? '',
          style: AppStyle.theme.body.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Icon(CupertinoIcons.pencil, size: 26, color: AppStyle.theme.muted),
      ],
    ),
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
