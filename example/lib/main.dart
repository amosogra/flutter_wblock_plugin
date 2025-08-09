import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/views/content_view.dart';
import 'package:flutter_wblock_plugin_example/views/onboarding_view.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

void main() {
  runApp(
    const ProviderScope(
      child: WBlockApp(),
    ),
  );
}

class WBlockApp extends ConsumerWidget {
  const WBlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Platform.isMacOS) {
      return MacosApp(
        title: 'Syferlab',
        theme: AppTheme.getMacOSTheme(),
        darkTheme: AppTheme.getMacOSTheme(), // Force light theme
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
      );
    } else {
      return CupertinoApp(
        title: 'Syferlab',
        theme: AppTheme.getCupertinoTheme(),
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
}

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> with WidgetsBindingObserver {
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboardingStatus();
    _initializeManagers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeManagers() {
    // Set the UserScriptManager for filter updates
    final filterManager = ref.read(appFilterManagerProvider);
    final userScriptManager = ref.read(userScriptManagerProvider);
    filterManager.setUserScriptManager(userScriptManager);
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

    return Stack(
      children: [
        const ContentView(),
        if (!_hasCompletedOnboarding!) _buildOnboardingOverlay(),
      ],
    );
  }

  Widget _buildLoadingView() {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AppTheme.backgroundColor,
        child: const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    } else {
      return MacosScaffold(
        backgroundColor: AppTheme.backgroundColor,
        children: [
          ContentArea(
            builder: (context, scrollController) => Container(
              color: AppTheme.backgroundColor,
              child: const Center(
                child: ProgressCircle(value: null),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildOnboardingOverlay() {
    return Container(
      color: AppTheme.backgroundColor,
      child: const Center(
        child: OnboardingView(),
      ),
    );
  }
}
