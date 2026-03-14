import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GameStatusSheet extends StatefulWidget {
  const GameStatusSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<GameStatusSheet> createState() => _GameStatusSheetState();
}

class _GameStatusSheetState extends State<GameStatusSheet> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, -4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppStyle.theme.muted.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(child: 
          ListView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Center(
                child: Text("Game Status", style: AppStyle.theme.mutedText),
              ),
            ],
          ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
