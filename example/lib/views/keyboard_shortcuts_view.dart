import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class KeyboardShortcutsView extends StatelessWidget {
  final VoidCallback onDismiss;

  const KeyboardShortcutsView({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      ('⌘R', 'Check for Updates'),
      ('⌘S', 'Apply Changes'),
      ('⌘N', 'Add Custom Filter'),
      ('⌘⇧L', 'Show Logs'),
      ('⌘,', 'Show Settings'),
      ('⌘⌥R', 'Reset to Default'),
      ('⌘⇧F', 'Toggle Only Enabled Filters'),
      ('⌘⇧K', 'Keyboard Shortcuts'),
    ];

    return Container(
      width: 400,
      height: 450,
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: MacosTheme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  'Keyboard Shortcuts',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(Icons.close),
                  onPressed: onDismiss,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Shortcuts List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ...shortcuts.map((shortcut) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: MacosTheme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shortcut.$1,
                            style: TextStyle(
                              fontFamily: 'SF Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: MacosTheme.of(context).typography.body.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            shortcut.$2,
                            style: MacosTheme.of(context).typography.body,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Spacer(),
                  PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: onDismiss,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
