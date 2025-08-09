import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class MissingFiltersView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const MissingFiltersView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<MissingFiltersView> createState() => _MissingFiltersViewState();
}

class _MissingFiltersViewState extends ConsumerState<MissingFiltersView> {
  @override
  Widget build(BuildContext context) {
    final filterManager = ref.watch(appFilterManagerProvider);
    final progressPercentage = (filterManager.progress * 100).round();

    if (Platform.isMacOS) {
      return _buildMacOSView(filterManager, progressPercentage);
    } else {
      return _buildIOSView(filterManager, progressPercentage);
    }
  }

  Widget _buildMacOSView(filterManager, int progressPercentage) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: _buildContent(filterManager, progressPercentage),
        ),
      ),
    );
  }

  Widget _buildIOSView(filterManager, int progressPercentage) {
    return Container(
      color: CupertinoColors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: _buildContent(filterManager, progressPercentage),
        ),
      ),
    );
  }

  Widget _buildContent(filterManager, int progressPercentage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(filterManager),
        const SizedBox(height: 20),
        SizedBox(
          height: filterManager.isLoading ? 200 : 250,
          child: filterManager.isLoading 
            ? _buildDownloadProgress(filterManager, progressPercentage) 
            : _buildFilterList(filterManager),
        ),
        if (!filterManager.isLoading) ...[
          const SizedBox(height: 20),
          _buildButtons(filterManager),
        ],
      ],
    );
  }

  Widget _buildHeader(filterManager) {
    return Row(
      children: [
        Text(
          filterManager.isLoading ? 'Downloading Missing Filters' : 'Missing Filters',
          style: AppTheme.headline,
        ),
        const Spacer(),
        if (!filterManager.isLoading)
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

  Widget _buildDownloadProgress(filterManager, int progressPercentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIndicator(filterManager, progressPercentage),
        const SizedBox(height: 16),
        Text(
          'After downloading, filter lists will be applied automatically.',
          textAlign: TextAlign.center,
          style: AppTheme.caption,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(filterManager, int progressPercentage) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: filterManager.progress,
            backgroundColor: Platform.isMacOS 
              ? MacosColors.quaternaryLabelColor 
              : CupertinoColors.systemGrey4,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$progressPercentage%',
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterList(filterManager) {
    if (filterManager.missingFilters.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Platform.isMacOS 
          ? MacosColors.controlBackgroundColor 
          : CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Platform.isMacOS 
          ? Border.all(color: MacosColors.separatorColor) 
          : null,
      ),
      child: ListView.separated(
        itemCount: filterManager.missingFilters.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppTheme.dividerColor,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final filter = filterManager.missingFilters[index];
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
            style: AppTheme.headline,
          ),
          const SizedBox(height: 8),
          Text(
            'All enabled filter lists are downloaded and ready',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
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
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w500,
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
                style: AppTheme.caption,
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

  Widget _buildButtons(filterManager) {
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
                color: AppTheme.primaryColor,
                onPressed: filterManager.missingFilters.isEmpty 
                  ? null 
                  : () => _downloadMissingFilters(filterManager),
                child: const Text('Download'),
              )
            : CupertinoButton.filled(
                onPressed: filterManager.missingFilters.isEmpty 
                  ? null 
                  : () => _downloadMissingFilters(filterManager),
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
        return AppTheme.primaryColor;
      case FilterListCategory.security:
        return Colors.green;
      case FilterListCategory.multipurpose:
        return Colors.orange;
      case FilterListCategory.annoyances:
        return Colors.purple;
      case FilterListCategory.experimental:
        return Colors.yellow;
      case FilterListCategory.foreign:
        return Platform.isMacOS 
          ? MacosColors.systemTealColor 
          : CupertinoColors.systemTeal;
      case FilterListCategory.custom:
        return Platform.isMacOS 
          ? MacosColors.systemGrayColor 
          : CupertinoColors.systemGrey;
      default:
        return CupertinoColors.label;
    }
  }

  Future<void> _downloadMissingFilters(filterManager) async {
    await filterManager.downloadMissingFilters();
  }
}
