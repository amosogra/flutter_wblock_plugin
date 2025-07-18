import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class LogsView extends StatefulWidget {
  final VoidCallback onDismiss;

  const LogsView({
    super.key,
    required this.onDismiss,
  });

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load logs when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilterListManager>().loadLogsFromFile();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterManager = context.watch<FilterListManager>();

    return Container(
      width: 600,
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
                  'Logs',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: filterManager.logs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs copied to clipboard')),
                    );
                  },
                  semanticLabel: 'Copy Logs',
                ),
                MacosIconButton(
                  icon: const MacosIcon(Icons.delete_outline),
                  onPressed: () => filterManager.clearLogs(),
                  semanticLabel: 'Clear Logs',
                ),
                MacosIconButton(
                  icon: const MacosIcon(Icons.close),
                  onPressed: widget.onDismiss,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Log Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: MacosScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    filterManager.logs.isEmpty
                        ? 'No logs available'
                        : filterManager.logs,
                    style: TextStyle(
                      fontFamily: 'SF Mono',
                      fontSize: 12,
                      color: MacosTheme.of(context).typography.body.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
