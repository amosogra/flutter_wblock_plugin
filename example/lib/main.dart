import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/views/content_view.dart';
import 'package:flutter_wblock_plugin_example/views/onboarding_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      child: Platform.isMacOS
          ? const MacOSApp()
          : const IOSApp(),
    );
  }
}

class MacOSApp extends StatelessWidget {
  const MacOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wBlock',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IOSApp extends StatelessWidget {
  const IOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'wBlock',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCompletedOnboarding == null) {
      // Loading state
      if (Platform.isIOS) {
        return const CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        );
      } else {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    }

    final filterManager = context.watch<AppFilterManager>();
    final userScriptManager = context.watch<UserScriptManager>();

    if (!_hasCompletedOnboarding!) {
      return OnboardingView(
        filterManager: filterManager,
        userScriptManager: userScriptManager,
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasCompletedOnboarding', true);
          setState(() {
            _hasCompletedOnboarding = true;
          });
        },
      );
    }

    return ContentView(
      filterManager: filterManager,
      userScriptManager: userScriptManager,
    );
  }
}
