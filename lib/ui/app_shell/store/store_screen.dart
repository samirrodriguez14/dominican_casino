import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/app_shell/settings/theme_option.dart';
import 'package:flutter/cupertino.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final storeThemes = Theme.values
        .where((t) => !ownedThemes.contains(t))
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, shellTopBarHeight(context) + 8, 16, 110),
      children: [
        Text(l10n.store, style: theme.title.copyWith(fontSize: 32)),
        const SizedBox(height: 8),
        Text(l10n.noRealMoney, style: theme.body),
        const SizedBox(height: 24),
        Text(l10n.themes, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: storeThemes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final themeType = storeThemes[index];
            return ThemeOptionCard(
              themeType: themeType,
              previewTheme: themeFromEnum(themeType),
              selected: false,
              locked: true,
              badgeLabel: l10n.comingSoon,
              onTap: null,
            );
          },
        ),
        const SizedBox(height: 28),
        Text(l10n.buyEnergy, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        _ComingSoonCard(
          icon: CupertinoIcons.bolt_fill,
          title: l10n.buyEnergy,
          subtitle: l10n.comingSoon,
        ),
        const SizedBox(height: 20),
        Text(l10n.buyCoins, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        _ComingSoonCard(
          icon: CupertinoIcons.circle_grid_3x3_fill,
          title: l10n.buyCoins,
          subtitle: l10n.comingSoon,
        ),
      ],
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: theme.surfaceBox(),
      child: Row(
        children: [
          Icon(icon, color: theme.muted, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.body),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.mutedText),
              ],
            ),
          ),
          Icon(CupertinoIcons.lock_fill, color: theme.muted, size: 18),
        ],
      ),
    );
  }
}
