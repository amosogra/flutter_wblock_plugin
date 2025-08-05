import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

/// Theme constants for wBlock to match the native Swift UI appearance
class WBlockTheme {
  // Prevent instantiation
  WBlockTheme._();

  // Background colors
  static const Color macOSBackgroundColor = Color(0xFFF5F5F7); // Light gray background
  static const Color iOSBackgroundColor = Color(0xFFF2F2F7); // System grouped background
  static const Color windowBackgroundColor = Color(0xFFF0F0F0); // Window background
  
  // Card/Container colors
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure white
  static final Color cardBackgroundColorTranslucent = Colors.white.withOpacity(0.8);
  static final Color modalBackgroundColor = Colors.white.withOpacity(0.95);
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF000000); // Black
  static const Color secondaryTextColor = Color(0xFF8E8E93); // Secondary gray
  static const Color tertiaryTextColor = Color(0xFFC7C7CC); // Tertiary gray
  
  // Component colors
  static const Color statCardBackground = Color(0xFFF5F5F7); // Light gray for stat cards
  static const Color dividerColor = Color(0xFFE5E5EA); // Light divider
  static final Color subtleDividerColor = Colors.black.withOpacity(0.1);
  
  // iOS specific
  static const Color iOSNavigationBarColor = Color(0xFFF9F9F9);
  static final Color iOSNavigationBarColorTranslucent = iOSNavigationBarColor.withOpacity(0.94);
  
  // Shadow and effects
  static final Color shadowColor = Colors.black.withOpacity(0.05);
  static final Color overlayColor = Colors.black.withOpacity(0.1);
  
  // Alert colors
  static const Color warningColor = Colors.orange;
  static const Color errorColor = CupertinoColors.systemRed;
  static const Color successColor = CupertinoColors.systemGreen;
  
  // Get background color based on platform
  static Color getBackgroundColor() {
    if (Platform.isMacOS) {
      return macOSBackgroundColor;
    } else if (Platform.isIOS) {
      return iOSBackgroundColor;
    }
    return Colors.grey[100]!;
  }
  
  // Get card shadow
  static BoxShadow getCardShadow() {
    return BoxShadow(
      color: shadowColor,
      blurRadius: 2,
      offset: const Offset(0, 1),
    );
  }
  
  // Standard border radius
  static const double borderRadius = 12.0;
  static const double pillBorderRadius = 100.0;
  static const double iOSContinuousBorderRadius = 22.0;
  
  // Standard padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets iOSScreenPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  
  // Text styles
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
  );
  
  static const TextStyle smallCaptionStyle = TextStyle(
    fontSize: 11,
    color: tertiaryTextColor,
  );
  
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );
  
  static const TextStyle statLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: secondaryTextColor,
  );
}
