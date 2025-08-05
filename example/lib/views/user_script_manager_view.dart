import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';
import 'package:flutter_wblock_plugin_example/views/stat_card.dart';
import 'dart:io';

class UserScriptManagerView extends StatefulWidget {
  final UserScriptManager userScriptManager;
  final VoidCallback onDismiss;

  const UserScriptManagerView({
    super.key,
    required this.userScriptManager,
    required this.onDismiss,
  });

  @override
  State<UserScriptManagerView> createState() => _UserScriptManagerViewState();
}

class _UserScriptManagerViewState extends State<UserScriptManagerView> {
  bool _isRefreshing = false;
  double _refreshProgress = 0.0;
  String _refreshStatus = '';
  bool _showingRefreshProgress = false;
  bool _showingAddScriptSheet = false;
  UserScript? _selectedScript;

  String get totalScriptsTitle => Platform.isMacOS ? 'Total Scripts' : 'Scripts';

  int get totalScriptsCount => widget.userScriptManager.userScripts.length;

  int get enabledScriptsCount => widget.userScriptManager.userScripts.where((s) => s.isEnabled).length;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserScriptManager>(
      builder: (context, userScriptManager, child) {
        if (Platform.isMacOS) {
          return _buildMacOSView(userScriptManager);
        } else {
          return _buildIOSView(userScriptManager);
        }
      },
    );
  }

  Widget _buildMacOSView(UserScriptManager userScriptManager) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 700,
          height: 600,
          decoration: BoxDecoration(
            color: MacosColors.windowBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildMacOSHeader(),
              _buildHeaderView(userScriptManager),
              Expanded(
                child: userScriptManager.userScripts.isEmpty ? _buildEmptyStateView() : _buildScriptsList(userScriptManager),
              ),
              _buildBottomToolbar(userScriptManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView(UserScriptManager userScriptManager) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('User Scripts'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onDismiss,
          child: const Icon(CupertinoIcons.xmark_circle_fill),
        ),
      ),
      child: Column(
        children: [
          _buildHeaderView(userScriptManager),
          Expanded(
            child: userScriptManager.userScripts.isEmpty ? _buildEmptyStateView() : _buildScriptsList(userScriptManager),
          ),
          _buildBottomToolbar(userScriptManager),
        ],
      ),
    );
  }

  Widget _buildMacOSHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'User Scripts',
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

  Widget _buildHeaderView(UserScriptManager userScriptManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: totalScriptsTitle,
                  value: '$totalScriptsCount',
                  icon: 'doc.text',
                  pillColor: Colors.transparent,
                  valueColor: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatCard(
                  title: 'Enabled',
                  value: '$enabledScriptsCount',
                  icon: 'checkmark.circle',
                  pillColor: Colors.transparent,
                  valueColor: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                ),
              ),
            ],
          ),
          if (userScriptManager.isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Platform.isMacOS ? const ProgressCircle(value: null) : const CupertinoActivityIndicator(radius: 8),
                ),
                const SizedBox(width: 8),
                Text(
                  userScriptManager.statusDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScriptsList(UserScriptManager userScriptManager) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: userScriptManager.userScripts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = userScriptManager.userScripts[index];
        return _buildUserScriptRow(script, userScriptManager);
      },
    );
  }

  Widget _buildUserScriptRow(UserScript script, UserScriptManager userScriptManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            script.isDownloaded ? CupertinoIcons.doc_text_fill : CupertinoIcons.doc_text,
            color: script.isDownloaded
                ? (Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue)
                : (Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  script.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                  ),
                ),
                if (script.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    script.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                _buildScriptMetadata(script),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (script.isDownloaded) ...[
                Platform.isMacOS
                    ? MacosIconButton(
                        icon: const MacosIcon(CupertinoIcons.refresh),
                        onPressed: () => _updateScript(script, userScriptManager),
                      )
                    : CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _updateScript(script, userScriptManager),
                        child: const Icon(CupertinoIcons.refresh),
                      ),
                const SizedBox(width: 8),
              ],
              Platform.isMacOS
                  ? MacosSwitch(
                      value: script.isEnabled,
                      onChanged: script.isDownloaded ? (value) => userScriptManager.toggleUserScript(script) : null,
                    )
                  : CupertinoSwitch(
                      value: script.isEnabled,
                      onChanged: script.isDownloaded ? (value) => userScriptManager.toggleUserScript(script) : null,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptMetadata(UserScript script) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (script.version.isNotEmpty) _buildBadge('v${script.version}', Colors.blue),
        _buildBadge(
          '${script.matches.length} pattern${script.matches.length == 1 ? '' : 's'}',
          Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
        ),
        if (!script.isDownloaded) _buildBadge('Not Downloaded', Colors.red),
        if (script.isDownloaded) _buildBadge('Downloaded', Colors.green),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text_search,
            size: 48,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor.withOpacity(0.6) : CupertinoColors.secondaryLabel.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'No User Scripts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add userscripts to customize your browsing experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 24),
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () => setState(() => _showingAddScriptSheet = true),
                  child: const Text('Add User Script'),
                )
              : CupertinoButton.filled(
                  onPressed: () => setState(() => _showingAddScriptSheet = true),
                  child: const Text('Add User Script'),
                ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(UserScriptManager userScriptManager) {
    return Container(
      decoration: BoxDecoration(
        color: Platform.isMacOS ? MacosColors.windowBackgroundColor.withOpacity(0.8) : CupertinoColors.systemBackground.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Platform.isMacOS ? MacosColors.separatorColor : CupertinoColors.separator,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showingRefreshProgress) _buildProgressBar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Platform.isMacOS
                    ? PushButton(
                        controlSize: ControlSize.large,
                        onPressed: _isRefreshing ? null : () => _refreshAllUserScripts(userScriptManager),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRefreshing) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: ProgressCircle(value: null),
                              ),
                              const SizedBox(width: 6),
                            ] else
                              const Icon(CupertinoIcons.refresh_circled, size: 16),
                            const Text('Update All'),
                          ],
                        ),
                      )
                    : CupertinoButton(
                        onPressed: _isRefreshing ? null : () => _refreshAllUserScripts(userScriptManager),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRefreshing) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CupertinoActivityIndicator(radius: 6),
                              ),
                              const SizedBox(width: 6),
                            ] else
                              const Icon(CupertinoIcons.refresh_circled, size: 16),
                            const Text('Update All'),
                          ],
                        ),
                      ),
                const SizedBox(width: 16),
                Platform.isMacOS
                    ? PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () => setState(() => _showingAddScriptSheet = true),
                        child: const Text('Add Script'),
                      )
                    : CupertinoButton.filled(
                        onPressed: () => setState(() => _showingAddScriptSheet = true),
                        child: const Text('Add Script'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Platform.isMacOS ? MacosColors.systemBlueColor.withOpacity(0.05) : CupertinoColors.systemBlue.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _refreshStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                ),
              ),
              const Spacer(),
              Text(
                '${(_refreshProgress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _refreshProgress,
            backgroundColor: Platform.isMacOS ? MacosColors.quaternaryLabelColor : CupertinoColors.systemGrey4,
            valueColor: AlwaysStoppedAnimation<Color>(
              Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScript(UserScript script, UserScriptManager userScriptManager) async {
    await userScriptManager.updateUserScript(script);
  }

  Future<void> _refreshAllUserScripts(UserScriptManager userScriptManager) async {
    final downloadedScripts = userScriptManager.userScripts.where((s) => s.isDownloaded).toList();
    if (downloadedScripts.isEmpty) return;

    setState(() {
      _isRefreshing = true;
      _showingRefreshProgress = true;
      _refreshProgress = 0.0;
      _refreshStatus = 'Starting refresh...';
    });

    try {
      for (int i = 0; i < downloadedScripts.length; i++) {
        final script = downloadedScripts[i];
        setState(() {
          _refreshStatus = 'Updating ${script.name}...';
          _refreshProgress = i / downloadedScripts.length;
        });

        await userScriptManager.updateUserScript(script);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _refreshProgress = 1.0;
        _refreshStatus = 'Refresh complete!';
      });

      await Future.delayed(const Duration(seconds: 1));
    } finally {
      setState(() {
        _showingRefreshProgress = false;
        _isRefreshing = false;
      });
    }
  }

  // Add UserScript sheet would be shown here
  void _showAddScriptSheet() {
    setState(() {
      _showingAddScriptSheet = true;
    });
  }
}

