import 'package:flutter/material.dart';
import 'package:flutter_wblock_example/configs/config.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'views/content_view.dart';

void main() {
  runApp(const WBlockApp());
}

class WBlockApp extends StatelessWidget {
  const WBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilterListManager()),
        ChangeNotifierProvider(create: (_) => UpdateController.shared),
      ],
      child: MacosApp(
        title: 'wBlock',
        navigatorKey: navigatorKey,
        theme: MacosThemeData(
          brightness: Brightness.light,
          accentColor: AccentColor.blue,
        ),
        darkTheme: MacosThemeData(
          brightness: Brightness.dark,
          accentColor: AccentColor.blue,
        ),
        home: const WBlockMainWindow(),
      ),
    );
  }
}

class WBlockMainWindow extends StatelessWidget {
  const WBlockMainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const ContentView();
            },
          ),
        ],
      ),
    );
  }
}
