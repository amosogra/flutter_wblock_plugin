import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';
import '../managers/user_script_manager.dart';
import '../models/filter_list.dart';
import 'stat_card.dart';
import 'add_filter_list_view.dart';
import 'logs_view.dart';
import 'user_script_manager_view.dart';
import 'update_popup_view.dart';
import 'missing_filters_view.dart';
import 'apply_changes_progress_view.dart';
import 'whitelist_manager_view.dart';

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

class _ContentViewState extends State<ContentView> with WidgetsBindingObserver {
  bool showOnlyEnabledLists = false;
  bool _showingAddFilterSheet = false;
  bool _showingLogsView = false;
  bool _showingUserScriptsView = false;
  bool _showingWhitelistSheet = false;

  int get enabledListsCount {
    return widget.filterManager.filterLists
        .where((filter) => filter.isSelected)
        .length;
  }

  List<String> get displayableCategories {
    return FilterListCategory.displayableCategories;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.filterManager.setUserScriptManager(widget.userScriptManager);
    _setupListeners();
    
    if (Platform.isIOS) {
      _requestNotificationPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isIOS && 
        state == AppLifecycleState.paused && 
        widget.filterManager.hasUnappliedChanges) {
      _scheduleNotification();
    }
  }

  void _setupListeners() {
    widget.filterManager.addListener(() {
      if (!mounted) return;
      
      // Handle sheet presentations
      if (widget.filterManager.showingUpdatePopup) {
        _showUpdatePopup();
      }
      
      if (widget.filterManager.showMissingFiltersSheet) {
        _showMissingFiltersSheet();
      }
      
      if (widget.filterManager.showingApplyProgressSheet) {
        _showApplyProgressSheet();
      }
      
      // Handle alerts
      if (widget.filterManager.showingNoUpdatesAlert) {
        _showNoUpdatesAlert();
      }
      
      if (widget.filterManager.showingDownloadCompleteAlert) {
        _showDownloadCompleteAlert();
      }
      
      if (widget.filterManager.showingCategoryWarningAlert) {
        _showCategoryWarningAlert();
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    // iOS notification permission is handled through native code
    // This is just a placeholder as the actual implementation would be in the native plugin
  }

  void _scheduleNotification() {
    // iOS notification scheduling is handled through native code
    // This is just a placeholder as the actual implementation would be in the native plugin
  }

  void _showUpdatePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UpdatePopupView(
        filterManager: widget.filterManager,
        userScriptManager: widget.userScriptManager,
        isPresented: (value) {
          widget.filterManager.setShowingUpdatePopup(value);
          if (!value && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    ).then((_) {
      widget.filterManager.setShowingUpdatePopup(false);
    });
  }

  void _showMissingFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MissingFiltersView(
        filterManager: widget.filterManager,
      ),
    ).then((_) {
      widget.filterManager.setShowMissingFiltersSheet(false);
    });
  }

  void _showApplyProgressSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (context) => ApplyChangesProgressView(
        filterManager: widget.filterManager,
        isPresented: (value) {
          widget.filterManager.setShowingApplyProgressSheet(value);
          if (!value && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    ).then((_) {
      widget.filterManager.setShowingApplyProgressSheet(false);
    });
  }

  void _showNoUpdatesAlert() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Updates Found'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingNoUpdatesAlert(false);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Updates Found'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingNoUpdatesAlert(false);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showDownloadCompleteAlert() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Download Complete'),
          content: Text(widget.filterManager.downloadCompleteMessage),
          actions: [
            CupertinoDialogAction(
              child: const Text('Apply Now'),
              onPressed: () async {
                Navigator.pop(context);
                widget.filterManager.setShowingDownloadCompleteAlert(false);
                await widget.filterManager.applyDownloadedChanges();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Later'),
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingDownloadCompleteAlert(false);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Complete'),
          content: Text(widget.filterManager.downloadCompleteMessage),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                widget.filterManager.setShowingDownloadCompleteAlert(false);
                await widget.filterManager.applyDownloadedChanges();
              },
              child: const Text('Apply Now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingDownloadCompleteAlert(false);
              },
              child: const Text('Later'),
            ),
          ],
        ),
      );
    }
  }

  void _showCategoryWarningAlert() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Category Rule Limit Warning'),
          content: Text(widget.filterManager.categoryWarningMessage),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingCategoryWarningAlert(false);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Category Rule Limit Warning'),
          content: Text(widget.filterManager.categoryWarningMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.filterManager.setShowingCategoryWarningAlert(false);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              _buildIOSHeader(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
          _buildOverlays(context),
        ],
      ),
    );
  }

  Widget _buildMacOSView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('wBlock'),
        actions: _buildMacOSToolbar(context),
      ),
      body: Stack(
        children: [
          _buildContent(context),
          _buildOverlays(context),
        ],
      ),
    );
  }

  Widget _buildIOSHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 20, right: 20, bottom: 12),
      child: Row(
        children: [
          const Spacer(),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.filterManager.isLoading
                    ? null
                    : () async {
                        await widget.filterManager.checkForUpdates();
                      },
                child: const Icon(CupertinoIcons.arrow_clockwise),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.filterManager.isLoading || enabledListsCount == 0
                    ? null
                    : () async {
                        await widget.filterManager.checkAndEnableFilters(forceReload: true);
                      },
                child: const Icon(CupertinoIcons.arrow_2_circlepath),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _showingLogsView = true;
                  });
                  _showLogsView(context);
                },
                child: const Icon(CupertinoIcons.doc_text_search),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _showingUserScriptsView = true;
                  });
                  _showUserScriptsView(context);
                },
                child: const Icon(CupertinoIcons.doc_text_fill),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _showingAddFilterSheet = true;
                  });
                  _showAddFilterSheet(context);
                },
                child: const Icon(CupertinoIcons.plus),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMacOSToolbar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: widget.filterManager.isLoading
            ? null
            : () async {
                await widget.filterManager.checkForUpdates();
              },
        tooltip: 'Check for Updates',
      ),
      IconButton(
        icon: const Icon(Icons.sync),
        onPressed: widget.filterManager.isLoading || enabledListsCount == 0
            ? null
            : () async {
                await widget.filterManager.checkAndEnableFilters(forceReload: true);
              },
        tooltip: 'Apply Changes',
      ),
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          setState(() {
            _showingLogsView = true;
          });
          _showLogsView(context);
        },
        tooltip: 'Show Logs',
      ),
      IconButton(
        icon: const Icon(Icons.description),
        onPressed: () {
          setState(() {
            _showingUserScriptsView = true;
          });
          _showUserScriptsView(context);
        },
        tooltip: 'User Scripts',
      ),
      IconButton(
        icon: const Icon(Icons.list),
        onPressed: () {
          setState(() {
            _showingWhitelistSheet = true;
          });
          _showWhitelistView(context);
        },
        tooltip: 'Whitelisted Domains',
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _showingAddFilterSheet = true;
          });
          _showAddFilterSheet(context);
        },
        tooltip: 'Add Filter',
      ),
      IconButton(
        icon: Icon(showOnlyEnabledLists ? Icons.filter_list_off : Icons.filter_list),
        onPressed: () {
          setState(() {
            showOnlyEnabledLists = !showOnlyEnabledLists;
          });
        },
        tooltip: 'Show Enabled Only',
      ),
    ];
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _buildStatsCards(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < displayableCategories.length) {
                  final category = displayableCategories[index];
                  final lists = _listsForCategory(category);
                  if (lists.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFilterSection(context, category, lists),
                  );
                } else {
                  final customLists = _customLists;
                  if (customLists.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFilterSection(context, FilterListCategory.custom, customLists),
                  );
                }
              },
              childCount: displayableCategories.length + 1,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Enabled Lists',
            value: enabledListsCount.toString(),
            icon: Platform.isIOS 
                ? CupertinoIcons.list_bullet_below_rectangle
                : Icons.list_alt,
            pillColor: Colors.transparent,
            valueColor: null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Safari Rules',
            value: widget.filterManager.lastRuleCount.toString(),
            icon: Platform.isIOS
                ? CupertinoIcons.shield_lefthalf_fill
                : Icons.shield,
            pillColor: Colors.transparent,
            valueColor: null,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context, String category, List<FilterList> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              FutureBuilder<bool>(
                future: widget.filterManager.isCategoryApproachingLimit(category),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return GestureDetector(
                      onTap: () {
                        widget.filterManager.showCategoryWarning(category);
                      },
                      child: Icon(
                        Platform.isIOS
                            ? CupertinoIcons.exclamationmark_triangle
                            : Icons.warning,
                        color: Colors.orange,
                        size: 16,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Spacer(),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Platform.isIOS
                ? CupertinoColors.systemGrey6.resolveFrom(context)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < filters.length; i++) ...[
                _buildFilterRow(context, filters[i]),
                if (i < filters.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Divider(
                      height: 1,
                      color: Platform.isIOS
                          ? CupertinoColors.separator.resolveFrom(context)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, FilterList filter) {
    return GestureDetector(
      onLongPress: () {
        _showFilterContextMenu(context, filter);
      },
      child: Container(
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
                  if (filter.sourceRuleCount != null && filter.sourceRuleCount! > 0) ...[
                    Text(
                      '(${filter.sourceRuleCount!.toString()} rules)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isIOS
                            ? CupertinoColors.secondaryLabel.resolveFrom(context)
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ] else if (filter.sourceRuleCount == null && filter.isSelected && !widget.filterManager.doesFilterFileExist(filter)) ...[
                    const Text(
                      '(Counting...)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '(N/A rules)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isIOS
                            ? CupertinoColors.secondaryLabel.resolveFrom(context)
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (filter.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      filter.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isIOS
                            ? CupertinoColors.secondaryLabel.resolveFrom(context)
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (filter.version.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Version: ${filter.version}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Platform.isIOS
                            ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Platform.isIOS
                ? CupertinoSwitch(
                    value: filter.isSelected,
                    onChanged: (value) {
                      widget.filterManager.toggleFilterListSelection(filter.id);
                    },
                  )
                : Switch(
                    value: filter.isSelected,
                    onChanged: (value) {
                      widget.filterManager.toggleFilterListSelection(filter.id);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlays(BuildContext context) {
    return Stack(
      children: [
        if (widget.filterManager.isLoading &&
            !widget.filterManager.showingApplyProgressSheet &&
            !widget.filterManager.showMissingFiltersSheet &&
            !widget.filterManager.showingUpdatePopup)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Platform.isIOS
                      ? CupertinoColors.systemBackground.resolveFrom(context)
                      : Theme.of(context).cardColor,
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
                    Platform.isIOS
                        ? const CupertinoActivityIndicator(radius: 20)
                        : const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      widget.filterManager.statusDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Platform.isIOS
                            ? CupertinoColors.secondaryLabel.resolveFrom(context)
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<FilterList> _listsForCategory(String category) {
    return widget.filterManager.filterLists
        .where((filter) => 
            filter.category == category && 
            (!showOnlyEnabledLists || filter.isSelected))
        .toList();
  }

  List<FilterList> get _customLists {
    return widget.filterManager.filterLists
        .where((filter) => 
            filter.category == FilterListCategory.custom && 
            (!showOnlyEnabledLists || filter.isSelected))
        .toList();
  }

  void _showFilterContextMenu(BuildContext context, FilterList filter) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            if (filter.category == FilterListCategory.custom)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  widget.filterManager.removeFilterList(filter);
                },
                isDestructiveAction: true,
                child: const Text('Delete Custom List'),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: filter.url));
              },
              child: const Text('Copy URL'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Filter Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.category == FilterListCategory.custom)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Custom List'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.filterManager.removeFilterList(filter);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy URL'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: filter.url));
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showAddFilterSheet(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => AddFilterListView(
          filterManager: widget.filterManager,
        ),
      ).then((_) {
        setState(() {
          _showingAddFilterSheet = false;
        });
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AddFilterListView(
          filterManager: widget.filterManager,
        ),
      ).then((_) {
        setState(() {
          _showingAddFilterSheet = false;
        });
      });
    }
  }

  void _showLogsView(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => const LogsView(),
        ),
      ).then((_) {
        setState(() {
          _showingLogsView = false;
        });
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => const Dialog(
          child: SizedBox(
            width: 600,
            height: 400,
            child: LogsView(),
          ),
        ),
      ).then((_) {
        setState(() {
          _showingLogsView = false;
        });
      });
    }
  }

  void _showUserScriptsView(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => UserScriptManagerView(
            userScriptManager: widget.userScriptManager,
          ),
        ),
      ).then((_) {
        setState(() {
          _showingUserScriptsView = false;
        });
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 600,
            height: 400,
            child: UserScriptManagerView(
              userScriptManager: widget.userScriptManager,
            ),
          ),
        ),
      ).then((_) {
        setState(() {
          _showingUserScriptsView = false;
        });
      });
    }
  }

  void _showWhitelistView(BuildContext context) {
    if (Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 400,
            height: 400,
            child: WhitelistManagerView(
              filterManager: widget.filterManager,
            ),
          ),
        ),
      ).then((_) {
        setState(() {
          _showingWhitelistSheet = false;
        });
      });
    }
  }
}
