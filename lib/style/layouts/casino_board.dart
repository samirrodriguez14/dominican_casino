import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CasinoBoard extends StatelessWidget {
  final Widget child;

  const CasinoBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18), // wood thickness
      decoration: 
      BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [AppStyle.theme.border,AppStyle.theme.border],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: AppStyle.theme.tableBackground().copyWith(
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }
}
