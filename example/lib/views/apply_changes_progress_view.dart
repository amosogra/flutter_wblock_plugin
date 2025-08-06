import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class ApplyChangesProgressView extends ConsumerStatefulWidget {
  final AppFilterManager filterManager;
  final VoidCallback onDismiss;

  const ApplyChangesProgressView({
    super.key,
    required this.filterManager,
    required this.onDismiss,
  });

  @override
  ConsumerState<ApplyChangesProgressView> createState() => _ApplyChangesProgressViewState();
}

class _ApplyChangesProgressViewState extends ConsumerState<ApplyChangesProgressView> {
  List<FilterList> get selectedFilters => 
      widget.filterManager.filterLists.where((f) => f.isSelected).toList();

  int get progressPercentage => (widget.filterManager.progress * 100).round().clamp(0, 100);

  String get titleText {
    if (widget.filterManager.progress >= 1.0 && !widget.filterManager.isLoading) {
      return 'Filter Lists Applied';
    } else {
      return 'Converting Filter Lists';
    }
  }

  bool get hasStatistics => 
      widget.filterManager.lastRuleCount > 0 || 
      widget.filterManager.ruleCountsByCategory.isNotEmpty;

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
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 400,
          ),
          child: AppTheme.ultraThinMaterial(
            child: _buildContent(),
          ),
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 300,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (widget.filterManager.isLoading || hasStatistics)
          _buildHeader(),
        Expanded(
          child: widget.filterManager.isLoading
              ? _buildPhaseIndicators()
              : hasStatistics
                  ? _buildStatistics()
                  : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    titleText,
                    style: AppTheme.headline.copyWith(fontSize: 18),
                  ),
                ),
              ),
              if (!widget.filterManager.isLoading && widget.filterManager.progress >= 1.0)
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
          if (widget.filterManager.isLoading && 
              widget.filterManager.conversionStageDescription.isNotEmpty &&
              widget.filterManager.conversionStageDescription != titleText) ...[
            const SizedBox(height: 8),
            Text(
              widget.filterManager.conversionStageDescription,
              textAlign: TextAlign.center,
              style: AppTheme.caption,
              maxLines: 2,
            ),
          ],
          if (widget.filterManager.isLoading) ...[
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: widget.filterManager.progress,
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

  Widget _buildPhaseIndicators() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: _phaseData.map((phase) => _buildPhaseRow(phase)).toList(),
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

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStatistics(),
          if (widget.filterManager.ruleCountsByCategory.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCategoryStatistics(),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallStatistics() {
    final overallStats = _buildOverallStatisticsData();
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

  Widget _buildCategoryStatistics() {
    final categoryStats = _buildCategoryStatisticsData();
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

  List<PhaseData> get _phaseData {
    return [
      PhaseData(
        icon: 'folder.badge.questionmark',
        title: 'Reading Files',
        detail: widget.filterManager.totalFiltersCount > 0 
          ? '${widget.filterManager.processedFiltersCount}/${widget.filterManager.totalFiltersCount} extensions'
          : null,
        isActive: widget.filterManager.processedFiltersCount < widget.filterManager.totalFiltersCount && 
                 !widget.filterManager.isInConversionPhase,
        isCompleted: widget.filterManager.processedFiltersCount >= widget.filterManager.totalFiltersCount || 
                    widget.filterManager.progress > 0.6,
      ),
      PhaseData(
        icon: 'gearshape.2',
        title: 'Converting Rules',
        detail: widget.filterManager.currentFilterName.isEmpty 
          ? null 
          : 'Processing ${widget.filterManager.currentFilterName}',
        isActive: widget.filterManager.isInConversionPhase,
        isCompleted: widget.filterManager.progress > 0.75,
      ),
      PhaseData(
        icon: 'square.and.arrow.down',
        title: 'Saving & Building',
        detail: (widget.filterManager.isInSavingPhase || widget.filterManager.isInEnginePhase || 
                (widget.filterManager.progress > 0.7 && widget.filterManager.progress < 0.95))
          ? 'Writing files and building engines'
          : null,
        isActive: widget.filterManager.isInSavingPhase || widget.filterManager.isInEnginePhase || 
                 (widget.filterManager.progress > 0.7 && widget.filterManager.progress < 0.95),
        isCompleted: widget.filterManager.progress > 0.9,
      ),
      PhaseData(
        icon: 'arrow.clockwise',
        title: 'Reloading Extensions',
        detail: widget.filterManager.isInReloadPhase && widget.filterManager.currentFilterName.isNotEmpty
          ? 'Reloading ${widget.filterManager.currentFilterName}'
          : null,
        isActive: widget.filterManager.isInReloadPhase,
        isCompleted: widget.filterManager.progress >= 1.0,
      ),
    ];
  }

  List<StatisticData> _buildOverallStatisticsData() {
    final stats = <StatisticData>[];
    
    if (widget.filterManager.sourceRulesCount > 0) {
      stats.add(StatisticData(
        title: 'Source Rules',
        value: _formatNumber(widget.filterManager.sourceRulesCount),
        icon: 'doc.text',
        color: CupertinoColors.systemOrange,
      ));
    }
    
    if (widget.filterManager.lastRuleCount > 0) {
      stats.add(StatisticData(
        title: 'Safari Rules',
        value: _formatNumber(widget.filterManager.lastRuleCount),
        icon: 'shield.lefthalf.filled',
        color: AppTheme.primaryColor,
      ));
    }
    
    if (widget.filterManager.lastConversionTime != 'N/A') {
      stats.add(StatisticData(
        title: 'Conversion',
        value: widget.filterManager.lastConversionTime,
        icon: 'clock',
        color: CupertinoColors.systemGreen,
      ));
    }
    
    if (widget.filterManager.lastReloadTime != 'N/A') {
      stats.add(StatisticData(
        title: 'Reload',
        value: widget.filterManager.lastReloadTime,
        icon: 'arrow.clockwise',
        color: CupertinoColors.systemPurple,
      ));
    }
    
    return stats;
  }

  List<StatisticData> _buildCategoryStatisticsData() {
    final stats = <StatisticData>[];
    
    final sortedCategories = widget.filterManager.ruleCountsByCategory.keys
        .where((category) => category != FilterListCategory.all)
        .toList()
      ..sort((a, b) => a.rawValue.compareTo(b.rawValue));
    
    for (final category in sortedCategories) {
      final ruleCount = widget.filterManager.ruleCountsByCategory[category];
      if (ruleCount != null) {
        final showWarning = widget.filterManager.categoriesApproachingLimit.contains(category);
        stats.add(StatisticData(
          title: category.rawValue,
          value: _formatNumber(ruleCount),
          icon: _getCategoryIcon(category),
          color: _getCategoryColor(category),
          showWarning: showWarning,
        ));
      }
    }
    
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
