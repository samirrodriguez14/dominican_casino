 import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

Widget _buildChallengePlayerArea(ScrollController scrollController) {
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
              color: AppStyle.theme.muted.withOpacity(0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_2_fill,
                        color: AppStyle.theme.turnHighlight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Challenge a Player', style: AppStyle.theme.title),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                CupertinoSearchTextField(
                  placeholder: 'Search player or enter ID',
                ),

                const SizedBox(height: 16),

                Text('Recent Players', style: AppStyle.theme.title),
                const SizedBox(height: 10),

                ...List.generate(12, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppStyle.theme.raisedSurfaceBox(),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle,
                            color: AppStyle.theme.turnHighlight,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Player $index',
                              style: AppStyle.theme.body,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 30,
                            onPressed: () {},
                            child: Text(
                              'Challenge',
                              style: AppStyle.theme.body.copyWith(
                                color: AppStyle.theme.turnHighlight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
