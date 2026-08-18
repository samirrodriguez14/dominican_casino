import 'package:dominican_casino/ui/app_shell/profile/profile_card.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();

  void goToInitial() {
    _carouselKey.currentState?.goToIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, shellTopBarHeight(context), 12, 108),
      child: StackedCardCarousel(
        key: _carouselKey,
        itemCount: 2,
        peekStyle: CardPeekStyle.stack,
        animateBackIn: true,
        widthFactor: homeCardWidthFactor,
        maxCardWidth: homeCardMaxWidth,
        fitToHeight: true,
        itemBuilder: (context, index) {
          return index == 0 ? const ProfileCard() : const ProfileSettingsBody();
        },
      ),
    );
  }
}
