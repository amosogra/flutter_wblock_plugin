import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';
import 'package:flutter_wblock_plugin_example/views/stat_card.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class UserScriptManagerView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const UserScriptManagerView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<UserScriptManagerView> createState() => _UserScriptManagerViewState();
}

class _UserScriptManagerViewState extends ConsumerState<UserScriptManagerView> {
  bool _isRefreshing = false;
  double _refreshProgress = 0.0;
  String _refreshStatus = '';
  bool _showingRefreshProgress = false;
  bool _showingAddScriptSheet = false;
  UserScript? _selectedScript;

  @override
  Widget build(BuildContext context) {
    final userScriptManager = ref.watch(userScriptManagerProvider);
    
    String totalScriptsTitle = Platform.isMacOS ? 'Total Scripts' : 'Scripts';
    int totalScriptsCount = userScriptManager.userScripts.length;
    int enabledScriptsCount = userScriptManager.userScripts.where((s) => s.isEnabled).length;

    if (Platform.isMacOS) {
      return _buildMacOSView(userScriptManager, totalScriptsTitle, totalScriptsCount, enabledScriptsCount);
    } else {
      return _buildIOSView(userScriptManager, totalScriptsTitle, totalScriptsCount, enabledScriptsCount);
    }
  }

  Widget _buildMacOSView(userScriptManager, String totalScriptsTitle, int totalScriptsCount, int enabledScriptsCount) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 700,
          height: 600,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            children: [
              _buildMacOSHeader(),
              _buildHeaderView(userScriptManager, totalScriptsTitle, totalScriptsCount, enabledScriptsCount),
              Expanded(
                child: userScriptManager.userScripts.isEmpty 
                  ? _buildEmptyStateView() 
                  : _buildScriptsList(userScriptManager),
              ),
              _buildBottomToolbar(userScriptManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView(userScriptManager, String totalScriptsTitle, int totalScriptsCount, int enabledScriptsCount) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.cardBackground.withOpacity(0.94),
        middle: const Text('User Scripts'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onDismiss,
          child: const Icon(CupertinoIcons.xmark_circle_fill),
        ),
      ),
      child: Column(
        children: [
          _buildHeaderView(userScriptManager, totalScriptsTitle, totalScriptsCount, enabledScriptsCount),
          Expanded(
            child: userScriptManager.userScripts.isEmpty 
              ? _buildEmptyStateView() 
              : _buildScriptsList(userScriptManager),
          ),
          _buildBottomToolbar(userScriptManager),
        ],
      ),
    );
  }

  Widget _buildMacOSHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'User Scripts',
            style: AppTheme.headline,
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

  Widget _buildHeaderView(userScriptManager, String totalScriptsTitle, int totalScriptsCount, int enabledScriptsCount) {
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
                  valueColor: CupertinoColors.label,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatCard(
                  title: 'Enabled',
                  value: '$enabledScriptsCount',
                  icon: 'checkmark.circle',
                  pillColor: Colors.transparent,
                  valueColor: CupertinoColors.label,
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
                  child: Platform.isMacOS 
                    ? const ProgressCircle(value: null) 
                    : const CupertinoActivityIndicator(radius: 8),
                ),
                const SizedBox(width: 8),
                Text(
                  userScriptManager.statusDescription,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScriptsList(userScriptManager) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: userScriptManager.userScripts.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppTheme.dividerColor,
      ),
      itemBuilder: (context, index) {
        final script = userScriptManager.userScripts[index];
        return _buildUserScriptRow(script, userScriptManager);
      },
    );
  }

  Widget _buildUserScriptRow(UserScript script, userScriptManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            script.isDownloaded ? CupertinoIcons.doc_text_fill : CupertinoIcons.doc_text,
            color: script.isDownloaded
                ? AppTheme.primaryColor
                : AppTheme.secondaryLabel,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  script.name,
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (script.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    script.description,
                    style: AppTheme.caption,
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
                      onChanged: script.isDownloaded 
                        ? (value) => userScriptManager.toggleUserScript(script) 
                        : null,
                    )
                  : CupertinoSwitch(
                      value: script.isEnabled,
                      onChanged: script.isDownloaded 
                        ? (value) => userScriptManager.toggleUserScript(script) 
                        : null,
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
        if (script.version.isNotEmpty) _buildBadge('v${script.version}', AppTheme.primaryColor),
        _buildBadge(
          '${script.matches.length} pattern${script.matches.length == 1 ? '' : 's'}',
          AppTheme.secondaryLabel,
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
            color: AppTheme.secondaryLabel.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'No User Scripts',
            style: AppTheme.headline,
          ),
          const SizedBox(height: 8),
          Text(
            'Add userscripts to customize your browsing experience',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
          const SizedBox(height: 24),
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  color: AppTheme.primaryColor,
                  onPressed: () => _showAddScriptSheet(),
                  child: const Text('Add User Script'),
                )
              : CupertinoButton.filled(
                  onPressed: () => _showAddScriptSheet(),
                  child: const Text('Add User Script'),
                ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(userScriptManager) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
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
                        onPressed: _isRefreshing 
                          ? null 
                          : () => _refreshAllUserScripts(userScriptManager),
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
                        onPressed: _isRefreshing 
                          ? null 
                          : () => _refreshAllUserScripts(userScriptManager),
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
                        color: AppTheme.primaryColor,
                        onPressed: () => _showAddScriptSheet(),
                        child: const Text('Add Script'),
                      )
                    : CupertinoButton.filled(
                        onPressed: () => _showAddScriptSheet(),
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
        color: AppTheme.primaryColor.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _refreshStatus,
                style: AppTheme.caption,
              ),
              const Spacer(),
              Text(
                '${(_refreshProgress * 100).round()}%',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _refreshProgress,
            backgroundColor: Platform.isMacOS 
              ? MacosColors.quaternaryLabelColor 
              : CupertinoColors.systemGrey4,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScript(UserScript script, userScriptManager) async {
    await userScriptManager.updateUserScript(script);
  }

  Future<void> _refreshAllUserScripts(userScriptManager) async {
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

  void _showAddScriptSheet() {
    final userScriptManager = ref.read(userScriptManagerProvider);
    
    if (Platform.isMacOS) {
      showMacosSheet(
        context: context,
        builder: (context) => AddUserScriptView(
          userScriptManager: userScriptManager,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => AddUserScriptView(
          userScriptManager: userScriptManager,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
  }
}

class AddUserScriptView extends StatefulWidget {
  final userScriptManager;
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
    if (Platform.isMacOS) {
      return _buildMacOSView();
    } else {
      return _buildIOSView();
    }
  }

  Widget _buildMacOSView() {
    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add User Script',
              style: AppTheme.headline,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the URL of a userscript (ending in .user.js)',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 16),
            MacosTextField(
              controller: _urlController,
              placeholder: 'https://example.com/script.user.js',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: widget.onDismiss,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.large,
                  color: AppTheme.primaryColor,
                  onPressed: _isLoading || _urlController.text.trim().isEmpty 
                    ? null 
                    : _addScript,
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSView() {
    return Container(
      height: 300,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onDismiss,
                  child: const Text('Cancel'),
                ),
                Text(
                  'Add User Script',
                  style: AppTheme.headline,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading || _urlController.text.trim().isEmpty 
                    ? null 
                    : _addScript,
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
                      : Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the URL of a userscript (ending in .user.js)',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _urlController,
                    placeholder: 'https://example.com/script.user.js',
                    keyboardType: TextInputType.url,
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),
          ),
        ],
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
