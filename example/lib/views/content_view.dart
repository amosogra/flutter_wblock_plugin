import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'filter_list_content_view.dart';
import 'add_custom_filter_view.dart';
import 'logs_view.dart';
import 'settings_view.dart';
import 'update_popup_view.dart';
import 'missing_filters_view.dart';
import 'keyboard_shortcuts_view.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  bool _showOnlyEnabledFilters = false;
  bool _showingLogs = false;
  bool _showingSettings = false;
  bool _showingAddFilterSheet = false;
  bool _showingCheatSheet = false;

  // Set up keyboard shortcuts
  final shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): RefreshIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): ApplyChangesIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): AddCustomFilterIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyL): ShowLogsIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma): ShowSettingsIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.alt, LogicalKeyboardKey.keyR): ResetToDefaultIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF): ToggleEnabledFiltersIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): ShowCheatSheetIntent(),
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filterManager = context.watch<FilterListManager>();

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) => filterManager.checkForUpdates(),
          ),
          ApplyChangesIntent: CallbackAction<ApplyChangesIntent>(
            onInvoke: (_) => filterManager.checkAndEnableFilters(),
          ),
          AddCustomFilterIntent: CallbackAction<AddCustomFilterIntent>(
            onInvoke: (_) {
              setState(() => _showingAddFilterSheet = true);
              return null;
            },
          ),
          ShowLogsIntent: CallbackAction<ShowLogsIntent>(
            onInvoke: (_) {
              setState(() => _showingLogs = true);
              return null;
            },
          ),
          ShowSettingsIntent: CallbackAction<ShowSettingsIntent>(
            onInvoke: (_) {
              setState(() => _showingSettings = true);
              return null;
            },
          ),
          ResetToDefaultIntent: CallbackAction<ResetToDefaultIntent>(
            onInvoke: (_) {
              _showResetDialog(context, filterManager);
              return null;
            },
          ),
          ToggleEnabledFiltersIntent: CallbackAction<ToggleEnabledFiltersIntent>(
            onInvoke: (_) {
              setState(() => _showOnlyEnabledFilters = !_showOnlyEnabledFilters);
              return null;
            },
          ),
          ShowCheatSheetIntent: CallbackAction<ShowCheatSheetIntent>(
            onInvoke: (_) {
              setState(() => _showingCheatSheet = true);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: SizedBox(
            width: 700,
            height: 500,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildToolbar(context, filterManager),
                    Expanded(
                      child: FilterListContentView(
                        selectedCategory: FilterListCategory.all,
                        showOnlyEnabledFilters: _showOnlyEnabledFilters,
                      ),
                    ),
                  ],
                ),

                // Sheets and Dialogs
                if (filterManager.showProgressView) _buildProgressOverlay(filterManager),

                if (_showingAddFilterSheet)
                  _buildSheet(
                    child: AddCustomFilterView(
                      onDismiss: () => setState(() => _showingAddFilterSheet = false),
                    ),
                  ),

                if (_showingLogs)
                  _buildSheet(
                    child: LogsView(
                      onDismiss: () => setState(() => _showingLogs = false),
                    ),
                  ),

                if (_showingSettings)
                  _buildSheet(
                    child: SettingsView(
                      onDismiss: () => setState(() => _showingSettings = false),
                    ),
                  ),

                if (_showingCheatSheet)
                  _buildSheet(
                    child: KeyboardShortcutsView(
                      onDismiss: () => setState(() => _showingCheatSheet = false),
                    ),
                  ),

                if (filterManager.missingFilters.isNotEmpty)
                  _buildSheet(
                    child: MissingFiltersView(
                      missingFilters: filterManager.missingFilters,
                      onDismiss: () => filterManager.missingFilters.clear(),
                      onUpdate: () => filterManager.updateMissingFilters(),
                    ),
                  ),

                if (filterManager.availableUpdates.isNotEmpty)
                  _buildSheet(
                    child: UpdatePopupView(
                      availableUpdates: filterManager.availableUpdates,
                      onDismiss: () => filterManager.availableUpdates.clear(),
                      onUpdate: (filters) => filterManager.updateSelectedFilters(filters),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, FilterListManager filterManager) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(
            color: MacosTheme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 70), // Space for window controls
          const Spacer(),

          // Apply Changes
          MacosIconButton(
            icon: const MacosIcon(Icons.download),
            onPressed: filterManager.hasUnappliedChanges ? () async => await filterManager.checkAndEnableFilters() : null,
            semanticLabel: 'Apply Changes',
          ),

          // Add Filter
          MacosIconButton(
            icon: const MacosIcon(Icons.add),
            onPressed: () => setState(() => _showingAddFilterSheet = true),
            semanticLabel: 'Add Custom Filter',
          ),

          // Refresh
          MacosIconButton(
            icon: const MacosIcon(Icons.refresh),
            onPressed: () async => await filterManager.checkForUpdates(),
            semanticLabel: 'Update Filters',
          ),

          // Settings
          MacosIconButton(
            icon: const MacosIcon(Icons.settings),
            onPressed: () => setState(() => _showingSettings = true),
            semanticLabel: 'Settings',
          ),

          // Filter Toggle
          MacosIconButton(
            icon: MacosIcon(
              _showOnlyEnabledFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () => setState(() => _showOnlyEnabledFilters = !_showOnlyEnabledFilters),
            semanticLabel: _showOnlyEnabledFilters ? 'Show All Filters' : 'Show Only Enabled Filters',
          ),

          // More Menu
          MacosPopupButton<String>(
            hint: const MacosIcon(Icons.more_horiz),
            items: [
              const MacosPopupMenuItem(
                value: 'logs',
                child: Text('Show Logs'),
              ),
              const MacosPopupMenuItem(
                value: 'reset',
                child: Text('Reset to Default'),
              ),
            ],
            onChanged: (value) {
              if (value == 'logs') {
                setState(() => _showingLogs = true);
              } else if (value == 'reset') {
                _showResetDialog(context, filterManager);
              }
            },
          ),

          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildProgressOverlay(FilterListManager filterManager) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressBar(value: (filterManager.progress * 100)),
              const SizedBox(height: 16),
              Text('${(filterManager.progress * 100).toInt()}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheet({required Widget child}) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, FilterListManager filterManager) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(Icons.warning),
        title: const Text('Reset to Default Lists?'),
        message: const Text(
          'This will reset all filter selections to the recommended defaults. Are you sure?',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.regular,
          onPressed: () {
            filterManager.resetToDefaultLists();
            Navigator.of(context).pop();
          },
          color: Colors.red,
          child: const Text('Reset'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.regular,
          onPressed: () => Navigator.of(context).pop(),
          secondary: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// Intent classes for keyboard shortcuts
class RefreshIntent extends Intent {}

class ApplyChangesIntent extends Intent {}

class AddCustomFilterIntent extends Intent {}

class ShowLogsIntent extends Intent {}

class ShowSettingsIntent extends Intent {}

class ResetToDefaultIntent extends Intent {}

class ToggleEnabledFiltersIntent extends Intent {}

class ShowCheatSheetIntent extends Intent {}
