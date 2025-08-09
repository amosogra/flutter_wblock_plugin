import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';
import 'dart:ui';
import 'package:macos_ui/macos_ui.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color pillColor;
  final Color valueColor;

  static const double valueWidth = 100;

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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: Platform.isIOS 
            ? BorderRadius.circular(22) // Continuous corner for iOS
            : BorderRadius.circular(100), // Capsule for macOS
        boxShadow: pillColor != Colors.transparent 
            ? [AppTheme.cardShadow]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.statLabel,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.statValue.copyWith(
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIconData(icon);
    if (Platform.isMacOS) {
      return MacosIcon(
        iconData,
        size: 24,
        color: valueColor,
      );
    } else {
      return Icon(
        iconData,
        size: 24,
        color: valueColor,
      );
    }
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
