import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color pillColor;
  final Color valueColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.pillColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: valueColor.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MacosTheme.of(context).typography.caption1.copyWith(
                  color: MacosTheme.of(context).typography.caption1.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: MacosTheme.of(context).typography.title3.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
