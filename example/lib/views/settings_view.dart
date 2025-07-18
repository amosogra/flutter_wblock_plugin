import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onDismiss;

  const SettingsView({
    super.key,
    required this.onDismiss,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoUpdate = false;
  String _updateFrequency = 'Daily';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 400,
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
                  'Settings',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(Icons.close),
                  onPressed: widget.onDismiss,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Settings Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto Update Section
                  Text(
                    'Updates',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      MacosSwitch(
                        value: _autoUpdate,
                        onChanged: (value) => setState(() => _autoUpdate = value),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Automatically update filter lists',
                        style: MacosTheme.of(context).typography.body,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_autoUpdate) ...[
                    Row(
                      children: [
                        Text(
                          'Update frequency:',
                          style: MacosTheme.of(context).typography.body,
                        ),
                        const SizedBox(width: 12),
                        MacosPopupButton<String>(
                          value: _updateFrequency,
                          items: const [
                            MacosPopupMenuItem(value: 'Hourly', child: Text('Hourly')),
                            MacosPopupMenuItem(value: 'Daily', child: Text('Daily')),
                            MacosPopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _updateFrequency = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // About Section
                  Text(
                    'About',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'wBlock 0.2.0 Beta',
                    style: MacosTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The next-generation ad blocker for Safari',
                    style: MacosTheme.of(context).typography.body.copyWith(
                      color: MacosTheme.of(context).typography.body.color?.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Links
                  MacosListTile(
                    leading: const MacosIcon(Icons.code),
                    title: Text(
                      'View on GitHub',
                      style: MacosTheme.of(context).typography.body,
                    ),
                    onClick: () async {
                      const url = 'https://github.com/0xCUB3/wBlock';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  MacosListTile(
                    leading: const MacosIcon(Icons.bug_report),
                    title: Text(
                      'Report an Issue',
                      style: MacosTheme.of(context).typography.body,
                    ),
                    onClick: () async {
                      const url = 'https://github.com/0xCUB3/wBlock/issues';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  
                  const Spacer(),
                  
                  // Close Button
                  Center(
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      onPressed: widget.onDismiss,
                      child: const Text('Close'),
                    ),
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
