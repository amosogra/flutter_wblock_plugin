import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';

class MissingFiltersView extends StatelessWidget {
  final AppFilterManager filterManager;

  const MissingFiltersView({
    super.key,
    required this.filterManager,
  });

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
      height: MediaQuery.of(context).size.height * 0.7,
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
                const SizedBox(width: 60),
                const Text(
                  'Missing Filters',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done'),
                  onPressed: () {
                    filterManager.setShowMissingFiltersSheet(false);
                    Navigator.of(context).pop();
                  },
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
      title: const Text('Missing Filters'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _buildContent(context),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await filterManager.checkForUpdates();
            filterManager.setShowMissingFiltersSheet(false);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Download Missing'),
        ),
        ElevatedButton(
          onPressed: () {
            filterManager.setShowMissingFiltersSheet(false);
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    // Get missing filters (filters that are selected but don't have files)
    final missingFilters = filterManager.filterLists
        .where((filter) => filter.isSelected && !filterManager.doesFilterFileExist(filter))
        .toList();

    if (missingFilters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.checkmark_circle
                  : Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'All selected filters are available',
              style: TextStyle(fontSize: 16),
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
                'The following filters are selected but their files are missing:',
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
                '${missingFilters.length} filter${missingFilters.length == 1 ? '' : 's'} missing',
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
            itemCount: missingFilters.length,
            itemBuilder: (context, index) {
              final filter = missingFilters[index];
              return _buildMissingFilterItem(context, filter.name, filter.url);
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
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () async {
                  await filterManager.checkForUpdates();
                  filterManager.setShowMissingFiltersSheet(false);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Download Missing Filters'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMissingFilterItem(BuildContext context, String name, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemGrey6.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : Icons.warning,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: TextStyle(
              fontSize: 12,
              color: Platform.isIOS
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
