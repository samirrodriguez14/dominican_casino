import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CasinoBoard extends StatelessWidget {
  final Widget child;

  const CasinoBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
  return 
  Container(
  padding: const EdgeInsets.all(2),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    boxShadow: const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7A5746),
        Color(0xFF5A4032),
        Color(0xFF3A281F),
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  ),
  child: 
  ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.8,
            child: Image.asset(
              'assets/images/wood_grain.png',
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
       
        Container(
          margin: const EdgeInsets.all(24),
          decoration: AppStyle.theme.tableBackground().copyWith(
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ],
    ),
  ),
);
  }
}