class AddUserScriptView extends StatefulWidget {
  final UserScriptManager userScriptManager;
  final VoidCallback onDismiss;

  const AddUserScriptView({
    super.key,
    required this.userScriptManager,
    required this.onDismiss,
  });

  @override
  State<AddUserScriptView> createState() => _AddUserScriptViewState();
}

class _AddUserScriptViewState extends State<AddUserScriptView> {
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: Platform.isMacOS ? 500 : double.infinity,
          height: Platform.isMacOS ? 250 : null,
          margin: Platform.isMacOS ? null : const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Platform.isMacOS ? MacosColors.windowBackgroundColor : CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add User Script',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the URL of a userscript (ending in .user.js)',
                style: TextStyle(
                  fontSize: 14,
                  color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              Platform.isMacOS
                  ? MacosTextField(
                      controller: _urlController,
                      placeholder: 'https://example.com/script.user.js',
                    )
                  : CupertinoTextField(
                      controller: _urlController,
                      placeholder: 'https://example.com/script.user.js',
                      keyboardType: TextInputType.url,
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Platform.isMacOS
                      ? PushButton(
                          controlSize: ControlSize.large,
                          onPressed: widget.onDismiss,
                          child: const Text('Cancel'),
                        )
                      : CupertinoButton(
                          onPressed: widget.onDismiss,
                          child: const Text('Cancel'),
                        ),
                  const Spacer(),
                  Platform.isMacOS
                      ? PushButton(
                          controlSize: ControlSize.large,
                          onPressed: _isLoading || _urlController.text.trim().isEmpty ? null : _addScript,
                          child: _isLoading
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: ProgressCircle(value: null),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Adding...'),
                                  ],
                                )
                              : const Text('Add Script'),
                        )
                      : CupertinoButton.filled(
                          onPressed: _isLoading || _urlController.text.trim().isEmpty ? null : _addScript,
                          child: _isLoading
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CupertinoActivityIndicator(radius: 8),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Adding...'),
                                  ],
                                )
                              : const Text('Add Script'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addScript() async {
    final urlString = _urlController.text.trim();
    final url = Uri.tryParse(urlString);

    if (url == null || url.scheme.isEmpty || url.host.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.userScriptManager.addUserScriptFromUrl(url);
      widget.onDismiss();
    } catch (e) {
      print('Error adding user script: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
