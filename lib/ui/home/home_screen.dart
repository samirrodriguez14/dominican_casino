import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerId = "Player123"; 
  
    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.35,
            image: const AssetImage(
              'assets/images/logo_icon_wooden_transparent.png',
            ),
            fit: BoxFit.fitHeight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 28,
                ),
                decoration: AppStyle.theme.raisedSurfaceBox(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ---- TITLE ----
                    Text(
                      "Dominican Casino",
                      textAlign: TextAlign.center,
                      style: AppStyle.theme.title.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// ---- DIVIDER ----
                    Container(
                      height: 1,
                      width: 120,
                      color: AppStyle.theme.surfaceAlt.withOpacity(.6),
                    ),

                    const SizedBox(height: 20),

                    /// ---- PLAYER NAME ----
                    GestureDetector(
                      onTap: () {
                        // later open edit name popup
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyle.theme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.person,
                              size: 16,
                              color: AppStyle.theme.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(playerId, style: AppStyle.theme.body),
                            const SizedBox(width: 6),
                            Icon(
                              CupertinoIcons.pencil,
                              size: 14,
                              color: AppStyle.theme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// ---- START BUTTON ----
                    CupertinoButton(
                      color: AppStyle.theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      onPressed: () {
                        context.go('/lobby');
                      },
                      child: Text(
                        "Lobby",
                        style: TextStyle(
                          color: AppStyle.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
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