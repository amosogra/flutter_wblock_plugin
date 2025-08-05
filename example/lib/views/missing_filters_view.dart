import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'dart:io';

class MissingFiltersView extends StatefulWidget {
  final AppFilterManager filterManager;
  final VoidCallback onDismiss;

  const MissingFiltersView({
    super.key,
    required this.filterManager,
    required this.onDismiss,
  });

  @override
  State<MissingFiltersView> createState() => _MissingFiltersViewState();
}

class _MissingFiltersViewState extends State<MissingFiltersView> {
  int get progressPercentage => (widget.filterManager.progress * 100).round();

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
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MacosColors.windowBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildIOSView() {
    return Container(
      color: CupertinoColors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        SizedBox(
          height: widget.filterManager.isLoading ? 200 : 250,
          child: widget.filterManager.isLoading ? _buildDownloadProgress() : _buildFilterList(),
        ),
        if (!widget.filterManager.isLoading) ...[
          const SizedBox(height: 20),
          _buildButtons(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.filterManager.isLoading ? 'Downloading Missing Filters' : 'Missing Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const Spacer(),
        if (!widget.filterManager.isLoading)
          Platform.isMacOS
              ? MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                  onPressed: widget.onDismiss,
                )
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onDismiss,
                  child: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'After downloading, filter lists will be applied automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: widget.filterManager.progress,
            backgroundColor: Platform.isMacOS ? MacosColors.quaternaryLabelColor : CupertinoColors.systemGrey4,
            valueColor: AlwaysStoppedAnimation<Color>(
              Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$progressPercentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterList() {
    if (widget.filterManager.missingFilters.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Platform.isMacOS ? MacosColors.controlBackgroundColor : CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Platform.isMacOS ? Border.all(color: MacosColors.separatorColor) : null,
      ),
      child: ListView.separated(
        itemCount: widget.filterManager.missingFilters.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final filter = widget.filterManager.missingFilters[index];
          return _buildFilterRow(filter);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.checkmark_circle,
            size: 48,
            color: Colors.green.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No Missing Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All enabled filter lists are downloaded and ready',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(FilterList filter) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                  ),
                ),
              ),
            ],
          ),
          if (filter.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                filter.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _buildCategoryBadge(filter.category),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(FilterListCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.rawValue,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
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
                onPressed: widget.filterManager.missingFilters.isEmpty ? null : _downloadMissingFilters,
                child: const Text('Download'),
              )
            : CupertinoButton.filled(
                onPressed: widget.filterManager.missingFilters.isEmpty ? null : _downloadMissingFilters,
                child: const Text('Download'),
              ),
      ],
    );
  }

  Color _getCategoryColor(FilterListCategory category) {
    switch (category) {
      case FilterListCategory.ads:
        return Colors.red;
      case FilterListCategory.privacy:
        return Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue;
      case FilterListCategory.security:
        return Colors.green;
      case FilterListCategory.multipurpose:
        return Colors.orange;
      case FilterListCategory.annoyances:
        return Colors.purple;
      case FilterListCategory.experimental:
        return Colors.yellow;
      case FilterListCategory.foreign:
        return Platform.isMacOS ? MacosColors.systemTealColor : CupertinoColors.systemTeal;
      case FilterListCategory.custom:
        return Platform.isMacOS ? MacosColors.systemGrayColor : CupertinoColors.systemGrey;
      default:
        return Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label;
    }
  }

  Future<void> _downloadMissingFilters() async {
    await widget.filterManager.downloadMissingFilters();
  }
}
