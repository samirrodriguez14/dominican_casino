import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_about_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/home/home_login_card.dart';
import 'package:dominican_casino/ui/home/home_privacy_card.dart';
import 'package:dominican_casino/ui/widgets/account_dialogs.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:dominican_casino/view_models/home_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _loginPage = 1;

  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeViewModel>().loadPlayer();
    });
  }

  Future<String?> _askName({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    try {
      return await showCupertinoDialog<String>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.enterYourName),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              maxLength: 10,
              textAlign: TextAlign.center,
              placeholder: l10n.yourName,
              autofocus: true,
              onSubmitted: (_) {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx, name);
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: SoundService.wrapTap(() {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx, name);
              }),
              child: Text(l10n.continueLabel, style: theme.title),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _onGuest() async {
    if (_entering) return;
    final name = await _askName();
    if (!mounted || name == null || name.isEmpty) return;
    await _saveNameAndEnter(name);
  }

  Future<void> _saveNameAndEnter(String name) async {
    if (_entering) return;
    setState(() => _entering = true);
    try {
      await context.read<HomeViewModel>().updatePlayerName(name);
      if (!mounted) return;
      context.go('/landing');
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  Future<void> _onGoogle() async {
    if (_entering) return;
    final confirmed = await confirmConnectGoogle(context);
    if (!confirmed || !mounted) return;
    setState(() => _entering = true);
    var needsName = false;
    String? suggested;
    try {
      final vm = context.read<HomeViewModel>();
      final result = await vm.linkGoogle();
      if (!mounted) return;
      if (result.status == GoogleAuthStatus.canceled) return;
      if (result.status == GoogleAuthStatus.failed) {
        await _showGoogleError(result.errorCode);
        return;
      }
      final player = vm.player;
      if (player != null && !player.needsAccountSetup) {
        context.go('/landing');
        return;
      }
      suggested = result.suggestedName?.trim();
      needsName = true;
    } finally {
      if (mounted) setState(() => _entering = false);
    }
    if (!mounted || !needsName) return;
    final name = await _askName(
      initial: (suggested != null && suggested.isNotEmpty) ? suggested : null,
    );
    if (!mounted || name == null || name.isEmpty) return;
    await _saveNameAndEnter(name);
  }

  Future<void> _showGoogleError(String? code) async {
    final l10n = AppLocalizations.of(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.google),
        content: Text(l10n.googleSignInError(code)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }

  Future<void> _startTutorial() async {
    if (_entering) return;
    setState(() => _entering = true);
    try {
      if (context.read<HomeViewModel>().player == null) return;
      if (!mounted) return;
      context.go(
        GameRoutes.game(
          gameId: Uuid().v4().substring(0, 6),
          gameMode: GameMode.casino.name,
          tutorial: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeViewModel vm = context.watch<HomeViewModel>();
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      backgroundColor: theme.background,
      child: DecoratedBox(
        decoration: theme.tableBackground(),
        child: SafeArea(child: _body(context, vm, theme, l10n)),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    HomeViewModel vm,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    if (vm.loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vm.player != null && !vm.player!.needsAccountSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/landing');
      });
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vm.name == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.couldNotStart,
                style: theme.title,
                textAlign: TextAlign.center,
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.tryAgain,
                  style: theme.mutedText,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: SoundService.wrapTap(vm.retry),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const bylineReserve = 36.0;
        const buttonsHeight = 44.0;
        final stageH = homeCarouselStageHeight(constraints);
        final gapBelow = ((constraints.maxHeight - stageH) / 2).clamp(
          0.0,
          constraints.maxHeight,
        );
        final regionH = (gapBelow - bylineReserve).clamp(0.0, gapBelow);
        final buttonsBottom =
            bylineReserve + ((regionH - buttonsHeight) / 2).clamp(0.0, regionH);

        return Stack(
          children: [
            Positioned.fill(
              child: StackedCardCarousel(
                key: _carouselKey,
                itemCount: 3,
                initialIndex: _loginPage,
                peekStyle: CardPeekStyle.fan,
                animateBackIn: true,
                fitToHeight: true,
                widthFactor: homeCarouselWidthFactor,
                maxCardWidth: homeCarouselMaxWidth,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return const HomePrivacyCard();
                    case 1:
                      return HomeLoginCard(
                        busy: _entering,
                        onQuickPlay: _startTutorial,
                      );
                    default:
                      return const HomeAboutCard();
                  }
                },
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: buttonsBottom,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: homeCarouselMaxWidth,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: HomeAuthPill(
                          label: l10n.guest,
                          icon: CupertinoIcons.person,
                          onPressed: _entering ? null : _onGuest,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HomeAuthPill(
                          label: l10n.google,
                          leading: const GoogleGMark(size: 15),
                          onPressed: _entering ? null : _onGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Text(
                l10n.appByline,
                textAlign: TextAlign.center,
                style: theme.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                  color: theme.textPrimary.withValues(alpha: .55),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
