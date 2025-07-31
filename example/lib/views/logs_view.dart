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
  List<Map<String, dynamic>> _logs = [];
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
      
      final logs = await FlutterWblockPlugin.getLogs();
      
      setState(() {
        _logs = logs;
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
        _logs = [];
      });
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }

  void _copyAllLogs() {
    final logsText = _logs.map((log) {
      final timestamp = log['timestamp'] ?? '';
      final message = log['message'] ?? '';
      return '$timestamp: $message';
    }).join('\n');
    
    Clipboard.setData(ClipboardData(text: logsText));
    
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

  void _copyLogEntry(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? '';
    final message = log['message'] ?? '';
    final text = '$timestamp: $message';
    
    Clipboard.setData(ClipboardData(text: text));
    
    // Show feedback
    if (Platform.isIOS) {
      // No feedback for individual entries on iOS to match native behavior
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log entry copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
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
              child: const Icon(CupertinoIcons.doc_on_clipboard),
              onPressed: _logs.isEmpty ? null : _copyAllLogs,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.trash),
              onPressed: _logs.isEmpty ? null : () => _showClearConfirmation(),
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
            onPressed: _logs.isEmpty ? null : _copyAllLogs,
            tooltip: 'Copy All',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _logs.isEmpty ? null : () => _showClearConfirmation(),
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

    if (_logs.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? '';
    final message = log['message'] ?? '';
    
    return GestureDetector(
      onLongPress: () => _copyLogEntry(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Platform.isIOS
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Theme.of(context).textTheme.bodySmall?.color,
                fontFamily: Platform.isIOS ? 'SF Mono' : 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
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
