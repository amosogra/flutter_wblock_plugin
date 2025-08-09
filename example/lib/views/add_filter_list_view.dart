import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class AddFilterListView extends ConsumerStatefulWidget {
  const AddFilterListView({super.key});

  @override
  ConsumerState<AddFilterListView> createState() => _AddFilterListViewState();
}

class _AddFilterListViewState extends ConsumerState<AddFilterListView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final filterManager = ref.read(appFilterManagerProvider);
    final trimmedUrl = _urlController.text.trim();
    
    if (trimmedUrl.isEmpty) {
      _showErrorAlert('Please enter a URL');
      return;
    }

    try {
      final url = Uri.parse(trimmedUrl);
      if (url.scheme.isEmpty || url.host.isEmpty) {
        _showErrorAlert('The URL entered is not valid. Please enter a complete and correct URL (e.g., http:// or https://).');
        return;
      }

      // Check if URL already exists
      if (filterManager.filterLists.any((filter) => filter.url == trimmedUrl)) {
        _showErrorAlert('A filter list with this URL already exists.');
        return;
      }

      filterManager.addFilterList(
        name: _nameController.text.trim(),
        urlString: trimmedUrl,
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorAlert('The URL entered is not valid. Please enter a complete and correct URL.');
    }
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
      showMacosAlertDialog(
        context: context,
        builder: (context) => MacosAlertDialog(
          appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
          title: const Text('Invalid Input'),
          message: Text(message),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
    return Container(
      height: 350,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Text(
                  'Add Custom Filter List',
                  style: AppTheme.headline,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
                  child: Text(
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
                    'Filter Name (Optional):',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'e.g., My Ad Block List',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filter URL:',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _urlController,
                    placeholder: 'https://example.com/filter.txt',
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSView() {
    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Custom Filter List', style: AppTheme.headline),
            const SizedBox(height: 20),
            Text('Filter Name (Optional):', style: AppTheme.caption),
            const SizedBox(height: 4),
            MacosTextField(
              controller: _nameController,
              placeholder: 'e.g., My Ad Block List',
            ),
            const SizedBox(height: 16),
            Text('Filter URL:', style: AppTheme.caption),
            const SizedBox(height: 4),
            MacosTextField(
              controller: _urlController,
              placeholder: 'https://example.com/filter.txt',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.large,
                  color: AppTheme.primaryColor,
                  onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
