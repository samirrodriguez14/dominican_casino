import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// iPad/Mac share sheets require a source rect or they do nothing.
Rect sharePositionOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && !box.size.isEmpty) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 2,
    height: 2,
  );
}

Future<void> shareGameInvite({
  required BuildContext context,
  required String gameId,
  required String gameMode,
}) async {
  if (!context.mounted) return;
  AppHaptics.mediumImpact();
  final link = GameRoutes.inviteUrl(gameId: gameId, gameMode: gameMode);
  await SharePlus.instance.share(
    ShareParams(
      text: 'Join my Dominican $gameMode game!\n$link',
      sharePositionOrigin: sharePositionOriginOf(context),
    ),
  );
}
