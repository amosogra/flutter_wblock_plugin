import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_view.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'package:flutter_wblock_plugin_example/views/logs_view.dart';
import 'package:flutter_wblock_plugin_example/views/user_script_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/apply_changes_progress_view.dart';
import 'package:flutter_wblock_plugin_example/views/missing_filters_view.dart';
import 'package:flutter_wblock_plugin_example/views/update_popup_view.dart';
import 'package:flutter_wblock_plugin_example/views/add_filter_list_view.dart';
import 'package:flutter_wblock_plugin_example/views/stat_card.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'dart:io';
import 'dart:ui';

class ContentView extends ConsumerStatefulWidget {
  const ContentView({super.key});

  @override
  ConsumerState<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends ConsumerState<ContentView> {
  List<FilterListCategory> get displayableCategories =>
      FilterListCategory.values.where((c) => c != FilterListCategory.all && c != FilterListCategory.custom).toList();

  // Track which sheets/dialogs are currently showing to prevent duplicates
  bool _isShowingUpdatePopup = false;
  bool _isShowingMissingFiltersSheet = false;
  bool _isShowingApplyProgressSheet = false;
  bool _isShowingNoUpdatesAlert = false;
  bool _isShowingDownloadCompleteAlert = false;
  bool _isShowingCategoryWarningAlert = false;

  @override
  void initState() {
    super.initState();
    // Listen to filter manager changes to show sheets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filterManager = ref.read(appFilterManagerProvider);
      filterManager.addListener(_handleFilterManagerChanges);
    });
  }

  @override
  void dispose() {
    final filterManager = ref.read(appFilterManagerProvider);
    filterManager.removeListener(_handleFilterManagerChanges);
    super.dispose();
  }

  void _handleFilterManagerChanges() {
    if (!mounted) return;

    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final filterManager = ref.read(appFilterManagerProvider);

        // Only show sheets/dialogs if they're not already showing
        if (filterManager.showingUpdatePopup && !_isShowingUpdatePopup) {
          _showUpdatePopup();
        }
        if (filterManager.showMissingFiltersSheet && !_isShowingMissingFiltersSheet) {
          _showMissingFiltersSheet();
        }
        if (filterManager.showingApplyProgressSheet && !_isShowingApplyProgressSheet) {
          _showApplyProgressSheet();
        }
        if (filterManager.showingNoUpdatesAlert && !_isShowingNoUpdatesAlert) {
          _showNoUpdatesAlert();
        }
        if (filterManager.showingDownloadCompleteAlert && !_isShowingDownloadCompleteAlert) {
          _showDownloadCompleteAlert();
        }
        if (filterManager.showingCategoryWarningAlert && !_isShowingCategoryWarningAlert) {
          _showCategoryWarningAlert();
        }
      } catch (e) {
        // Silently handle if context is not available
      }
    });
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
    final filterManager = ref.watch(appFilterManagerProvider);
    final enabledListsCount = ref.watch(enabledListsCountProvider);
    final showOnlyEnabledLists = ref.watch(showOnlyEnabledListsProvider);

    return MacosWindow(
      child: MacosScaffold(
        backgroundColor: AppTheme.backgroundColor,
        toolBar: ToolBar(
          title: const Text('Syferlab'),
          titleWidth: 150.0,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withOpacity(0.94),
            border: Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
            ),
          ),
          leading: MacosIcon(
            CupertinoIcons.shield_lefthalf_fill,
            color: AppTheme.primaryColor,
            size: 20.0,
          ),
          actions: [
            ToolBarIconButton(
              label: 'Check for Updates',
              icon: const MacosIcon(CupertinoIcons.arrow_clockwise),
              onPressed: filterManager.isLoading ? null : () => filterManager.checkForUpdates(),
              tooltipMessage: 'Check for filter list updates',
              showLabel: false,
            ),
            ToolBarIconButton(
              label: 'Apply Changes',
              icon: const MacosIcon(CupertinoIcons.arrow_2_circlepath),
              onPressed: filterManager.isLoading || enabledListsCount == 0 ? null : () => filterManager.checkAndEnableFilters(forceReload: true),
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
              onPressed: _showWhitelistViewSheet,
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
              icon: MacosIcon(showOnlyEnabledLists ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease_circle),
              onPressed: () => ref.read(showOnlyEnabledListsProvider.notifier).state = !showOnlyEnabledLists,
              tooltipMessage: 'Toggle to show only enabled filter lists',
              showLabel: false,
            ),
          ],
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) => Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    //borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: SingleChildScrollView(
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
                ),
                // Only show loading overlay when actually loading and no sheet is showing
                if (filterManager.isLoading &&
                    !filterManager.showingApplyProgressSheet &&
                    !filterManager.showMissingFiltersSheet &&
                    !filterManager.showingUpdatePopup &&
                    filterManager.statusDescription.isNotEmpty)
                  _buildLoadingOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSView() {
    final filterManager = ref.watch(appFilterManagerProvider);
    final enabledListsCount = ref.watch(enabledListsCountProvider);
    final showOnlyEnabledLists = ref.watch(showOnlyEnabledListsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                backgroundColor: AppTheme.cardBackground.withOpacity(0.94),
                largeTitle: const Text('Syferlab'),
                leading: Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: AppTheme.primaryColor,
                  size: 20.0,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: filterManager.isLoading ? null : () => filterManager.checkForUpdates(),
                      child: Icon(CupertinoIcons.arrow_clockwise, color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: filterManager.isLoading || enabledListsCount == 0 ? null : () => filterManager.checkAndEnableFilters(forceReload: true),
                      child: Icon(CupertinoIcons.arrow_2_circlepath, color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showLogsViewIOS,
                      child: Icon(CupertinoIcons.doc_text_search, color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showUserScriptsViewIOS,
                      child: Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showWhitelistSheetIOS,
                      child: Icon(CupertinoIcons.list_bullet_indent, color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => ref.read(showOnlyEnabledListsProvider.notifier).state = !showOnlyEnabledLists,
                      child: Icon(showOnlyEnabledLists ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease_circle,
                          color: AppTheme.primaryColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddFilterSheetIOS,
                      child: Icon(CupertinoIcons.plus, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatsCardsView(),
                      const SizedBox(height: 20),
                      ..._buildFilterSections(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Only show loading overlay when actually loading and no sheet is showing
          if (filterManager.isLoading &&
              !filterManager.showingApplyProgressSheet &&
              !filterManager.showMissingFiltersSheet &&
              !filterManager.showingUpdatePopup &&
              filterManager.statusDescription.isNotEmpty)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildStatsCardsView() {
    final filterManager = ref.watch(appFilterManagerProvider);
    final enabledListsCount = ref.watch(enabledListsCountProvider);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Enabled Lists',
            value: '$enabledListsCount',
            icon: 'list.bullet.rectangle',
            pillColor: CupertinoColors.darkBackgroundGray.withOpacity(0.2),
            valueColor: CupertinoColors.label,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Safari Rules',
            value: filterManager.lastRuleCount.toString(),
            icon: 'shield.lefthalf.filled',
            pillColor: CupertinoColors.darkBackgroundGray.withOpacity(0.2),
            valueColor: CupertinoColors.label,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterSections() {
    final filterManager = ref.watch(appFilterManagerProvider);
    final showOnlyEnabledLists = ref.watch(showOnlyEnabledListsProvider);
    final sections = <Widget>[];

    for (final category in displayableCategories) {
      final lists = _listsForCategory(category, filterManager, showOnlyEnabledLists);
      if (lists.isNotEmpty) {
        sections.add(_buildFilterSectionView(category, lists));
        sections.add(const SizedBox(height: 16));
      }
    }

    final customLists = _customLists(filterManager, showOnlyEnabledLists);
    if (customLists.isNotEmpty) {
      sections.add(_buildFilterSectionView(FilterListCategory.custom, customLists));
    }

    return sections;
  }

  List<FilterList> _listsForCategory(FilterListCategory category, filterManager, bool showOnlyEnabledLists) {
    return filterManager.filterLists.where((f) => f.category == category && (!showOnlyEnabledLists || f.isSelected)).toList();
  }

  List<FilterList> _customLists(filterManager, bool showOnlyEnabledLists) {
    return filterManager.filterLists.where((f) => f.category == FilterListCategory.custom && (!showOnlyEnabledLists || f.isSelected)).toList();
  }

  Widget _buildFilterSectionView(FilterListCategory category, List<FilterList> filters) {
    final filterManager = ref.watch(appFilterManagerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.displayName,
              style: AppTheme.headline,
            ),
            FutureBuilder<bool>(
              future: Future.value(filterManager.isCategoryApproachingLimit(category)),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Row(
                    children: [
                      const SizedBox(width: 8),
                      Platform.isMacOS
                          ? MacosIconButton(
                              icon: const MacosIcon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemOrange,
                                size: 16,
                              ),
                              onPressed: () => filterManager.showCategoryWarning(category),
                            )
                          : CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => filterManager.showCategoryWarning(category),
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
        AppTheme.regularMaterial(
          context: context,
          child: Column(
            children: filters.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              return Column(
                children: [
                  _buildFilterRowView(filter),
                  if (index < filters.length - 1)
                    Divider(
                      height: 0.5,
                      color: AppTheme.dividerColor,
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
    final filterManager = ref.watch(appFilterManagerProvider);

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
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                FilterRuleCountText(
                  filter: filter,
                  filterManager: filterManager,
                ),
                if (filter.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    filter.description,
                    style: AppTheme.caption,
                  ),
                ],
                if (filter.version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Version: ${filter.version}',
                    style: AppTheme.caption2,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Platform.isMacOS
              ? MacosSwitch(
                  value: filter.isSelected,
                  onChanged: (value) => filterManager.toggleFilterListSelection(filter.id),
                )
              : CupertinoSwitch(
                  value: filter.isSelected,
                  onChanged: (value) => filterManager.toggleFilterListSelection(filter.id),
                ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final filterManager = ref.watch(appFilterManagerProvider);

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.cardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Platform.isMacOS ? const ProgressCircle(value: null, radius: 24) : const CupertinoActivityIndicator(radius: 20),
                  const SizedBox(height: 10),
                  Text(
                    filterManager.statusDescription,
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // macOS Sheet methods
  void _showAddFilterSheet() {
    if (!mounted) return;

    showMacosSheet(
      context: context,
      builder: (context) => const AddFilterListView(),
    );
  }

  void _showLogsView() {
    if (!mounted) return;

    showMacosSheet(
      context: context,
      builder: (context) => LogsView(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showUserScriptsView() {
    if (!mounted) return;

    showMacosSheet(
      context: context,
      builder: (context) => UserScriptManagerView(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showWhitelistViewSheet() {
    if (!mounted) return;

    showMacosSheet(
      context: context,
      builder: (context) => WhitelistManagerView(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  // iOS Sheet methods
  void _showLogsViewIOS() {
    if (!mounted) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => Material(
          child: LogsView(
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showUserScriptsViewIOS() {
    if (!mounted) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => Material(
          child: UserScriptManagerView(
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showWhitelistSheetIOS() {
    if (!mounted) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => Material(
          child: WhitelistView(
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showAddFilterSheetIOS() {
    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AddFilterListViewIOS(),
    );
  }

  // Sheet methods for update/progress/alerts that work on both platforms
  void _showUpdatePopup() {
    if (!mounted || _isShowingUpdatePopup) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showingUpdatePopup) return;

    _isShowingUpdatePopup = true;

    if (Platform.isMacOS) {
      showMacosSheet(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdatePopupView(
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ).whenComplete(() {
        _isShowingUpdatePopup = false;
        filterManager.showingUpdatePopup = false;
      });
    } else {
      // iOS - Use fullscreen modal
      Navigator.of(context)
          .push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => Material(
            child: UpdatePopupView(
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      )
          .whenComplete(() {
        _isShowingUpdatePopup = false;
        filterManager.showingUpdatePopup = false;
      });
    }
  }

  void _showMissingFiltersSheet() {
    if (!mounted || _isShowingMissingFiltersSheet) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showMissingFiltersSheet) return;

    _isShowingMissingFiltersSheet = true;

    if (Platform.isMacOS) {
      showMacosSheet(
        context: context,
        barrierDismissible: false,
        builder: (context) => MissingFiltersView(
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ).whenComplete(() {
        _isShowingMissingFiltersSheet = false;
        filterManager.showMissingFiltersSheet = false;
      });
    } else {
      // iOS - Use fullscreen modal
      Navigator.of(context)
          .push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => Material(
            child: MissingFiltersView(
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      )
          .whenComplete(() {
        _isShowingMissingFiltersSheet = false;
        filterManager.showMissingFiltersSheet = false;
      });
    }
  }

  void _showApplyProgressSheet() {
    if (!mounted || _isShowingApplyProgressSheet) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showingApplyProgressSheet) return;

    _isShowingApplyProgressSheet = true;

    if (Platform.isMacOS) {
      showMacosSheet(
        context: context,
        barrierDismissible: false,
        builder: (context) => ApplyChangesProgressView(
          onDismiss: () {
            Navigator.of(context).pop();
            final fm = ref.read(appFilterManagerProvider);
            fm.showingApplyProgressSheet = false;
          },
        ),
      ).whenComplete(() {
        _isShowingApplyProgressSheet = false;
        if (mounted) {
          final fm = ref.read(appFilterManagerProvider);
          fm.showingApplyProgressSheet = false;
        }
      });
    } else {
      // iOS - Use modal popup
      showCupertinoModalPopup(
        context: context,
        barrierDismissible: false,
        builder: (context) => ApplyChangesProgressView(
          onDismiss: () {
            Navigator.of(context).pop();
            final fm = ref.read(appFilterManagerProvider);
            fm.showingApplyProgressSheet = false;
          },
        ),
      ).whenComplete(() {
        _isShowingApplyProgressSheet = false;
        if (mounted) {
          final fm = ref.read(appFilterManagerProvider);
          fm.showingApplyProgressSheet = false;
        }
      });
    }
  }

  void _showNoUpdatesAlert() {
    if (!mounted || _isShowingNoUpdatesAlert) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showingNoUpdatesAlert) return;

    _isShowingNoUpdatesAlert = true;

    if (Platform.isMacOS) {
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
      ).whenComplete(() {
        _isShowingNoUpdatesAlert = false;
        filterManager.showingNoUpdatesAlert = false;
      });
    } else {
      // iOS - Use Cupertino alert dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Updates Found'),
          content: const Text('All your filters and userscripts are up to date.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ).whenComplete(() {
        _isShowingNoUpdatesAlert = false;
        filterManager.showingNoUpdatesAlert = false;
      });
    }
  }

  void _showDownloadCompleteAlert() {
    if (!mounted || _isShowingDownloadCompleteAlert) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showingDownloadCompleteAlert) return;

    _isShowingDownloadCompleteAlert = true;

    if (Platform.isMacOS) {
      showMacosAlertDialog(
        context: context,
        builder: (context) => MacosAlertDialog(
          appIcon: const MacosIcon(CupertinoIcons.checkmark_circle),
          title: const Text('Download Complete'),
          message: Text(filterManager.downloadCompleteMessage),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            color: AppTheme.primaryColor,
            child: const Text('Apply Now'),
            onPressed: () {
              Navigator.of(context).pop();
              filterManager.applyDownloadedChanges();
            },
          ),
          secondaryButton: PushButton(
            controlSize: ControlSize.large,
            child: const Text('Later'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ).whenComplete(() {
        _isShowingDownloadCompleteAlert = false;
        filterManager.showingDownloadCompleteAlert = false;
      });
    } else {
      // iOS - Use Cupertino alert dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Download Complete'),
          content: Text(filterManager.downloadCompleteMessage),
          actions: [
            CupertinoDialogAction(
              child: const Text('Later'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Apply Now'),
              onPressed: () {
                Navigator.of(context).pop();
                filterManager.applyDownloadedChanges();
              },
            ),
          ],
        ),
      ).whenComplete(() {
        _isShowingDownloadCompleteAlert = false;
        filterManager.showingDownloadCompleteAlert = false;
      });
    }
  }

  void _showCategoryWarningAlert() {
    if (!mounted || _isShowingCategoryWarningAlert) return;

    final filterManager = ref.read(appFilterManagerProvider);
    if (!filterManager.showingCategoryWarningAlert) return;

    _isShowingCategoryWarningAlert = true;

    if (Platform.isMacOS) {
      showMacosAlertDialog(
        context: context,
        builder: (context) => MacosAlertDialog(
          appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
          title: const Text('Category Rule Limit Warning'),
          message: Text(filterManager.categoryWarningMessage),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ).whenComplete(() {
        _isShowingCategoryWarningAlert = false;
        filterManager.showingCategoryWarningAlert = false;
      });
    } else {
      // iOS - Use Cupertino alert dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Category Rule Limit Warning'),
          content: Text(filterManager.categoryWarningMessage),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ).whenComplete(() {
        _isShowingCategoryWarningAlert = false;
        filterManager.showingCategoryWarningAlert = false;
      });
    }
  }
}

// Separate widget to handle async filter file exists check
class FilterRuleCountText extends StatefulWidget {
  final FilterList filter;
  final filterManager;

  const FilterRuleCountText({
    super.key,
    required this.filter,
    required this.filterManager,
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
        style: AppTheme.caption,
      );
    } else if (widget.filter.sourceRuleCount == null && widget.filter.isSelected && _filterFileExists == false) {
      return Text(
        '(Counting...)',
        style: AppTheme.caption.copyWith(color: CupertinoColors.systemOrange),
      );
    } else {
      return Text(
        '(N/A rules)',
        style: AppTheme.caption,
      );
    }
  }
}

class AddFilterListViewIOS extends ConsumerStatefulWidget {
  const AddFilterListViewIOS({super.key});

  @override
  ConsumerState<AddFilterListViewIOS> createState() => _AddFilterListViewIOSState();
}

class _AddFilterListViewIOSState extends ConsumerState<AddFilterListViewIOS> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final filterManager = ref.read(appFilterManagerProvider);
    final trimmedURL = _urlController.text.trim();

    if (trimmedURL.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(trimmedURL);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      _showError('The URL entered is not valid. Please enter a complete and correct URL (e.g., http:// or https://).');
      return;
    }

    if (filterManager.filterLists.any((f) => f.url.toString() == trimmedURL)) {
      _showError('A filter list with this URL already exists.');
      return;
    }

    filterManager.addFilterList(
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
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Text('Add Custom Filter List', style: AppTheme.headline),
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
                  Text('Filter Name (Optional):', style: AppTheme.caption),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'e.g., My Ad Block List',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  const SizedBox(height: 20),
                  Text('Filter URL:', style: AppTheme.caption),
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
