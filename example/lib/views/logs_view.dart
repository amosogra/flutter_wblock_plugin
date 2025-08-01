import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  String _logsText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final logsText = await FlutterWblockPlugin.getLogs();
      
      setState(() {
        _logsText = logsText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading logs: $e');
    }
  }

  Future<void> _clearLogs() async {
    try {
      await FlutterWblockPlugin.clearLogs();
      setState(() {
        _logsText = '';
      });
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }

  void _copyAllLogs() {
    Clipboard.setData(ClipboardData(text: _logsText));
    
    // Show feedback
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Copied'),
          content: const Text('All logs have been copied to clipboard'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All logs copied to clipboard')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    } else {
      return _buildMacOSView();
    }
  }

  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Logs'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _logsText.isEmpty ? null : _copyAllLogs,
              child: const Icon(CupertinoIcons.doc_on_clipboard),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _logsText.isEmpty ? null : () => _showClearConfirmation(),
              child: const Icon(CupertinoIcons.trash),
            ),
          ],
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildMacOSView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _logsText.isEmpty ? null : _copyAllLogs,
            tooltip: 'Copy All',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _logsText.isEmpty ? null : () => _showClearConfirmation(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (_logsText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.doc_text
                  : Icons.description,
              size: 64,
              color: Platform.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No logs available',
              style: TextStyle(
                fontSize: 18,
                color: Platform.isIOS
                    ? CupertinoColors.secondaryLabel
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Logs will appear here when the app performs actions',
              style: TextStyle(
                fontSize: 14,
                color: Platform.isIOS
                    ? CupertinoColors.tertiaryLabel
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Platform.isIOS
              ? CupertinoColors.systemGrey6.resolveFrom(context)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Platform.isIOS
                ? CupertinoColors.separator.resolveFrom(context)
                : Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: SelectableText(
          _logsText,
          style: TextStyle(
            fontSize: 13,
            fontFamily: Platform.isIOS ? 'SF Mono' : 'monospace',
            height: 1.5,
          ),
        ),
      ),
    );
  }


  void _showClearConfirmation() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Clear Logs'),
          content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Clear'),
              onPressed: () {
                Navigator.pop(context);
                _clearLogs();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Logs'),
          content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearLogs();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
    }
  }
}
