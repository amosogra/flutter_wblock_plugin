import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class ApplyChangesProgressView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const ApplyChangesProgressView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<ApplyChangesProgressView> createState() => _ApplyChangesProgressViewState();
}

class _ApplyChangesProgressViewState extends ConsumerState<ApplyChangesProgressView> {
  @override
  Widget build(BuildContext context) {
    final filterManager = ref.watch(appFilterManagerProvider);
    
    //final selectedFilters = filterManager.filterLists.where((f) => f.isSelected).toList();
    final progressPercentage = (filterManager.progress * 100).round().clamp(0, 100);

    String titleText;
    if (filterManager.progress >= 1.0 && !filterManager.isLoading) {
      titleText = 'Filter Lists Applied';
    } else {
      titleText = 'Converting Filter Lists';
    }

    final hasStatistics = filterManager.lastRuleCount > 0 || 
        filterManager.ruleCountsByCategory.isNotEmpty;

    if (Platform.isMacOS) {
      return _buildMacOSView(filterManager, titleText, hasStatistics, progressPercentage);
    } else {
      return _buildIOSView(filterManager, titleText, hasStatistics, progressPercentage);
    }
  }

  Widget _buildMacOSView(filterManager, String titleText, bool hasStatistics, int progressPercentage) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 400,
          ),
          child: AppTheme.ultraThinMaterial(
            child: _buildContent(filterManager, titleText, hasStatistics, progressPercentage),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView(filterManager, String titleText, bool hasStatistics, int progressPercentage) {
    return Container(
      color: CupertinoColors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 300,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildContent(filterManager, titleText, hasStatistics, progressPercentage),
        ),
      ),
    );
  }

  Widget _buildContent(filterManager, String titleText, bool hasStatistics, int progressPercentage) {
    return Column(
      children: [
        // Always show header
        _buildHeader(filterManager, titleText, progressPercentage),
        Expanded(
          child: filterManager.isLoading
              ? _buildPhaseIndicators(filterManager)
              : _buildStatistics(filterManager), // Always show statistics view (it handles empty state)
        ),
      ],
    );
  }

  Widget _buildHeader(filterManager, String titleText, int progressPercentage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 24), // Balance the close button
              Expanded(
                child: Center(
                  child: Text(
                    titleText,
                    style: AppTheme.headline.copyWith(fontSize: 18),
                  ),
                ),
              ),
              // Always show dismiss button
              Platform.isMacOS
                ? MacosIconButton(
                    icon: const MacosIcon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 24,
                    ),
                    onPressed: widget.onDismiss,
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.onDismiss,
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppTheme.secondaryLabel,
                      size: 24,
                    ),
                  ),
            ],
          ),
          if (filterManager.isLoading && 
              filterManager.conversionStageDescription.isNotEmpty &&
              filterManager.conversionStageDescription != titleText) ...[
            const SizedBox(height: 8),
            Text(
              filterManager.conversionStageDescription,
              textAlign: TextAlign.center,
              style: AppTheme.caption,
              maxLines: 2,
            ),
          ],
          if (filterManager.isLoading) ...[
            const SizedBox(height: 16),
            _buildProgressBar(filterManager, progressPercentage),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(filterManager, int progressPercentage) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: filterManager.progress,
          backgroundColor: AppTheme.dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          minHeight: 3,
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

  Widget _buildPhaseIndicators(filterManager) {
    final phaseData = _getPhaseData(filterManager);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: phaseData.map((phase) => _buildPhaseRow(phase)).toList(),
        ),
      ),
    );
  }

  Widget _buildPhaseRow(PhaseData phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Icon(
            _getPhaseIcon(phase.icon),
            color: phase.isCompleted 
              ? CupertinoColors.systemGreen 
              : phase.isActive 
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
                  phase.title,
                  style: AppTheme.body.copyWith(
                    fontWeight: phase.isActive ? FontWeight.w500 : FontWeight.normal,
                    color: phase.isCompleted 
                      ? CupertinoColors.systemGreen 
                      : phase.isActive 
                        ? CupertinoColors.label
                        : AppTheme.secondaryLabel,
                  ),
                ),
                if (phase.detail != null && phase.detail!.isNotEmpty)
                  Text(
                    phase.detail!,
                    style: AppTheme.caption,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 16,
            height: 16,
            child: phase.isCompleted
              ? const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.systemGreen,
                  size: 16,
                )
              : phase.isActive
                ? (Platform.isMacOS 
                    ? const ProgressCircle(value: null, radius: 8) 
                    : const CupertinoActivityIndicator(radius: 8))
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(filterManager) {
    final hasOverallStats = filterManager.sourceRulesCount > 0 || 
                           filterManager.lastRuleCount > 0 || 
                           filterManager.lastConversionTime != 'N/A' || 
                           filterManager.lastReloadTime != 'N/A';
    final hasCategoryStats = filterManager.ruleCountsByCategory != null && 
                             filterManager.ruleCountsByCategory.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOverallStats) _buildOverallStatistics(filterManager),
          if (hasOverallStats && hasCategoryStats) const SizedBox(height: 20),
          if (hasCategoryStats) _buildCategoryStatistics(filterManager),
          if (!hasOverallStats && !hasCategoryStats) 
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 48,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filters Applied Successfully',
                    style: AppTheme.headline,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverallStatistics(filterManager) {
    final overallStats = _buildOverallStatisticsData(filterManager);
    if (overallStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Overall Statistics',
              style: AppTheme.headline,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatisticsGrid(overallStats),
      ],
    );
  }

  Widget _buildCategoryStatistics(filterManager) {
    final categoryStats = _buildCategoryStatisticsData(filterManager);
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.square_grid_2x2,
              color: CupertinoColors.systemOrange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Category Statistics',
              style: AppTheme.headline,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatisticsGrid(categoryStats),
      ],
    );
  }

  Widget _buildStatisticsGrid(List<StatisticData> stats) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatisticCard(stats[index]),
    );
  }

  Widget _buildStatisticCard(StatisticData stat) {
    return AppTheme.regularMaterial(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getStatIcon(stat.icon),
                  color: stat.color,
                  size: 20,
                ),
                if (stat.showWarning)
                  const Positioned(
                    top: -4,
                    right: -4,
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: CupertinoColors.systemYellow,
                      size: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                stat.value,
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                stat.title,
                style: AppTheme.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PhaseData> _getPhaseData(filterManager) {
    return [
      PhaseData(
        icon: 'folder.badge.questionmark',
        title: 'Reading Files',
        detail: filterManager.totalFiltersCount > 0 
          ? '${filterManager.processedFiltersCount}/${filterManager.totalFiltersCount} extensions'
          : null,
        isActive: filterManager.processedFiltersCount < filterManager.totalFiltersCount && 
                 !filterManager.isInConversionPhase,
        isCompleted: filterManager.processedFiltersCount >= filterManager.totalFiltersCount || 
                    filterManager.progress > 0.6,
      ),
      PhaseData(
        icon: 'gearshape.2',
        title: 'Converting Rules',
        detail: filterManager.currentFilterName.isEmpty 
          ? null 
          : 'Processing ${filterManager.currentFilterName}',
        isActive: filterManager.isInConversionPhase,
        isCompleted: filterManager.progress > 0.75,
      ),
      PhaseData(
        icon: 'square.and.arrow.down',
        title: 'Saving & Building',
        detail: (filterManager.isInSavingPhase || filterManager.isInEnginePhase || 
                (filterManager.progress > 0.7 && filterManager.progress < 0.95))
          ? 'Writing files and building engines'
          : null,
        isActive: filterManager.isInSavingPhase || filterManager.isInEnginePhase || 
                 (filterManager.progress > 0.7 && filterManager.progress < 0.95),
        isCompleted: filterManager.progress > 0.9,
      ),
      PhaseData(
        icon: 'arrow.clockwise',
        title: 'Reloading Extensions',
        detail: filterManager.isInReloadPhase && filterManager.currentFilterName.isNotEmpty
          ? 'Reloading ${filterManager.currentFilterName}'
          : null,
        isActive: filterManager.isInReloadPhase,
        isCompleted: filterManager.progress >= 1.0,
      ),
    ];
  }

  List<StatisticData> _buildOverallStatisticsData(filterManager) {
    final stats = <StatisticData>[];
    
    if (filterManager.sourceRulesCount > 0) {
      stats.add(StatisticData(
        title: 'Source Rules',
        value: _formatNumber(filterManager.sourceRulesCount),
        icon: 'doc.text',
        color: CupertinoColors.systemOrange,
      ));
    }
    
    if (filterManager.lastRuleCount > 0) {
      stats.add(StatisticData(
        title: 'Safari Rules',
        value: _formatNumber(filterManager.lastRuleCount),
        icon: 'shield.lefthalf.filled',
        color: AppTheme.primaryColor,
      ));
    }
    
    if (filterManager.lastConversionTime != 'N/A') {
      stats.add(StatisticData(
        title: 'Conversion',
        value: filterManager.lastConversionTime,
        icon: 'clock',
        color: CupertinoColors.systemGreen,
      ));
    }
    
    if (filterManager.lastReloadTime != 'N/A') {
      stats.add(StatisticData(
        title: 'Reload',
        value: filterManager.lastReloadTime,
        icon: 'arrow.clockwise',
        color: CupertinoColors.systemPurple,
      ));
    }
    
    return stats;
  }

  List<StatisticData> _buildCategoryStatisticsData(filterManager) {
    final stats = <StatisticData>[];
    
    if (filterManager.ruleCountsByCategory == null || filterManager.ruleCountsByCategory.isEmpty) {
      // Debug: log what we have
      debugPrint('No category statistics available');
      return stats;
    }
    
    final Map<FilterListCategory, int> categoryRules = filterManager.ruleCountsByCategory;
    debugPrint('Category rules count: ${categoryRules.length}');
    
    final categories = categoryRules.keys
        .where((category) => category != FilterListCategory.all && categoryRules[category] != null && categoryRules[category]! > 0)
        .toList();
    
    if (categories.isEmpty) {
      debugPrint('No valid categories with rules');
      return stats;
    }
    
    categories.sort((FilterListCategory a, FilterListCategory b) => 
        a.rawValue.compareTo(b.rawValue));
    
    for (final category in categories) {
      final ruleCount = categoryRules[category];
      if (ruleCount != null && ruleCount > 0) {
        final showWarning = filterManager.categoriesApproachingLimit?.contains(category) ?? false;
        stats.add(StatisticData(
          title: category.displayName, // Use displayName instead of rawValue
          value: _formatNumber(ruleCount),
          icon: _getCategoryIcon(category),
          color: _getCategoryColor(category),
          showWarning: showWarning,
        ));
      }
    }
    
    debugPrint('Built ${stats.length} category statistics');
    return stats;
  }

  IconData _getPhaseIcon(String systemName) {
    switch (systemName) {
      case 'folder.badge.questionmark':
        return CupertinoIcons.folder_badge_plus;
      case 'gearshape.2':
        return CupertinoIcons.gear_alt;
      case 'square.and.arrow.down':
        return CupertinoIcons.square_arrow_down;
      case 'arrow.clockwise':
        return CupertinoIcons.refresh;
      default:
        return CupertinoIcons.info;
    }
  }

  IconData _getStatIcon(String systemName) {
    switch (systemName) {
      case 'doc.text':
        return CupertinoIcons.doc_text;
      case 'shield.lefthalf.filled':
        return CupertinoIcons.shield_lefthalf_fill;
      case 'clock':
        return CupertinoIcons.clock;
      case 'arrow.clockwise':
        return CupertinoIcons.refresh;
      default:
        return CupertinoIcons.info;
    }
  }

  String _getCategoryIcon(FilterListCategory category) {
    switch (category) {
      case FilterListCategory.ads:
        return 'rectangle.slash';
      case FilterListCategory.privacy:
        return 'eye.slash';
      case FilterListCategory.security:
        return 'shield';
      case FilterListCategory.multipurpose:
        return 'square.grid.2x2';
      case FilterListCategory.annoyances:
        return 'hand.raised';
      case FilterListCategory.experimental:
        return 'flask';
      case FilterListCategory.foreign:
        return 'globe';
      case FilterListCategory.custom:
        return 'gearshape';
      default:
        return 'list.bullet';
    }
  }

  Color _getCategoryColor(FilterListCategory category) {
    switch (category) {
      case FilterListCategory.ads:
        return CupertinoColors.systemRed;
      case FilterListCategory.privacy:
        return AppTheme.primaryColor;
      case FilterListCategory.security:
        return CupertinoColors.systemGreen;
      case FilterListCategory.multipurpose:
        return CupertinoColors.systemOrange;
      case FilterListCategory.annoyances:
        return CupertinoColors.systemPurple;
      case FilterListCategory.experimental:
        return CupertinoColors.systemYellow;
      case FilterListCategory.foreign:
        return CupertinoColors.systemTeal;
      case FilterListCategory.custom:
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.label;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

class PhaseData {
  final String icon;
  final String title;
  final String? detail;
  final bool isActive;
  final bool isCompleted;

  PhaseData({
    required this.icon,
    required this.title,
    this.detail,
    required this.isActive,
    required this.isCompleted,
  });
}

class StatisticData {
  final String title;
  final String value;
  final String icon;
  final Color color;
  final bool showWarning;

  StatisticData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.showWarning = false,
  });
}
