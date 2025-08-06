import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/whitelist_view_model.dart';
import 'package:flutter_wblock_plugin_example/views/logs_view.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_view.dart';
import 'package:flutter_wblock_plugin_example/views/user_script_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/apply_changes_progress_view.dart';
import 'package:flutter_wblock_plugin_example/views/missing_filters_view.dart';
import 'package:flutter_wblock_plugin_example/views/update_popup_view.dart';
import 'package:flutter_wblock_plugin_example/views/stat_card.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/theme/theme_constants.dart';
import 'dart:io';

class ContentView extends StatefulWidget {
  final AppFilterManager filterManager;
  final UserScriptManager userScriptManager;

  const ContentView({
    super.key,
    required this.filterManager,
    required this.userScriptManager,
  });

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  bool _showOnlyEnabledLists = false;
  late WhitelistViewModel _whitelistViewModel;

  int get enabledListsCount => widget.filterManager.filterLists.where((f) => f.isSelected).length;

  List<FilterListCategory> get displayableCategories =>
      FilterListCategory.values.where((c) => c != FilterListCategory.all && c != FilterListCategory.custom).toList();

  @override
  void initState() {
    super.initState();
    _whitelistViewModel = WhitelistViewModel();

    // Set the UserScriptManager for filter updates
    widget.filterManager.setUserScriptManager(widget.userScriptManager);

    // Listen to filter manager changes to show sheets
    widget.filterManager.addListener(_handleFilterManagerChanges);
  }

  @override
  void dispose() {
    widget.filterManager.removeListener(_handleFilterManagerChanges);
    super.dispose();
  }

  void _handleFilterManagerChanges() {
    if (widget.filterManager.showingUpdatePopup) {
      _showUpdatePopup();
    }
    if (widget.filterManager.showMissingFiltersSheet) {
      _showMissingFiltersSheet();
    }
    if (widget.filterManager.showingApplyProgressSheet) {
      _showApplyProgressSheet();
    }
    if (widget.filterManager.showingNoUpdatesAlert) {
      _showNoUpdatesAlert();
    }
    if (widget.filterManager.showingDownloadCompleteAlert) {
      _showDownloadCompleteAlert();
    }
    if (widget.filterManager.showingCategoryWarningAlert) {
      _showCategoryWarningAlert();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return _buildMacOSView();
    } else {
      return _buildIOSView();
    }
  }

  Widget _buildMacOSView() {
    return MacosWindow(
      child: MacosScaffold(
        backgroundColor: WBlockTheme.macOSBackgroundColor,
        toolBar: ToolBar(
          title: const Text('wBlock'),
          titleWidth: 150.0,
          leading: MacosIcon(
            CupertinoIcons.shield_lefthalf_fill,
            color: MacosTheme.brightnessOf(context).resolve(
              const Color.fromRGBO(0, 0, 0, 0.5),
              const Color.fromRGBO(255, 255, 255, 0.5),
            ),
            size: 20.0,
          ),
          actions: [
            ToolBarIconButton(
              label: 'Check for Updates',
              icon: const MacosIcon(CupertinoIcons.arrow_clockwise),
              onPressed: widget.filterManager.isLoading ? null : () => widget.filterManager.checkForUpdates(),
              tooltipMessage: 'Check for filter list updates',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Apply Changes',
              icon: const MacosIcon(CupertinoIcons.arrow_2_circlepath),
              onPressed: widget.filterManager.isLoading || enabledListsCount == 0 ? null : () => widget.filterManager.checkAndEnableFilters(forceReload: true),
              tooltipMessage: 'Apply selected filters and reload Safari',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Show Logs',
              icon: const MacosIcon(CupertinoIcons.doc_text_search),
              onPressed: _showLogsView,
              tooltipMessage: 'View application logs',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'User Scripts',
              icon: const MacosIcon(CupertinoIcons.doc_text_fill),
              onPressed: _showUserScriptsView,
              tooltipMessage: 'Manage userscripts',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Whitelisted Domains',
              icon: const MacosIcon(CupertinoIcons.list_bullet_indent),
              onPressed: _showWhitelistSheet,
              tooltipMessage: 'Configure whitelisted domains',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Add Filter',
              icon: const MacosIcon(CupertinoIcons.plus),
              onPressed: _showAddFilterSheet,
              tooltipMessage: 'Add custom filter list from URL',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Show Enabled Only',
              icon: MacosIcon(_showOnlyEnabledLists ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease_circle),
              onPressed: () => setState(() => _showOnlyEnabledLists = !_showOnlyEnabledLists),
              tooltipMessage: 'Toggle to show only enabled filter lists',
              showLabel: false,
            ),
          ],
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) => Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCardsView(),
                      const SizedBox(height: 20),
                      ..._buildFilterSections(),
                    ],
                  ),
                ),
                if (widget.filterManager.isLoading &&
                    !widget.filterManager.showingApplyProgressSheet &&
                    !widget.filterManager.showMissingFiltersSheet &&
                    !widget.filterManager.showingUpdatePopup)
                  _buildLoadingOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFilterSheet() {
    showMacosSheet(
      context: context,
      builder: (context) => AddFilterListView(filterManager: widget.filterManager),
    );
  }

