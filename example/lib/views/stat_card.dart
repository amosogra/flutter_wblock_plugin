import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:macos_ui/macos_ui.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color pillColor;
  final Color valueColor;

  static const double valueWidth = 80;

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
    if (Platform.isMacOS) {
      return _buildMacOSCard();
    } else {
      return _buildIOSCard();
    }
  }

  Widget _buildMacOSCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: pillColor.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            _getIconData(icon),
            size: 24,
            color: valueColor,
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
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: valueWidth,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
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

  Widget _buildIOSCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: pillColor.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconData(icon),
            size: 24,
            color: valueColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: valueWidth,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
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

  IconData _getIconData(String systemName) {
    // Map SF Symbols to Material/Cupertino icons
    switch (systemName) {
      case 'list.bullet.rectangle':
        return CupertinoIcons.square_list;
      case 'shield.lefthalf.filled':
        return CupertinoIcons.shield_lefthalf_fill;
      case 'doc.text':
        return CupertinoIcons.doc_text;
      case 'checkmark.circle':
        return CupertinoIcons.check_mark_circled;
      case 'rectangle.slash':
        return CupertinoIcons.clear;
      case 'eye.slash':
        return CupertinoIcons.eye_slash;
      case 'square.grid.2x2':
        return CupertinoIcons.square_grid_2x2;
      case 'hand.raised':
        return CupertinoIcons.hand_raised;
      case 'flask':
        return CupertinoIcons.lab_flask;
      case 'globe':
        return CupertinoIcons.globe;
      case 'gearshape':
        return CupertinoIcons.gear;
      case 'chart.bar.doc.horizontal':
        return CupertinoIcons.chart_bar;
      case 'clock':
        return CupertinoIcons.clock;
      case 'arrow.clockwise':
        return CupertinoIcons.refresh;
      default:
        return CupertinoIcons.info;
    }
  }
}
