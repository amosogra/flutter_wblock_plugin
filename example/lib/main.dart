import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/views/content_view.dart';
import 'package:flutter_wblock_plugin_example/views/onboarding_view.dart';
import 'package:flutter_wblock_plugin_example/theme/theme_constants.dart';
import 'dart:io';

void main() {
  runApp(const WBlockApp());
}

class WBlockApp extends StatelessWidget {
  const WBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppFilterManager()),
        ChangeNotifierProvider(create: (_) => UserScriptManager()),
      ],
      child: Platform.isMacOS ? const MacOSApp() : const IOSApp(),
    );
  }
}

class MacOSApp extends StatelessWidget {
  const MacOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a custom light theme
    final lightTheme = MacosThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF007AFF),
      canvasColor: const Color(0xFFF5F5F7),
      dividerColor: const Color(0xFFE5E5EA),
    );

    return MacosApp(
      title: 'wBlock',
      theme: lightTheme,
      darkTheme: lightTheme, // Force light theme even in dark mode
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const AppWrapper(),
    );
  }
}

class IOSApp extends StatelessWidget {
  const IOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'wBlock',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        barBackgroundColor: Color(0xFFF9F9F9),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF000000),
        ),
      ),
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle background state for iOS notifications
    if (Platform.isIOS && state == AppLifecycleState.paused) {
      _scheduleNotificationIfNeeded();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final hasCompleted = await FlutterWblockPlugin.hasCompletedOnboarding();
      setState(() {
        _hasCompletedOnboarding = hasCompleted;
      });
    } catch (e) {
      print('Error checking onboarding status: $e');
      setState(() {
        _hasCompletedOnboarding = false;
      });
    }
  }

  Future<void> _scheduleNotificationIfNeeded() async {
    try {
      final hasUnappliedChanges = await FlutterWblockPlugin.hasUnappliedChanges();
      if (hasUnappliedChanges) {
        // Schedule a notification after 1 second of being in background
        await Future.delayed(const Duration(seconds: 1));
        _scheduleUnappliedChangesNotification();
      }
    } catch (e) {
      print('Error checking unapplied changes: $e');
    }
  }

  void _scheduleUnappliedChangesNotification() {
    // This would trigger a local notification on iOS
    // The actual notification scheduling would be handled by the native side
    print('Would schedule notification for unapplied changes');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCompletedOnboarding == null) {
      // Loading state
      return _buildLoadingView();
    }

    return Consumer2<AppFilterManager, UserScriptManager>(
      builder: (context, filterManager, userScriptManager, child) {
        return Stack(
          children: [
            ContentView(
              filterManager: filterManager,
              userScriptManager: userScriptManager,
            ),
            if (!_hasCompletedOnboarding!)
              _buildOnboardingOverlay(filterManager, userScriptManager),
          ],
        );
      },
    );
  }

  Widget _buildLoadingView() {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: WBlockTheme.iOSBackgroundColor,
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    } else {
      return MacosScaffold(
        backgroundColor: WBlockTheme.macOSBackgroundColor,
        children: [
          ContentArea(
            builder: (context, scrollController) => Container(
              color: WBlockTheme.macOSBackgroundColor,
              child: const Center(
                child: ProgressCircle(value: null),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildOnboardingOverlay(AppFilterManager filterManager, UserScriptManager userScriptManager) {
    return Container(
      color: WBlockTheme.windowBackgroundColor,
      child: Center(
        child: OnboardingView(
          filterManager: filterManager,
          userScriptManager: userScriptManager,
          onComplete: () {
            setState(() {
              _hasCompletedOnboarding = true;
            });
          },
        ),
      ),
    );
  }
}
