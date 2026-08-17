import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
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

class SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppRepo>().refreshNotificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppRepo>().refreshNotificationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AppThemeViewModel>();
    final appRepo = context.watch<AppRepo>();
    final sounds = context.watch<SoundService>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            l10n.chooseTable,
            style: theme.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(l10n.noRealMoney, style: theme.body),
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
          Text(l10n.language, style: theme.title),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LanguageButton(
                  label: 'Español',
                  selected: appRepo.locale.languageCode == 'es',
                  onPressed: () => appRepo.setLocale(const Locale('es')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageButton(
                  label: 'English',
                  selected: appRepo.locale.languageCode == 'en',
                  onPressed: () => appRepo.setLocale(const Locale('en')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(l10n.sound, style: theme.title),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            label: l10n.soundEffects,
            value: sounds.sfxEnabled,
            onChanged: sounds.setSfxEnabled,
          ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            label: l10n.backgroundMusic,
            value: sounds.musicEnabled,
            onChanged: sounds.setMusicEnabled,
          ),
          const SizedBox(height: 28),
          Text(l10n.notifications, style: theme.title),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: theme.surfaceBox(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.notifications, style: theme.body),
                      const SizedBox(height: 4),
                      Text(
                        appRepo.notificationsEnabled
                            ? l10n.notificationsOn
                            : l10n.notificationsOff,
                        style: theme.mutedText.copyWith(
                          color: appRepo.notificationsEnabled
                              ? theme.success
                              : theme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!appRepo.notificationsEnabled)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: theme.surfaceAlt,
                    onPressed: () =>
                        _requestNotifications(context, appRepo, l10n),
                    child: Text(
                      l10n.enableNotifications,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: selected ? theme.surfaceAlt : theme.surface,
      borderRadius: BorderRadius.circular(theme.radius),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? theme.textPrimary : theme.muted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: theme.surfaceBox(),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.body)),
          CupertinoSwitch(
            value: value,
            activeTrackColor: theme.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
