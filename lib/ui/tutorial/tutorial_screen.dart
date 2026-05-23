import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      child: SafeArea(
        child: Consumer<TutorialViewModel>(
          builder: (context, vm, _) {
            // Animate to the page when step changes
            if (_pageController.hasClients &&
                vm.currentStep != _pageController.page?.round()) {
              _pageController.animateToPage(
                vm.currentStep,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }

            return Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      opacity: 0.35,
                      image: AssetImage(AppStyle.theme.appLogo),
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
                // Tutorial Content
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    vm.goToStep(index);
                  },
                  children: [
                    _buildWelcomeStep(context, vm),
                    _buildAppShellOverviewStep(context, vm),
                    _buildGameScreenStep(context, vm),
                    _buildStartGameStep(context, vm),
                    _buildGameWalkthroughStep(context, vm),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context, TutorialViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Welcome to Dominican Casino!",
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 100,
                color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
              ),
              const SizedBox(height: 24),
              Text(
                "Let's learn how to play! This quick tutorial will guide you through the app and show you how to start your first game against Puli, our AI opponent.",
                textAlign: TextAlign.center,
                style: AppStyle.theme.body.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildProgressIndicator(vm.currentStep, vm.totalSteps),
              const SizedBox(height: 32),
              _buildNavigationButtons(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppShellOverviewStep(BuildContext context, TutorialViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Main Menu Overview",
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 80,
                color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
              ),
              const SizedBox(height: 24),
              _buildStepContent(
                icon: CupertinoIcons.game_controller,
                title: "Games Tab",
                description:
                    "Browse available games and start new matches against AI opponents or other players.",
              ),
              const SizedBox(height: 16),
              _buildStepContent(
                icon: CupertinoIcons.person,
                title: "Profile Tab",
                description:
                    "View your stats, game history, and manage your player profile.",
              ),
              const SizedBox(height: 16),
              _buildStepContent(
                icon: CupertinoIcons.settings,
                title: "Settings Tab",
                description:
                    "Adjust app preferences, notifications, and other options.",
              ),
              const SizedBox(height: 32),
              _buildProgressIndicator(vm.currentStep, vm.totalSteps),
              const SizedBox(height: 32),
              _buildNavigationButtons(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreenStep(BuildContext context, TutorialViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Game Screen",
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 80,
                color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
              ),
              const SizedBox(height: 24),
              _buildStepContent(
                icon: CupertinoIcons.suit_spade_fill,
                title: "Card Display",
                description:
                    "Your hand appears at the bottom. The board shows all played cards.",
              ),
              const SizedBox(height: 16),
              _buildStepContent(
                icon: CupertinoIcons.square_stack_3d_up,
                title: "Game Stacks",
                description:
                    "Build stacks with cards in sequence. Match numbers and suits strategically.",
              ),
              const SizedBox(height: 16),
              _buildStepContent(
                icon: CupertinoIcons.info_circle,
                title: "Turn Indicator",
                description:
                    "Watch for whose turn it is and plan your moves ahead.",
              ),
              const SizedBox(height: 32),
              _buildProgressIndicator(vm.currentStep, vm.totalSteps),
              const SizedBox(height: 32),
              _buildNavigationButtons(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartGameStep(BuildContext context, TutorialViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Starting a Game",
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 80,
                color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppStyle.theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppStyle.theme.surfaceAlt.withValues(alpha: .5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How to Start a Game:",
                      style: AppStyle.theme.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionRow("1", "Go to the Games tab"),
                    _buildInstructionRow("2", "Select 'Puli' as your opponent"),
                    _buildInstructionRow("3", "Choose your game mode"),
                    _buildInstructionRow("4", "Tap 'Start Game'"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Puli is our friendly AI opponent - perfect for learning!",
                textAlign: TextAlign.center,
                style: AppStyle.theme.body.copyWith(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppStyle.theme.muted,
                ),
              ),
              const SizedBox(height: 32),
              _buildProgressIndicator(vm.currentStep, vm.totalSteps),
              const SizedBox(height: 32),
              _buildNavigationButtons(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameWalkthroughStep(BuildContext context, TutorialViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ready to Play?",
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 80,
                color: AppStyle.theme.surfaceAlt.withValues(alpha: .6),
              ),
              const SizedBox(height: 24),
              Text(
                "Let's play your first game against Puli! You'll see how the game flows in real-time with live gameplay explanations.",
                textAlign: TextAlign.center,
                style: AppStyle.theme.body.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppStyle.theme.surfaceAlt.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppStyle.theme.surfaceAlt.withValues(alpha: .5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb,
                      size: 32,
                      color: AppStyle.theme.surfaceAlt,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tips during gameplay:",
                      style: AppStyle.theme.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pay attention to the highlighted tips and strategy pointers as we play!",
                      textAlign: TextAlign.center,
                      style: AppStyle.theme.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildProgressIndicator(vm.currentStep, vm.totalSteps),
              const SizedBox(height: 32),
              _buildNavigationButtons(context, vm, isFinalStep: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppStyle.theme.surfaceAlt,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyle.theme.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppStyle.theme.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppStyle.theme.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: AppStyle.theme.background,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppStyle.theme.body.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == current
                ? AppStyle.theme.surfaceAlt
                : AppStyle.theme.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    TutorialViewModel vm, {
    bool isFinalStep = false,
  }) {
    return Column(
      children: [
        if (vm.currentStep > 0)
          CupertinoButton(
            onPressed: vm.previousStep,
            child: Text(
              "← Back",
              style: TextStyle(color: AppStyle.theme.muted),
            ),
          ),
        const SizedBox(height: 8),
        if (!isFinalStep)
          CupertinoButton(
            color: AppStyle.theme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            onPressed: vm.nextStep,
            child: Text(
              "Next →",
              style: TextStyle(
                color: AppStyle.theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          CupertinoButton(
            color: AppStyle.theme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            onPressed: vm.isLoading
                ? null
                : () async {
                    await vm.completeTutorial();
                    // ignore: use_build_context_synchronously
                    context.go('/landing');
                  },
            child: Text(
              vm.isLoading ? "Starting game..." : "Play Your First Game!",
              style: TextStyle(
                color: AppStyle.theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
