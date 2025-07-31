import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? pillColor;
  final Color? valueColor;

  static const double valueWidth = 80;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.pillColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePillColor = pillColor ?? Colors.transparent;
    final effectiveValueColor = valueColor ?? 
        (Platform.isIOS 
            ? CupertinoColors.label.resolveFrom(context)
            : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: effectivePillColor.withOpacity(0.85),
        borderRadius: Platform.isIOS
            ? BorderRadius.circular(22)
            : BorderRadius.circular(50), // Capsule shape
        boxShadow: [
          BoxShadow(
            color: effectivePillColor.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: effectiveValueColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Platform.isIOS
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: valueWidth,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: effectiveValueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
