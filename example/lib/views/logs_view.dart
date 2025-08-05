import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'dart:io';

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
  String _logs = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await FlutterWblockPlugin.getLogs();
      setState(() {
        _logs = logs;
      });
    } catch (e) {
      setState(() {
        _logs = 'Error loading logs: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    try {
      await FlutterWblockPlugin.clearLogs();
      await _loadLogs();
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return _buildMacOSView();
    } else {
      return _buildIOSView();
    }
  }

  Widget _buildMacOSView() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 600,
          height: 650,
          decoration: BoxDecoration(
            color: MacosColors.windowBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildMacOSHeader(),
              Expanded(
                child: _buildContent(),
              ),
              _buildMacOSButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('wBlock Logs'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onDismiss,
          child: const Icon(CupertinoIcons.xmark_circle_fill),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildContent(),
          ),
          _buildIOSButtons(),
        ],
      ),
    );
  }

  Widget _buildMacOSHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'wBlock Logs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MacosColors.labelColor,
            ),
          ),
          const Spacer(),
          MacosIconButton(
            icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Platform.isMacOS ? const ProgressCircle() : const CupertinoActivityIndicator(),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Platform.isMacOS ? MacosColors.textBackgroundColor : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Platform.isMacOS ? MacosColors.separatorColor : CupertinoColors.separator,
        ),
      ),
      child: Platform.isMacOS
          ? SelectableText(
              _logs.isEmpty ? 'No logs available' : _logs,
              style: const TextStyle(
                fontFamily: 'SF Mono',
                fontSize: 12,
              ),
            )
          : SingleChildScrollView(
              child: SelectableText(
                _logs.isEmpty ? 'No logs available' : _logs,
                style: const TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  Widget _buildMacOSButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          PushButton(
            controlSize: ControlSize.large,
            onPressed: _loadLogs,
            child: const Text('Refresh'),
          ),
          const SizedBox(width: 16),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: _clearLogs,
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton.filled(
              onPressed: _loadLogs,
              child: const Text('Refresh'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoButton(
              color: CupertinoColors.destructiveRed,
              onPressed: _clearLogs,
              child: const Text('Clear Logs'),
            ),
          ),
        ],
      ),
    );
  }
}
