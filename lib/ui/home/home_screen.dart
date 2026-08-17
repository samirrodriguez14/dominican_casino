import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/home/home_instruction_card.dart';
import 'package:dominican_casino/ui/home/home_login_card.dart';
import 'package:dominican_casino/ui/home/home_privacy_card.dart';
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
  static const _privacyPage = 0;
  static const _instructionsPage = 2;

  final TextEditingController _nameController = TextEditingController();
  late final PageController _pageController;
  List<InstructionSection> _sections = const [];
  bool _entering = false;
  bool _askingName = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _loginPage);
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeViewModel>().loadPlayer();
      _ensureInstructions();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startNameStep() {
    final vm = context.read<HomeViewModel>();
    final name = vm.name;
    if (name != null && !(vm.player?.needsAccountSetup ?? true)) {
      _nameController.text = name;
    }
    setState(() => _askingName = true);
  }

  Future<void> _onGoogle() async {
    if (_entering) return;
    setState(() => _entering = true);
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
      final suggested = result.suggestedName?.trim();
      if (suggested != null && suggested.isNotEmpty) {
        _nameController.text = suggested;
      }
      setState(() => _askingName = true);
    } finally {
      if (mounted) setState(() => _entering = false);
    }
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

  void _cancelNameStep() {
    setState(() => _askingName = false);
  }

  Future<void> _goTo(int page) async {
    if (page == _instructionsPage) {
      await _ensureInstructions();
      if (!mounted) return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _ensureInstructions() async {
    if (_sections.isNotEmpty) return;
    try {
      final data = await loadInstructions(homeInstructionMode);
      if (!mounted) return;
      setState(() => _sections = data.sections);
    } catch (_) {}
  }

  Future<void> _enter() async {
    if (_entering) return;
    final typed = _nameController.text.trim();
    if (typed.isEmpty) return;
    setState(() => _entering = true);
    try {
      final vm = context.read<HomeViewModel>();
      await vm.updatePlayerName(typed);
      if (!mounted) return;
      context.go('/landing');
    } finally {
      if (mounted) setState(() => _entering = false);
    }
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

    if (vm.player != null && !vm.player!.needsAccountSetup && !_askingName) {
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

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          l10n.appTitle,
          style: theme.title.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: theme.textPrimary.withValues(alpha: .9),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PrivacyPane(onBack: () => _goTo(_loginPage)),
              _LoginPane(
                nameController: _nameController,
                busy: _entering,
                askingName: _askingName,
                onGuest: _startNameStep,
                onGoogle: _onGoogle,
                onQuickPlay: _startTutorial,
                onContinue: _enter,
                onCancelName: _cancelNameStep,
                onPrivacy: () => _goTo(_privacyPage),
                onInstructions: () => _goTo(_instructionsPage),
              ),
              _InstructionsPane(
                sections: _sections,
                onBack: () => _goTo(_loginPage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginPane extends StatelessWidget {
  const _LoginPane({
    required this.nameController,
    required this.busy,
    required this.askingName,
    required this.onGuest,
    required this.onGoogle,
    required this.onQuickPlay,
    required this.onContinue,
    required this.onCancelName,
    required this.onPrivacy,
    required this.onInstructions,
  });

  final TextEditingController nameController;
  final bool busy;
  final bool askingName;
  final VoidCallback onGuest;
  final VoidCallback onGoogle;
  final VoidCallback onQuickPlay;
  final VoidCallback onContinue;
  final VoidCallback onCancelName;
  final VoidCallback onPrivacy;
  final VoidCallback onInstructions;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = homeCardWidth(constraints);
              return Center(
                child: SizedBox(
                  width: width,
                  child: HomeLoginCard(
                    nameController: nameController,
                    askingName: askingName,
                    busy: busy,
                    onGuest: onGuest,
                    onGoogle: onGoogle,
                    onQuickPlay: onQuickPlay,
                    onContinue: onContinue,
                    onCancelName: onCancelName,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TextLink(label: l10n.privacy, onPressed: onPrivacy),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('·', style: theme.mutedText.copyWith(fontSize: 18)),
              ),
              _TextLink(label: l10n.instructions, onPressed: onInstructions),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyPane extends StatelessWidget {
  const _PrivacyPane({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = homeCardWidth(constraints);
              return Center(
                child: SizedBox(width: width, child: const HomePrivacyCard()),
              );
            },
          ),
        ),
        _PaneBackButton(label: l10n.back, trailing: true, onPressed: onBack),
      ],
    );
  }
}

class _InstructionsPane extends StatelessWidget {
  const _InstructionsPane({required this.sections, required this.onBack});

  final List<InstructionSection> sections;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: sections.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : StackedCardCarousel(
                  itemCount: sections.length,
                  widthFactor: homeCardWidthFactor,
                  maxCardWidth: homeCardMaxWidth,
                  fitToHeight: true,
                  itemBuilder: (context, index) {
                    return HomeInstructionCard(
                      section: sections[index],
                      pageNumber: index + 1,
                      totalPages: sections.length,
                    );
                  },
                ),
        ),
        _PaneBackButton(label: l10n.back, trailing: false, onPressed: onBack),
      ],
    );
  }
}

class _PaneBackButton extends StatelessWidget {
  const _PaneBackButton({
    required this.label,
    required this.trailing,
    required this.onPressed,
  });

  final String label;
  final bool trailing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final arrow = Icon(
      trailing ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
      size: 16,
      color: theme.muted,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onPressed),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!trailing) ...[arrow, const SizedBox(width: 4)],
            Text(
              label,
              style: theme.mutedText.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: theme.muted.withValues(alpha: .45),
              ),
            ),
            if (trailing) ...[const SizedBox(width: 4), arrow],
          ],
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Text(
        label,
        style: theme.caption.copyWith(
          color: theme.muted,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: theme.muted.withValues(alpha: .4),
        ),
      ),
    );
  }
}
