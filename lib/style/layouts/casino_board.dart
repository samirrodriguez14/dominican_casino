import 'package:flutter/cupertino.dart';

class CasinoBoard extends StatelessWidget {
  final Widget child;

  const CasinoBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18), // wood thickness
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4F2A), Color(0xFF5C3A1E)],
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: RadialGradient(
            center: Alignment(0, -0.05),
            radius: 1.2,
            colors: [
              Color.fromARGB(255, 19, 68, 49),
              Color.fromARGB(255, 18, 59, 44),

              Color.fromARGB(255, 11, 44, 32),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
