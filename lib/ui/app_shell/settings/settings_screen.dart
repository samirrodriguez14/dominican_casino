import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/theme_option.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AppThemeViewModel>();
    final appRepo = context.watch<AppRepo>();
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            l10n.chooseTable,
            style: AppStyle.theme.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(l10n.noRealMoney, style: AppStyle.theme.body),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: Theme.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final themeType = Theme.values[index];
              final previewTheme = themeFromEnum(themeType);
              final selected = vm.appTheme == themeType;

              return ThemeOptionCard(
                themeType: themeType,
                previewTheme: previewTheme,
                selected: selected,
                onTap: () => vm.selectTheme(themeType),
              );
            },
          ),
          const SizedBox(height: 28),
          Text(l10n.language, style: AppStyle.theme.title),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: appRepo.locale.languageCode == 'es'
                      ? AppStyle.theme.border
                      : AppStyle.theme.surface,
                  onPressed: () => appRepo.setLocale(const Locale('es')),
                  child: const Text('Español'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: appRepo.locale.languageCode == 'en'
                      ? AppStyle.theme.border
                      : AppStyle.theme.surface,
                  onPressed: () => appRepo.setLocale(const Locale('en')),
                  child: const Text('English'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            color: AppStyle.theme.surface,
            onPressed: () => _requestNotifications(context, appRepo, l10n),
            child: Text(l10n.enableNotifications),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: () => context.push('/privacy'),
            child: Text(l10n.privacyPolicy),
          ),
          CupertinoButton(
            onPressed: () => _confirmDelete(context, appRepo, l10n),
            child: Text(
              l10n.deleteAccount,
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotifications(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.enableNotifications),
        content: Text(l10n.notificationsRationale),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notNow),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.enableNotifications),
          ),
        ],
      ),
    );
    if (go == true) await appRepo.enableNotifications();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (go == true) {
      await appRepo.deleteLocalAccount();
      if (context.mounted) context.go('/home');
    }
  }
}
