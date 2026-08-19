import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://dominican-casino.web.app/privacy';

Future<void> openPrivacyPolicy(BuildContext context) async {
  final uri = Uri.parse(privacyPolicyUrl);
  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      await _showPrivacyLinkFallback(context);
    }
  } on PlatformException {
    if (context.mounted) {
      await _showPrivacyLinkFallback(context);
    }
  } catch (_) {
    if (context.mounted) {
      await _showPrivacyLinkFallback(context);
    }
  }
}

Future<void> _showPrivacyLinkFallback(BuildContext context) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Open privacy policy'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          privacyPolicyUrl,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: privacyPolicyUrl));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Copy link'),
        ),
      ],
    ),
  );
}
