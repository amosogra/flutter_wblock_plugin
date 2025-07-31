import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';

class AddFilterListView extends StatefulWidget {
  final AppFilterManager filterManager;

  const AddFilterListView({
    super.key,
    required this.filterManager,
  });

  @override
  State<AddFilterListView> createState() => _AddFilterListViewState();
}

class _AddFilterListViewState extends State<AddFilterListView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
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
      if (widget.filterManager.filterLists.any((filter) => filter.url == trimmedUrl)) {
        _showErrorAlert('A filter list with this URL already exists.');
        return;
      }

      widget.filterManager.addFilterList(
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
    return Container(
      height: 350,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
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
                const Text(
                  'Add Custom Filter List',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
                  child: const Text('Add'),
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
                  const Text(
                    'Filter Name (Optional):',
                    style: TextStyle(fontSize: 12),
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
                  const Text(
                    'Filter URL:',
                    style: TextStyle(fontSize: 12),
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
    return AlertDialog(
      title: const Text('Add Custom Filter List'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Name (Optional):', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., My Ad Block List',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Filter URL:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'https://example.com/filter.txt',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