  void _showLogsView() {
    showMacosSheet(
      context: context,
      builder: (context) => LogsView(onDismiss: () => Navigator.of(context).pop()),
    );
  }

  void _showUserScriptsView() {
    showMacosSheet(
      context: context,
      builder: (context) => UserScriptManagerView(
        userScriptManager: widget.userScriptManager,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showWhitelistSheet() {
    showMacosSheet(
      context: context,
      builder: (context) => WhitelistManagerView(
        filterManager: widget.filterManager,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showUpdatePopup() {
    showMacosSheet(
      context: context,
      builder: (context) => UpdatePopupView(
        filterManager: widget.filterManager,
        userScriptManager: widget.userScriptManager,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      widget.filterManager.showingUpdatePopup = false;
    });
  }

  void _showMissingFiltersSheet() {
    showMacosSheet(
      context: context,
      builder: (context) => MissingFiltersView(
        filterManager: widget.filterManager,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      widget.filterManager.showMissingFiltersSheet = false;
    });
  }

  void _showApplyProgressSheet() {
    showMacosSheet(
      context: context,
      builder: (context) => ApplyChangesProgressView(
        filterManager: widget.filterManager,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      widget.filterManager.showingApplyProgressSheet = false;
    });
  }

  void _showNoUpdatesAlert() {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.info_circle),
        title: const Text('No Updates Found'),
        message: const Text('All your filters and userscripts are up to date.'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      widget.filterManager.showingNoUpdatesAlert = false;
    });
  }

  void _showDownloadCompleteAlert() {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.checkmark_circle),
        title: const Text('Download Complete'),
        message: Text(widget.filterManager.downloadCompleteMessage),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosTheme.of(context).primaryColor,
          child: const Text('Apply Now'),
          onPressed: () {
            Navigator.of(context).pop();
            widget.filterManager.applyDownloadedChanges();
          },
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          child: const Text('Later'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      widget.filterManager.showingDownloadCompleteAlert = false;
    });
  }

  void _showCategoryWarningAlert() {
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
        title: const Text('Category Rule Limit Warning'),
        message: Text(widget.filterManager.categoryWarningMessage),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      widget.filterManager.showingCategoryWarningAlert = false;
    });
  }

  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('wBlock'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.filterManager.isLoading ? null : () => widget.filterManager.checkForUpdates(),
                      child: const Icon(CupertinoIcons.arrow_clockwise),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          widget.filterManager.isLoading || enabledListsCount == 0 ? null : () => widget.filterManager.checkAndEnableFilters(forceReload: true),
                      child: const Icon(CupertinoIcons.arrow_2_circlepath),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showLogsViewIOS,
                      child: const Icon(CupertinoIcons.doc_text_search),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showUserScriptsViewIOS,
                      child: const Icon(CupertinoIcons.doc_text_fill),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddFilterSheetIOS,
                      child: const Icon(CupertinoIcons.plus),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showWhitelistSheetIOS,
                      child: const Icon(CupertinoIcons.list_bullet_indent),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatsCardsViewIOS(),
                      const SizedBox(height: 20),
                      ..._buildFilterSectionsIOS(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.filterManager.isLoading &&
              !widget.filterManager.showingApplyProgressSheet &&
              !widget.filterManager.showMissingFiltersSheet &&
              !widget.filterManager.showingUpdatePopup)
            _buildLoadingOverlayIOS(),
        ],
      ),
    );
  }

  Widget _buildStatsCardsView() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Enabled Lists',
            value: '$enabledListsCount',
            icon: 'list.bullet.rectangle',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: MacosTheme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Safari Rules',
            value: widget.filterManager.lastRuleCount.toString(),
            icon: 'shield.lefthalf.filled',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: MacosTheme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterSections() {
    final sections = <Widget>[];

    for (final category in displayableCategories) {
      final lists = _listsForCategory(category);
      if (lists.isNotEmpty) {
        sections.add(_buildFilterSectionView(category, lists));
        sections.add(const SizedBox(height: 16));
      }
    }

    final customLists = _customLists;
    if (customLists.isNotEmpty) {
      sections.add(_buildFilterSectionView(FilterListCategory.custom, customLists));
    }

    return sections;
  }

  List<FilterList> _listsForCategory(FilterListCategory category) {
    return widget.filterManager.filterLists.where((f) => f.category == category && (!_showOnlyEnabledLists || f.isSelected)).toList();
  }

  List<FilterList> get _customLists {
    return widget.filterManager.filterLists.where((f) => f.category == FilterListCategory.custom && (!_showOnlyEnabledLists || f.isSelected)).toList();
  }

  Widget _buildFilterSectionView(FilterListCategory category, List<FilterList> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.displayName,
              style: MacosTheme.of(context).typography.headline,
            ),
            FutureBuilder<bool>(
              future: Future.value(widget.filterManager.isCategoryApproachingLimit(category)),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Row(
                    children: [
                      const SizedBox(width: 8),
                      MacosIconButton(
                        icon: const MacosIcon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.systemOrange,
                          size: 16,
                        ),
                        onPressed: () => widget.filterManager.showCategoryWarning(category),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: WBlockTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: WBlockTheme.dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: filters.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              return Column(
                children: [
                  _buildFilterRowView(filter),
                  if (index < filters.length - 1)
                    Divider(
                      height: 1,
                      color: WBlockTheme.dividerColor,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRowView(FilterList filter) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.name,
                  style: MacosTheme.of(context).typography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                FilterRuleCountText(
                  filter: filter,
                  filterManager: widget.filterManager,
                ),
                if (filter.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    filter.description,
                    style: MacosTheme.of(context).typography.caption1.copyWith(
                          color: MacosTheme.of(context).typography.caption1.color?.withOpacity(0.6),
                        ),
                  ),
                ],
                if (filter.version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Version: ${filter.version}',
                    style: MacosTheme.of(context).typography.caption2.copyWith(
                          color: MacosTheme.of(context).typography.caption2.color?.withOpacity(0.5),
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          MacosSwitch(
            value: filter.isSelected,
            onChanged: (value) => widget.filterManager.toggleFilterListSelection(filter.id),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: WBlockTheme.overlayColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WBlockTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              WBlockTheme.getCardShadow(),
              BoxShadow(
                color: WBlockTheme.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ProgressCircle(
                value: null,
                radius: 24,
              ),
              const SizedBox(height: 10),
              Text(
                widget.filterManager.statusDescription,
                style: MacosTheme.of(context).typography.body.copyWith(
                      color: MacosTheme.of(context).typography.body.color?.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // iOS-specific methods
  void _showAddFilterSheetIOS() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddFilterListViewIOS(filterManager: widget.filterManager),
    );
  }

  void _showLogsViewIOS() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => LogsView(onDismiss: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _showUserScriptsViewIOS() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => UserScriptManagerView(
          userScriptManager: widget.userScriptManager,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showWhitelistSheetIOS() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => WhitelistView(
          viewModel: _whitelistViewModel,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildStatsCardsViewIOS() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Enabled Lists',
            value: '$enabledListsCount',
            icon: 'list.bullet.rectangle',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: CupertinoTheme.of(context).primaryColor ?? CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Safari Rules',
            value: widget.filterManager.lastRuleCount.toString(),
            icon: 'shield.lefthalf.filled',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: CupertinoTheme.of(context).primaryColor ?? CupertinoColors.activeBlue,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterSectionsIOS() {
    final sections = <Widget>[];

    for (final category in displayableCategories) {
      final lists = _listsForCategory(category);
      if (lists.isNotEmpty) {
        sections.add(_buildFilterSectionViewIOS(category, lists));
        sections.add(const SizedBox(height: 16));
      }
    }

    final customLists = _customLists;
    if (customLists.isNotEmpty) {
      sections.add(_buildFilterSectionViewIOS(FilterListCategory.custom, customLists));
    }

    return sections;
  }

  Widget _buildFilterSectionViewIOS(FilterListCategory category, List<FilterList> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.displayName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            FutureBuilder<bool>(
              future: Future.value(widget.filterManager.isCategoryApproachingLimit(category)),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Row(
                    children: [
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => widget.filterManager.showCategoryWarning(category),
                        child: const Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.systemOrange,
                          size: 16,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).barBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: filters.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              return Column(
                children: [
                  _buildFilterRowViewIOS(filter),
                  if (index < filters.length - 1)
                    Container(
                      height: 0.5,
                      color: CupertinoColors.separator,
                      margin: const EdgeInsets.only(left: 16),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRowViewIOS(FilterList filter) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FilterRuleCountText(
                  filter: filter,
                  filterManager: widget.filterManager,
                  isIOS: true,
                ),
                if (filter.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    filter.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
                if (filter.version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Version: ${filter.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: filter.isSelected,
            onChanged: (value) => widget.filterManager.toggleFilterListSelection(filter.id),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlayIOS() {
    return Container(
      color: CupertinoColors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).barBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(
                radius: 20,
              ),
              const SizedBox(height: 10),
              Text(
                widget.filterManager.statusDescription,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate widget to handle async filter file exists check
class FilterRuleCountText extends StatefulWidget {
  final FilterList filter;
  final AppFilterManager filterManager;
  final bool isIOS;

  const FilterRuleCountText({
    super.key,
    required this.filter,
    required this.filterManager,
    this.isIOS = false,
  });

  @override
  State<FilterRuleCountText> createState() => _FilterRuleCountTextState();
}

class _FilterRuleCountTextState extends State<FilterRuleCountText> {
  bool? _filterFileExists;

  @override
  void initState() {
    super.initState();
    _checkFilterFileExists();
  }

  @override
  void didUpdateWidget(FilterRuleCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.id != widget.filter.id) {
      _checkFilterFileExists();
    }
  }

  Future<void> _checkFilterFileExists() async {
    if (widget.filter.sourceRuleCount == null && widget.filter.isSelected) {
      final exists = await widget.filterManager.doesFilterFileExist(widget.filter);
      if (mounted) {
        setState(() {
          _filterFileExists = exists;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filter.sourceRuleCount != null && widget.filter.sourceRuleCount! > 0) {
      return Text(
        '(${widget.filter.sourceRuleCount} rules)',
        style: TextStyle(
          fontSize: widget.isIOS ? 13 : 12,
          color: widget.isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : MacosTheme.of(context).typography.caption1.color?.withOpacity(0.6),
        ),
      );
    } else if (widget.filter.sourceRuleCount == null && widget.filter.isSelected && _filterFileExists == false) {
      return Text(
        '(Counting...)',
        style: TextStyle(
          fontSize: widget.isIOS ? 13 : 12,
          color: CupertinoColors.systemOrange,
        ),
      );
    } else {
      return Text(
        '(N/A rules)',
        style: TextStyle(
          fontSize: widget.isIOS ? 13 : 12,
          color: widget.isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : MacosTheme.of(context).typography.caption1.color?.withOpacity(0.6),
        ),
      );
    }
  }
}

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
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _showErrorAlert = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Custom Filter List',
              style: MacosTheme.of(context).typography.title3,
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Name (Optional):',
              style: MacosTheme.of(context).typography.caption1,
            ),
            const SizedBox(height: 4),
            MacosTextField(
              controller: _nameController,
              placeholder: 'e.g., My Ad Block List',
            ),
            const SizedBox(height: 16),
            Text(
              'Filter URL:',
              style: MacosTheme.of(context).typography.caption1,
            ),
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
                  color: MacosTheme.of(context).primaryColor,
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

  void _validateAndAdd() {
    final trimmedURL = _urlController.text.trim();

    if (trimmedURL.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(trimmedURL);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      setState(() {
        _errorMessage = 'The URL entered is not valid. Please enter a complete and correct URL (e.g., http:// or https://).';
        _showErrorAlert = true;
      });
      return;
    }

    if (widget.filterManager.filterLists.any((f) => f.url.toString() == trimmedURL)) {
      setState(() {
        _errorMessage = 'A filter list with this URL already exists.';
        _showErrorAlert = true;
      });
      return;
    }

    widget.filterManager.addFilterList(
      name: _nameController.text.trim(),
      urlString: trimmedURL,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}

class AddFilterListViewIOS extends StatefulWidget {
  final AppFilterManager filterManager;

  const AddFilterListViewIOS({
    super.key,
    required this.filterManager,
  });

  @override
  State<AddFilterListViewIOS> createState() => _AddFilterListViewIOSState();
}

class _AddFilterListViewIOSState extends State<AddFilterListViewIOS> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final trimmedURL = _urlController.text.trim();

    if (trimmedURL.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(trimmedURL);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      _showError('The URL entered is not valid. Please enter a complete and correct URL (e.g., http:// or https://).');
      return;
    }

    if (widget.filterManager.filterLists.any((f) => f.url.toString() == trimmedURL)) {
      _showError('A filter list with this URL already exists.');
      return;
    }

    widget.filterManager.addFilterList(
      name: _nameController.text.trim(),
      urlString: trimmedURL,
    );
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Invalid Input'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
                  const Text(
                    'Filter Name (Optional):',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'e.g., My Ad Block List',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Filter URL:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _urlController,
                    placeholder: 'https://example.com/filter.txt',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
