import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';

class ApplyChangesProgressView extends StatefulWidget {
  final AppFilterManager filterManager;
  final ValueChanged<bool> isPresented;

  const ApplyChangesProgressView({
    super.key,
    required this.filterManager,
    required this.isPresented,
  });

  @override
  State<ApplyChangesProgressView> createState() => _ApplyChangesProgressViewState();
}

class _ApplyChangesProgressViewState extends State<ApplyChangesProgressView> {
  @override
  void initState() {
    super.initState();
    // Listen to filter manager changes
    widget.filterManager.addListener(_onFilterManagerChanged);
  }

  @override
  void dispose() {
    widget.filterManager.removeListener(_onFilterManagerChanged);
    super.dispose();
  }

  void _onFilterManagerChanged() {
    if (!mounted) return;
    setState(() {});
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (widget.filterManager.isLoading || (widget.filterManager.progress >= 1.0 && _hasStatistics)) _buildHeader(context),
          Expanded(
            child: widget.filterManager.isLoading ? _buildProgress(context) : (_hasStatistics ? _buildStatistics(context) : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSView(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 420,
          maxWidth: 480,
          minHeight: 350,
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.filterManager.isLoading || (widget.filterManager.progress >= 1.0 && _hasStatistics)) _buildHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: widget.filterManager.isLoading ? _buildProgress(context) : (_hasStatistics ? _buildStatistics(context) : const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasStatistics {
    return widget.filterManager.lastRuleCount > 0 || widget.filterManager.ruleCountsByCategory.isNotEmpty;
  }

  String get _titleText {
    if (widget.filterManager.progress >= 1.0 && !widget.filterManager.isLoading) {
      return 'Filter Lists Applied';
    } else {
      return 'Converting Filter Lists';
    }
  }

  int get _progressPercentage {
    final progress = widget.filterManager.progress.clamp(0.0, 1.0);
    return (progress * 100).toInt();
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Center(
              child: Text(
                _titleText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!widget.filterManager.isLoading && widget.filterManager.progress >= 1.0)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Platform.isIOS ? CupertinoIcons.xmark_circle_fill : Icons.close,
                    color: Colors.grey,
                    size: 28,
                  ),
                  onPressed: () => widget.isPresented(false),
                ),
              ),
          ],
        ),
        if (widget.filterManager.isLoading &&
            widget.filterManager.conversionStageDescription.isNotEmpty &&
            widget.filterManager.conversionStageDescription != _titleText) ...[
          const SizedBox(height: 8),
          Text(
            widget.filterManager.conversionStageDescription,
            style: TextStyle(
              fontSize: 14,
              color: Platform.isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
        if (widget.filterManager.isLoading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: widget.filterManager.progress,
            minHeight: Platform.isIOS ? 4 : 6,
          ),
          const SizedBox(height: 8),
          Text(
            '$_progressPercentage%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    final phaseData = _getPhaseData();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Platform.isIOS ? CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.5) : Theme.of(context).cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (int i = 0; i < phaseData.length; i++) ...[
                _buildPhaseRow(
                  context: context,
                  icon: phaseData[i]['icon'] as IconData,
                  title: phaseData[i]['title'] as String,
                  detail: phaseData[i]['detail'] as String?,
                  isActive: phaseData[i]['isActive'] as bool,
                  isCompleted: phaseData[i]['isCompleted'] as bool,
                ),
                if (i < phaseData.length - 1)
                  Divider(
                    indent: 32,
                    height: 1,
                    color: Platform.isIOS ? CupertinoColors.separator.resolveFrom(context) : Theme.of(context).dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getPhaseData() {
    final fm = widget.filterManager;
    return [
      {
        'icon': CupertinoIcons.folder_badge_plus,
        'title': 'Reading Files',
        'detail': fm.totalFiltersCount > 0 ? '${fm.processedFiltersCount}/${fm.totalFiltersCount} extensions' : null,
        'isActive': fm.processedFiltersCount < fm.totalFiltersCount && !fm.isInConversionPhase,
        'isCompleted': fm.processedFiltersCount >= fm.totalFiltersCount || fm.progress > 0.6,
      },
      {
        'icon': CupertinoIcons.gear_alt_fill,
        'title': 'Converting Rules',
        'detail': fm.currentFilterName.isNotEmpty ? 'Processing ${fm.currentFilterName}' : null,
        'isActive': fm.isInConversionPhase,
        'isCompleted': fm.progress > 0.75,
      },
      {
        'icon': CupertinoIcons.square_arrow_down,
        'title': 'Saving & Building',
        'detail': (fm.isInSavingPhase || fm.isInEnginePhase || (fm.progress > 0.7 && fm.progress < 0.95)) ? 'Writing files and building engines' : null,
        'isActive': fm.isInSavingPhase || fm.isInEnginePhase || (fm.progress > 0.7 && fm.progress < 0.95),
        'isCompleted': fm.progress > 0.9,
      },
      {
        'icon': CupertinoIcons.arrow_clockwise,
        'title': 'Reloading Extensions',
        'detail': fm.isInReloadPhase && fm.currentFilterName.isNotEmpty ? 'Reloading ${fm.currentFilterName}' : null,
        'isActive': fm.isInReloadPhase,
        'isCompleted': fm.progress >= 1.0,
      },
    ];
  }

  Widget _buildPhaseRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? detail,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? Platform.isIOS
                        ? CupertinoColors.activeBlue
                        : Theme.of(context).primaryColor
                    : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? null
                            : Colors.grey,
                  ),
                ),
                SizedBox(
                  height: 16,
                  child: detail != null && detail.isNotEmpty
                      ? Text(
                          detail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Platform.isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.green,
              size: 16,
            )
          else if (isActive)
            Platform.isIOS
                ? const CupertinoActivityIndicator(radius: 8)
                : const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
          else
            const SizedBox(width: 16, height: 16),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall statistics
        _buildStatisticsSection(
          context: context,
          icon: CupertinoIcons.doc_chart,
          title: 'Overall Statistics',
          color: Platform.isIOS ? CupertinoColors.activeBlue : Colors.blue,
          statistics: _buildOverallStatistics(),
        ),

        // Per-category statistics (if available)
        if (widget.filterManager.ruleCountsByCategory.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildStatisticsSection(
            context: context,
            icon: CupertinoIcons.square_grid_2x2,
            title: 'Category Statistics',
            color: Colors.orange,
            statistics: _buildCategoryStatistics(),
          ),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _buildOverallStatistics() {
    final fm = widget.filterManager;
    final stats = <Map<String, dynamic>>[];

    if (fm.sourceRulesCount > 0) {
      stats.add({
        'title': 'Source Rules',
        'value': fm.sourceRulesCount.toString(),
        'icon': CupertinoIcons.doc_text,
        'color': Colors.orange,
      });
    }

    if (fm.lastRuleCount > 0) {
      stats.add({
        'title': 'Safari Rules',
        'value': fm.lastRuleCount.toString(),
        'icon': CupertinoIcons.shield_lefthalf_fill,
        'color': Colors.blue,
      });
    }

    if (fm.lastConversionTime != 'N/A') {
      stats.add({
        'title': 'Conversion',
        'value': fm.lastConversionTime,
        'icon': CupertinoIcons.clock,
        'color': Colors.green,
      });
    }

    if (fm.lastReloadTime != 'N/A') {
      stats.add({
        'title': 'Reload',
        'value': fm.lastReloadTime,
        'icon': CupertinoIcons.arrow_clockwise,
        'color': Colors.purple,
      });
    }

    return stats;
  }

  List<Map<String, dynamic>> _buildCategoryStatistics() {
    final fm = widget.filterManager;
    final stats = <Map<String, dynamic>>[];

    // Sort categories alphabetically
    final sortedCategories = fm.ruleCountsByCategory.keys.toList()..sort();

    for (final category in sortedCategories) {
      // Skip "all" category
      if (category.toLowerCase() == 'all') continue;

      final ruleCount = fm.ruleCountsByCategory[category] ?? 0;
      final showWarning = fm.categoriesApproachingLimit.contains(category);

      stats.add({
        'title': category,
        'value': ruleCount.toString(),
        'icon': _getCategoryIcon(category),
        'color': _getCategoryColor(category),
        'showWarning': showWarning,
      });
    }

    return stats;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ads':
        return CupertinoIcons.projective;
      case 'privacy':
      case 'trackers':
        return CupertinoIcons.eye_slash;
      case 'security':
        return CupertinoIcons.shield;
      case 'multipurpose':
        return CupertinoIcons.square_grid_2x2;
      case 'annoyances':
        return CupertinoIcons.hand_raised;
      case 'experimental':
        return Platform.isIOS ? CupertinoIcons.lab_flask : Icons.science;
      case 'foreign':
      case 'regional':
        return CupertinoIcons.globe;
      case 'custom':
        return CupertinoIcons.gear;
      default:
        return CupertinoIcons.list_bullet;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ads':
        return Colors.red;
      case 'privacy':
        return Colors.indigo;
      case 'trackers':
        return Colors.blue;
      case 'security':
        return Colors.green;
      case 'multipurpose':
        return Colors.orange;
      case 'annoyances':
        return Colors.purple;
      case 'experimental':
        return Colors.yellow;
      case 'foreign':
      case 'regional':
        return Colors.teal;
      case 'custom':
        return Colors.grey;
      default:
        return Platform.isIOS ? CupertinoColors.label : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }
  }

  Widget _buildStatisticsSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required List<Map<String, dynamic>> statistics,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Platform.isIOS ? CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.5) : Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: statistics
                .map((stat) => _buildStatCard(
                      context: context,
                      title: stat['title'] as String,
                      value: stat['value'] as String,
                      icon: stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      showWarning: stat['showWarning'] as bool? ?? false,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool showWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Platform.isIOS ? CupertinoColors.systemBackground.resolveFrom(context) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(icon, color: color, size: 24),
              if (showWarning)
                const Positioned(
                  right: -8,
                  top: -8,
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.yellow,
                    size: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Platform.isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
