import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/user_script_manager.dart';

class UserScriptManagerView extends StatefulWidget {
  final UserScriptManager userScriptManager;

  const UserScriptManagerView({
    super.key,
    required this.userScriptManager,
  });

  @override
  State<UserScriptManagerView> createState() => _UserScriptManagerViewState();
}

class _UserScriptManagerViewState extends State<UserScriptManagerView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _showAddScriptView = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleAddScriptView() {
    setState(() {
      _showAddScriptView = !_showAddScriptView;
      if (!_showAddScriptView) {
        _nameController.clear();
        _contentController.clear();
      }
    });
  }

  void _addScript() {
    if (_nameController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      _showErrorAlert('Please enter both name and content for the script.');
      return;
    }

    widget.userScriptManager.addScript(
      name: _nameController.text.trim(),
      content: _contentController.text.trim(),
    );

    _toggleAddScriptView();
  }

  void _showErrorAlert(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Input'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Input'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
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
        middle: const Text('User Scripts'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(_showAddScriptView ? CupertinoIcons.xmark : CupertinoIcons.add),
          onPressed: _toggleAddScriptView,
        ),
      ),
      child: SafeArea(
        child: _showAddScriptView ? _buildAddScriptForm() : _buildScriptsList(),
      ),
    );
  }

  Widget _buildMacOSView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Scripts'),
        actions: [
          IconButton(
            icon: Icon(_showAddScriptView ? Icons.close : Icons.add),
            onPressed: _toggleAddScriptView,
          ),
        ],
      ),
      body: _showAddScriptView ? _buildAddScriptForm() : _buildScriptsList(),
    );
  }

  Widget _buildScriptsList() {
    final scripts = widget.userScriptManager.userScripts;

    if (scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS ? CupertinoIcons.doc_text : Icons.description,
              size: 64,
              color: Platform.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No user scripts',
              style: TextStyle(
                fontSize: 18,
                color: Platform.isIOS
                    ? CupertinoColors.secondaryLabel
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a new script',
              style: TextStyle(
                fontSize: 14,
                color: Platform.isIOS
                    ? CupertinoColors.tertiaryLabel
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scripts.length,
      itemBuilder: (context, index) {
        final script = scripts[index];
        return _buildScriptRow(script);
      },
    );
  }

  Widget _buildScriptRow(dynamic script) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemGrey6.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    script.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    script.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isIOS
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (Platform.isIOS)
              CupertinoSwitch(
                value: script.isEnabled,
                onChanged: (value) {
                  widget.userScriptManager.toggleScript(script.id);
                },
              )
            else
              Switch(
                value: script.isEnabled,
                onChanged: (value) {
                  widget.userScriptManager.toggleScript(script.id);
                },
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showDeleteConfirmation(script),
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.trash
                    : Icons.delete,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(dynamic script) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Script'),
          content: Text('Are you sure you want to delete "${script.name}"?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context);
                widget.userScriptManager.removeScript(script.id);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Script'),
          content: Text('Are you sure you want to delete "${script.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.userScriptManager.removeScript(script.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddScriptForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Script Name:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Platform.isIOS
                  ? CupertinoColors.label
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          if (Platform.isIOS)
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Enter script name',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter script name',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Script Content:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Platform.isIOS
                  ? CupertinoColors.label
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(
                color: Platform.isIOS
                    ? CupertinoColors.separator.resolveFrom(context)
                    : Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Platform.isIOS
                ? CupertinoTextField(
                    controller: _contentController,
                    placeholder: 'Enter JavaScript code',
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12,
                    ),
                  )
                : TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Enter JavaScript code',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Platform.isIOS) ...[
                CupertinoButton(
                  onPressed: _toggleAddScriptView,
                  child: const Text('Cancel'),
                ),
                CupertinoButton.filled(
                  onPressed: _addScript,
                  child: const Text('Add Script'),
                ),
              ] else ...[
                TextButton(
                  onPressed: _toggleAddScriptView,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addScript,
                  child: const Text('Add Script'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
