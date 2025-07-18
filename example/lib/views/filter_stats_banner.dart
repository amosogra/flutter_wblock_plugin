import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import '../widgets/stat_card.dart';

class FilterStatsBanner extends StatelessWidget {
  final FilterListManager filterManager;

  const FilterStatsBanner({
    super.key,
    required this.filterManager,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FilterStats>(
      future: filterManager.getFilterStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final enabledCount = stats?.enabledListsCount ?? 0;
        final totalRules = stats?.totalRulesCount ?? 0;

        final (pillColor, textColor) = _getPillInfo(totalRules);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatCard(
              title: 'Enabled Lists',
              value: '$enabledCount',
              icon: Icons.list,
              pillColor: MacosTheme.of(context).canvasColor,
              valueColor: MacosColors.systemBlueColor,
            ),
            const SizedBox(width: 28),
            StatCard(
              title: 'Rule Count',
              value: _formatRuleCount(totalRules),
              icon: Icons.shield,
              pillColor: pillColor,
              valueColor: textColor,
            ),
          ],
        );
      },
    );
  }

  (Color, Color) _getPillInfo(int ruleCount) {
    if (ruleCount == 0) {
      return (MacosColors.systemGrayColor.withOpacity(0.2), MacosColors.systemGrayColor);
    } else if (ruleCount < 140000) {
      return (MacosColors.systemBlueColor.withOpacity(0.1), MacosColors.systemBlueColor);
    } else if (ruleCount < 150000) {
      return (MacosColors.systemYellowColor.withOpacity(0.2), MacosColors.systemOrangeColor);
    } else {
      return (MacosColors.systemRedColor.withOpacity(0.2), MacosColors.systemRedColor);
    }
  }

  String _formatRuleCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    }
    return count.toString();
  }
}
