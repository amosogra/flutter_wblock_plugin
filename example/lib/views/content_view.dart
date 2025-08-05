import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/views/stat_card.dart';
import 'package:flutter_wblock_plugin_example/views/logs_view.dart';
import 'package:flutter_wblock_plugin_example/views/user_script_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_view.dart';
import 'package:flutter_wblock_plugin_example/views/whitelist_manager_view.dart';
import 'package:flutter_wblock_plugin_example/views/apply_changes_progress_view.dart';
import 'package:flutter_wblock_plugin_example/views/update_popup_view.dart';
import 'package:flutter_wblock_plugin_example/views/missing_filters_view.dart';
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
  bool _showingAddFilterSheet = false;
  bool _showingLogsView = false;
  bool _showingUserScriptsView = false;
  bool _showingWhitelistSheet = false;

  int get enabledListsCount => widget.filterManager.filterLists.where((f) => f.isSelected).length;

  List<FilterListCategory> get displayableCategories => [
        FilterListCategory.ads,
        FilterListCategory.privacy,
        FilterListCategory.security,
        FilterListCategory.multipurpose,
        FilterListCategory.annoyances,
        FilterListCategory.experimental,
        FilterListCategory.foreign,
      ];

  @override
  void initState() {
    super.initState();
    // Set the UserScriptManager for filter updates
    widget.filterManager.setUserScriptManager(widget.userScriptManager);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppFilterManager>(
      builder: (context, filterManager, child) {
        if (Platform.isMacOS) {
          return _buildMacOSContent(filterManager);
        } else {
          return _buildIOSContent(filterManager);
        }
      },
    );
  }

  Widget _buildMacOSContent(AppFilterManager filterManager) {
    return MacosScaffold(
      backgroundColor: WBlockTheme.macOSBackgroundColor,
      toolBar: ToolBar(
        title: const Text('wBlock'),
        titleWidth: 150.0,
        actions: [
          ToolBarIconButton(
            label: 'Check for Updates',
            showLabel: false,
            tooltipMessage: 'Check for Updates',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: filterManager.isLoading
                ? null
                : () async {
                    await filterManager.checkForUpdates();
                  },
          ),
          ToolBarIconButton(
            showLabel: false,
            label: 'Apply Changes',
            tooltipMessage: 'Apply Changes',
            icon: const MacosIcon(CupertinoIcons.refresh_circled),
            onPressed: (filterManager.isLoading || enabledListsCount == 0)
                ? null
                : () {
                    filterManager.checkAndEnableFilters(forceReload: true);
                  },
          ),
          ToolBarIconButton(
            label: 'Show Logs',
            tooltipMessage: 'Show Logs',
            icon: const MacosIcon(CupertinoIcons.doc_text_search),
            showLabel: false,
            onPressed: () {
              setState(() {
                _showingLogsView = true;
              });
            },
          ),
          ToolBarIconButton(
            label: 'User Scripts',
            tooltipMessage: 'User Scripts',
            icon: const MacosIcon(CupertinoIcons.doc_text_fill),
            showLabel: false,
            onPressed: () {
              setState(() {
                _showingUserScriptsView = true;
              });
            },
          ),
          ToolBarIconButton(
            label: 'Whitelisted Domains',
            tooltipMessage: 'Whitelisted Domains',
            icon: const MacosIcon(CupertinoIcons.list_bullet_indent),
            showLabel: false,
            onPressed: () {
              setState(() {
                _showingWhitelistSheet = true;
              });
            },
          ),
          ToolBarIconButton(
            label: 'Add Filter',
            tooltipMessage: 'Add Filter',
            icon: const MacosIcon(CupertinoIcons.plus),
            showLabel: false,
            onPressed: () {
              setState(() {
                _showingAddFilterSheet = true;
              });
            },
          ),
          ToolBarIconButton(
            label: 'Show Enabled Only',
            tooltipMessage: 'Show Enabled Only',
            icon: MacosIcon(_showOnlyEnabledLists ? CupertinoIcons.line_horizontal_3_decrease_circle_fill : CupertinoIcons.line_horizontal_3_decrease_circle),
            onPressed: () {
              setState(() {
                _showOnlyEnabledLists = !_showOnlyEnabledLists;
              });
            },
            showLabel: false,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) => _buildContent(filterManager, scrollController),
        ),
      ],
    );
  }

  Widget _buildIOSContent(AppFilterManager filterManager) {
    return CupertinoPageScaffold(
      backgroundColor: WBlockTheme.iOSBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: WBlockTheme.iOSNavigationBarColorTranslucent,
        middle: const Text('wBlock'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: filterManager.isLoading
                  ? null
                  : () async {
                      await filterManager.checkForUpdates();
                    },
              child: const Icon(CupertinoIcons.refresh),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: (filterManager.isLoading || enabledListsCount == 0)
                  ? null
                  : () {
                      filterManager.checkAndEnableFilters(forceReload: true);
                    },
              child: const Icon(CupertinoIcons.refresh_circled),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _showingLogsView = true;
                });
              },
              child: const Icon(CupertinoIcons.doc_text_search),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _showingUserScriptsView = true;
                });
              },
              child: const Icon(CupertinoIcons.doc_text_fill),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _showingAddFilterSheet = true;
                });
              },
              child: const Icon(CupertinoIcons.plus),
            ),
          ],
        ),
      ),
      child: _buildContent(filterManager, null),
    );
  }

  Widget _buildContent(AppFilterManager filterManager, ScrollController? scrollController) {
    return Stack(
      children: [
        Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: Platform.isMacOS ? const EdgeInsets.all(20) : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              _buildStatsCardsView(filterManager),
              const SizedBox(height: 20),
              ..._buildFilterSections(filterManager),
              const SizedBox(height: 20),
            ],
          ),
          ),
        ),
        _buildOverlay(filterManager),
        _buildSheets(filterManager),
        _buildAlerts(filterManager),
      ],
    );
  }

  Widget _buildStatsCardsView(AppFilterManager filterManager) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Enabled Lists',
            value: '$enabledListsCount',
            icon: 'list.bullet.rectangle',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: WBlockTheme.primaryTextColor
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Safari Rules',
            value: _formatNumber(filterManager.lastRuleCount),
            icon: 'shield.lefthalf.filled',
            pillColor: WBlockTheme.statCardBackground,
            valueColor: WBlockTheme.primaryTextColor
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterSections(AppFilterManager filterManager) {
    final sections = <Widget>[];

    for (final category in displayableCategories) {
      final filters = _listsForCategory(category, filterManager);
      if (filters.isNotEmpty) {
        sections.add(_buildFilterSectionView(category, filters, filterManager));
        sections.add(const SizedBox(height: 16));
      }
    }

    final customLists = _customLists(filterManager);
    if (customLists.isNotEmpty) {
      sections.add(_buildFilterSectionView(FilterListCategory.custom, customLists, filterManager));
      sections.add(const SizedBox(height: 16));
    }

    return sections;
  }

  Widget _buildFilterSectionView(FilterListCategory category, List<FilterList> filters, AppFilterManager filterManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                category.rawValue,
                style: WBlockTheme.headlineStyle,
              ),
              if (filterManager.isCategoryApproachingLimit(category)) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    filterManager.showCategoryWarning(category);
                  },
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: WBlockTheme.cardBackgroundColorTranslucent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < filters.length; i++) ...[
                _buildFilterRowView(filters[i], filterManager),
                if (i < filters.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 0,
                    color: WBlockTheme.subtleDividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRowView(FilterList filter, AppFilterManager filterManager) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filter.name,
                      style: WBlockTheme.bodyStyle,
                    ),
                    const SizedBox(height: 4),
                    _buildRuleCountText(filter, filterManager),
                    if (filter.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        filter.description,
                        style: WBlockTheme.captionStyle,
                      ),
                    ],
                    if (filter.version.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Version: ${filter.version}',
                        style: WBlockTheme.smallCaptionStyle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Platform.isMacOS
                  ? MacosSwitch(
                      value: filter.isSelected,
                      onChanged: (value) {
                        filterManager.toggleFilterListSelection(filter.id);
                      },
                    )
                  : CupertinoSwitch(
                      value: filter.isSelected,
                      onChanged: (value) {
                        filterManager.toggleFilterListSelection(filter.id);
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCountText(FilterList filter, AppFilterManager filterManager) {
    String text;
    Color color;

    if (filter.sourceRuleCount != null && filter.sourceRuleCount! > 0) {
      text = '(${_formatNumber(filter.sourceRuleCount!)} rules)';
      color = WBlockTheme.secondaryTextColor;
    } else if (filter.sourceRuleCount == null && filter.isSelected /* && !filterManager.doesFilterFileExist(filter) */) {
      text = '(Counting...)';
      color = Colors.orange;
    } else {
      text = '(N/A rules)';
      color = Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
      ),
    );
  }

  Widget _buildOverlay(AppFilterManager filterManager) {
    if (!filterManager.isLoading || filterManager.showingApplyProgressSheet || filterManager.showMissingFiltersSheet || filterManager.showingUpdatePopup) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WBlockTheme.modalBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Platform.isMacOS ? const ProgressCircle(value: null) : const CupertinoActivityIndicator(radius: 12),
              const SizedBox(height: 10),
              Text(
                filterManager.statusDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WBlockTheme.secondaryTextColor
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheets(AppFilterManager filterManager) {
    return Stack(
      children: [
        if (_showingAddFilterSheet) _buildAddFilterSheet(),
        if (_showingLogsView)
          LogsView(
            onDismiss: () {
              setState(() {
                _showingLogsView = false;
              });
            },
          ),
        if (_showingUserScriptsView)
          UserScriptManagerView(
            userScriptManager: widget.userScriptManager,
            onDismiss: () {
              setState(() {
                _showingUserScriptsView = false;
              });
            },
          ),
        if (_showingWhitelistSheet)
          Platform.isMacOS
              ? WhitelistManagerView(
                  filterManager: filterManager,
                  onDismiss: () {
                    setState(() {
                      _showingWhitelistSheet = false;
                    });
                  },
                )
              : WhitelistView(
                  viewModel: filterManager.whitelistViewModel,
                  onDismiss: () {
                    setState(() {
                      _showingWhitelistSheet = false;
                    });
                  },
                ),
        if (filterManager.showingUpdatePopup)
          UpdatePopupView(
            filterManager: filterManager,
            userScriptManager: widget.userScriptManager,
            onDismiss: () {
              filterManager.showingUpdatePopup = false;
            },
          ),
        if (filterManager.showMissingFiltersSheet)
          MissingFiltersView(
            filterManager: filterManager,
            onDismiss: () {
              filterManager.showMissingFiltersSheet = false;
            },
          ),
        if (filterManager.showingApplyProgressSheet)
          ApplyChangesProgressView(
            filterManager: filterManager,
            onDismiss: () {
              filterManager.showingApplyProgressSheet = false;
            },
          ),
      ],
    );
  }

  Widget _buildAlerts(AppFilterManager filterManager) {
    return Stack(
      children: [
        if (filterManager.showingNoUpdatesAlert)
          _buildAlert(
            title: 'No Updates Found',
            message: 'All filter lists are up to date.',
            onDismiss: () {
              filterManager.showingNoUpdatesAlert = false;
            },
          ),
        if (filterManager.showingDownloadCompleteAlert)
          _buildAlert(
            title: 'Download Complete',
            message: filterManager.downloadCompleteMessage,
            actions: [
              _buildAlertAction(
                'Apply Now',
                () {
                  filterManager.showingDownloadCompleteAlert = false;
                  filterManager.applyDownloadedChanges();
                },
              ),
              _buildAlertAction(
                'Later',
                () {
                  filterManager.showingDownloadCompleteAlert = false;
                },
              ),
            ],
          ),
        if (filterManager.showingCategoryWarningAlert)
          _buildAlert(
            title: 'Category Rule Limit Warning',
            message: filterManager.categoryWarningMessage,
            onDismiss: () {
              filterManager.showingCategoryWarningAlert = false;
            },
          ),
      ],
    );
  }

  Widget _buildAlert({
    required String title,
    required String message,
    List<Widget>? actions,
    VoidCallback? onDismiss,
  }) {
    if (Platform.isMacOS) {
      // Use MacOS alert dialog
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: MacosAlertDialog(
            appIcon: const FlutterLogo(size: 56),
            title: Text(title),
            message: Text(message),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: onDismiss ?? () {},
              child: const Text('OK'),
            ),
            secondaryButton: actions?.isNotEmpty == true && actions!.first is PushButton ? actions.first as PushButton : null,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: actions ??
                [
                  CupertinoDialogAction(
                    onPressed: onDismiss ?? () {},
                    child: const Text('OK'),
                  ),
                ],
          ),
        ),
      );
    }
  }

  Widget _buildAlertAction(String text, VoidCallback onPressed) {
    if (Platform.isMacOS) {
      return PushButton(
        controlSize: ControlSize.large,
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return CupertinoDialogAction(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }

  Widget _buildAddFilterSheet() {
    return AddFilterListView(
      filterManager: widget.filterManager,
      onDismiss: () {
        setState(() {
          _showingAddFilterSheet = false;
        });
      },
    );
  }

  List<FilterList> _listsForCategory(FilterListCategory category, AppFilterManager filterManager) {
    return filterManager.filterLists.where((f) => f.category == category && (!_showOnlyEnabledLists || f.isSelected)).toList();
  }

  List<FilterList> _customLists(AppFilterManager filterManager) {
    return filterManager.filterLists.where((f) => f.category == FilterListCategory.custom && (!_showOnlyEnabledLists || f.isSelected)).toList();
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

class AddFilterListView extends StatefulWidget {
  final AppFilterManager filterManager;
  final VoidCallback onDismiss;

  const AddFilterListView({
    super.key,
    required this.filterManager,
    required this.onDismiss,
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
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: Platform.isMacOS ? 400 : double.infinity,
          height: Platform.isMacOS ? 220 : null,
          margin: Platform.isMacOS ? null : const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WBlockTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Custom Filter List',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WBlockTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Name (Optional):',
                    style: WBlockTheme.captionStyle,
                  ),
                  const SizedBox(height: 4),
                  Platform.isMacOS
                      ? MacosTextField(
                          controller: _nameController,
                          placeholder: 'e.g., My Ad Block List',
                        )
                      : CupertinoTextField(
                          controller: _nameController,
                          placeholder: 'e.g., My Ad Block List',
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter URL:',
                    style: WBlockTheme.captionStyle,
                  ),
                  const SizedBox(height: 4),
                  Platform.isMacOS
                      ? MacosTextField(
                          controller: _urlController,
                          placeholder: 'https://example.com/filter.txt',
                        )
                      : CupertinoTextField(
                          controller: _urlController,
                          placeholder: 'https://example.com/filter.txt',
                          keyboardType: TextInputType.url,
                        ),
                ],
              ),
              const Spacer(),
              Row(
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
                          onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
                          child: const Text('Add'),
                        )
                      : CupertinoButton.filled(
                          onPressed: _urlController.text.trim().isEmpty ? null : _validateAndAdd,
                          child: const Text('Add'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateAndAdd() {
    final trimmedUrl = _urlController.text.trim();

    if (trimmedUrl.isEmpty) return;

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      setState(() {
        _errorMessage = 'The URL entered is not valid. Please enter a complete and correct URL (e.g., http:// or https://).';
        _showErrorAlert = true;
      });
      return;
    }

    // Check if filter already exists
    final exists = widget.filterManager.filterLists.any((f) => f.url == uri);
    if (exists) {
      setState(() {
        _errorMessage = 'A filter list with this URL already exists.';
        _showErrorAlert = true;
      });
      return;
    }

    widget.filterManager.addFilterList(
      name: _nameController.text.trim(),
      urlString: trimmedUrl,
    );
    widget.onDismiss();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
