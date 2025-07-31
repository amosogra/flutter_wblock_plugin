import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';
import '../managers/user_script_manager.dart';

class UpdatePopupView extends StatefulWidget {
  final AppFilterManager filterManager;
  final UserScriptManager userScriptManager;
  final ValueChanged<bool> isPresented;

  const UpdatePopupView({
    super.key,
    required this.filterManager,
    required this.userScriptManager,
    required this.isPresented,
  });

  @override
  State<UpdatePopupView> createState() => _UpdatePopupViewState();
}

class _UpdatePopupViewState extends State<UpdatePopupView> {
  Set<String> selectedUpdateIds = {};

  @override
  void initState() {
    super.initState();
    // Select all updates by default
    selectedUpdateIds = widget.filterManager.availableUpdates
        .map((update) => update['id'] as String)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView(context);
    } else {
      return _buildMacOSView(context);
    }
  }

  Widget _buildIOSView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  onPressed: () {
                    widget.isPresented(false);
                  },
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Updates Available',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: selectedUpdateIds.isEmpty
                      ? null
                      : () async {
                          await _applyUpdates();
                          widget.isPresented(false);
                        },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSView(BuildContext context) {
    return AlertDialog(
      title: const Text('Updates Available'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _buildContent(context),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.isPresented(false);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedUpdateIds.isEmpty
              ? null
              : () async {
                  await _applyUpdates();
                  widget.isPresented(false);
                },
          child: const Text('Update Selected'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final updates = widget.filterManager.availableUpdates;
    
    if (updates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.checkmark_circle
                  : Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'All filters are up to date!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following filter lists have updates available:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Platform.isIOS
                      ? CupertinoColors.label.resolveFrom(context)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${updates.length} update${updates.length == 1 ? '' : 's'} available',
                style: TextStyle(
                  fontSize: 14,
                  color: Platform.isIOS
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              return _buildUpdateItem(context, update);
            },
          ),
        ),
        if (Platform.isIOS)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          if (selectedUpdateIds.length == updates.length) {
                            selectedUpdateIds.clear();
                          } else {
                            selectedUpdateIds = updates
                                .map((u) => u['id'] as String)
                                .toSet();
                          }
                        });
                      },
                      child: Text(
                        selectedUpdateIds.length == updates.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                    Text(
                      '${selectedUpdateIds.length} selected',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: selectedUpdateIds.isEmpty
                        ? null
                        : () async {
                            await _applyUpdates();
                            widget.isPresented(false);
                          },
                    child: Text(
                      selectedUpdateIds.isEmpty
                          ? 'Select Updates to Apply'
                          : 'Update ${selectedUpdateIds.length} Filter${selectedUpdateIds.length == 1 ? '' : 's'}',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUpdateItem(BuildContext context, Map<String, dynamic> update) {
    final isSelected = selectedUpdateIds.contains(update['id']);
    final name = update['name'] as String;
    final currentVersion = update['currentVersion'] as String;
    final newVersion = update['newVersion'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemGrey6.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Platform.isIOS
                  ? CupertinoColors.activeBlue.resolveFrom(context)
                  : Theme.of(context).primaryColor
              : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedUpdateIds.remove(update['id']);
            } else {
              selectedUpdateIds.add(update['id'] as String);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (Platform.isIOS)
                Icon(
                  isSelected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: isSelected
                      ? CupertinoColors.activeBlue.resolveFrom(context)
                      : CupertinoColors.tertiaryLabel.resolveFrom(context),
                  size: 24,
                )
              else
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        selectedUpdateIds.add(update['id'] as String);
                      } else {
                        selectedUpdateIds.remove(update['id']);
                      }
                    });
                  },
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Version $currentVersion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Platform.isIOS
                                ? CupertinoColors.secondaryLabel.resolveFrom(context)
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.arrow_right
                                : Icons.arrow_forward,
                            size: 14,
                            color: Platform.isIOS
                                ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          'Version $newVersion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyUpdates() async {
    await widget.filterManager.applyUpdates(selectedUpdateIds.toList());
  }
}
