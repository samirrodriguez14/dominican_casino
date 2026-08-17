import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Shared privacy body used by Settings and the home Privacy card.
class PrivacyPolicyCopy extends StatelessWidget {
  const PrivacyPolicyCopy({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final body = theme.body.copyWith(fontSize: compact ? 14 : 16, height: 1.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.noRealMoney, style: body),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'We collect a Firebase Authentication identifier (anonymous until you '
          'connect Google), your display name, game match data you create or join, '
          'and — only if you allow notifications — a push token stored under '
          'your user profile (not on shared game documents). If you connect '
          'Google, we also receive your Google name and email from that sign-in.',
          style: body,
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          'Data is processed with Firebase (Google) for realtime play and '
          'turn alerts. We do not sell personal data. You can clear local '
          'profile data from Settings.',
          style: body,
        ),
        SizedBox(height: compact ? 10 : 12),
        Text('Contact: support@dominican-casino.web.app', style: body),
        SizedBox(height: compact ? 16 : 24),
        Text(
          'Public URL for App Store Connect: '
          'https://dominican-casino.web.app/privacy',
          style: body.copyWith(fontSize: compact ? 11 : 12),
        ),
      ],
    );
  }
}
