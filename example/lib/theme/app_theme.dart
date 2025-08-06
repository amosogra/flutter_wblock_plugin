import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'dart:io';
import 'dart:ui';

/// Modern theme system matching native SwiftUI appearance
class AppTheme {
  AppTheme._();
  
  // Material-style backgrounds with blur
  static Widget regularMaterial({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Platform.isMacOS 
              ? Colors.white.withOpacity(0.72)
              : CupertinoColors.systemBackground.resolveFrom(
                  NavigatorState().context
                ).withOpacity(0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
  
  static Widget ultraThinMaterial({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Platform.isMacOS 
              ? Colors.white.withOpacity(0.5)
              : CupertinoColors.systemBackground.resolveFrom(
                  NavigatorState().context
                ).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
  
  // Platform-specific colors
  static Color get primaryColor {
    if (Platform.isMacOS) {
      return const Color(0xFF007AFF); // macOS blue
    } else {
      return CupertinoColors.systemBlue;
    }
  }
  
  static Color get backgroundColor {
    if (Platform.isMacOS) {
      return const Color(0xFFF5F5F7); // Light gray background
    } else {
      return CupertinoColors.systemGroupedBackground;
    }
  }
  
  static Color get cardBackground {
    if (Platform.isMacOS) {
      return Colors.white.withOpacity(0.72);
    } else {
      return CupertinoColors.systemBackground;
    }
  }
  
  static Color get secondaryLabel {
    if (Platform.isMacOS) {
      return const Color(0xFF8E8E93);
    } else {
      return CupertinoColors.secondaryLabel;
    }
  }
  
  static Color get tertiaryLabel {
    if (Platform.isMacOS) {
      return const Color(0xFFC7C7CC);
    } else {
      return CupertinoColors.tertiaryLabel;
    }
  }
  
  static Color get dividerColor {
    if (Platform.isMacOS) {
      return const Color(0xFFE5E5EA).withOpacity(0.6);
    } else {
      return CupertinoColors.separator;
    }
  }
  
  // Typography
  static TextStyle get headline => TextStyle(
    fontSize: Platform.isMacOS ? 17 : 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );
  
  static TextStyle get body => TextStyle(
    fontSize: Platform.isMacOS ? 15 : 16,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.label,
  );
  
  static TextStyle get caption => TextStyle(
    fontSize: Platform.isMacOS ? 12 : 13,
    color: secondaryLabel,
  );
  
  static TextStyle get caption2 => TextStyle(
    fontSize: Platform.isMacOS ? 11 : 12,
    color: tertiaryLabel,
  );
  
  // Stat card specific
  static TextStyle get statValue => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static TextStyle get statLabel => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: secondaryLabel,
  );
  
  // Spacing constants
  static const double defaultPadding = 20.0;
  static const double itemSpacing = 16.0;
  static const double sectionSpacing = 20.0;
  static const double cardPadding = 16.0;
  
  // Border radius
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double pillRadius = 100.0;
  
  // Platform-specific styles
  static BorderRadius get cardBorderRadius {
    if (Platform.isIOS) {
      return BorderRadius.circular(22); // Continuous corner radius
    }
    return BorderRadius.circular(defaultRadius);
  }
  
  static BoxShadow get cardShadow {
    return BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 2,
      offset: const Offset(0, 1),
    );
  }
  
  // Button styles
  static ButtonStyle get primaryButtonStyle {
    if (Platform.isMacOS) {
      return ButtonStyle(
        backgroundColor: WidgetStateProperty.all(primaryColor),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangle(borderRadius: BorderRadius.circular(6)),
        ),
      );
    } else {
      return const ButtonStyle();
    }
  }
  
  static ButtonStyle get secondaryButtonStyle {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.all(primaryColor),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangle(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: dividerColor),
        ),
      ),
    );
  }
  
  // Create material app theme
  static ThemeData getMaterialTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: cardBackground,
      ),
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,
      textTheme: TextTheme(
        headlineSmall: headline,
        bodyLarge: body,
        bodySmall: caption,
        labelSmall: caption2,
      ),
    );
  }
  
  // Create Cupertino theme
  static CupertinoThemeData getCupertinoTheme() {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: backgroundColor,
      barBackgroundColor: cardBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.label,
        textStyle: body,
      ),
    );
  }
  
  // Create macOS theme
  static MacosThemeData getMacOSTheme() {
    return MacosThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      canvasColor: backgroundColor,
      dividerColor: dividerColor,
    );
  }
}

// Custom RoundedRectangle shape
class RoundedRectangle extends OutlinedBorder {
  final BorderRadius borderRadius;
  final BorderSide side;
  
  const RoundedRectangle({
    this.borderRadius = BorderRadius.zero,
    this.side = BorderSide.none,
  });
  
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width));
  }
  
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }
  
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    
    canvas.drawRRect(
      borderRadius.resolve(textDirection).toRRect(rect),
      side.toPaint(),
    );
  }
  
  @override
  ShapeBorder scale(double t) {
    return RoundedRectangle(
      borderRadius: borderRadius * t,
      side: side.scale(t),
    );
  }
  
  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return RoundedRectangle(
      borderRadius: borderRadius,
      side: side ?? this.side,
    );
  }
}
