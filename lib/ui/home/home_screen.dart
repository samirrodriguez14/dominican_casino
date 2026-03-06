import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerId = "Player123"; // replace later with repo value

    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.4,
            image: AssetImage('assets/images/logo_full.png'),
            fit: BoxFit
                .fitHeight, // This ensures the image covers the entire screen
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
              child: Container(
                decoration: AppStyle.theme.raisedSurfaceBox(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 28),

                    /// ---- TITLE ----
                    Text(
                      "Dominican Casino",
                      style: AppStyle.theme.title.copyWith(fontSize: 36),
                    ),

                    const SizedBox(height: 10),

                    /// ---- PLAYER NAME ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(playerId, style: AppStyle.theme.body),
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.pencil,
                          size: 16,
                          color: AppStyle.theme.muted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    /// ---- START BUTTON ----
                    CupertinoButton(
                      color: AppStyle.theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      onPressed: () {
                        context.go('/lobby');
                      },
                      child: Text(
                        "Start",
                        style: TextStyle(
                          color: AppStyle.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
