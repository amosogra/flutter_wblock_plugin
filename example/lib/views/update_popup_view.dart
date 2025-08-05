import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';
import 'dart:io';

class UpdatePopupView extends StatefulWidget {
  final AppFilterManager filterManager;
  final UserScriptManager? userScriptManager;
  final VoidCallback onDismiss;

  const UpdatePopupView({
    super.key,
    required this.filterManager,
    this.userScriptManager,
    required this.onDismiss,
  });

  @override
  State<UpdatePopupView> createState() => _UpdatePopupViewState();
}

class _UpdatePopupViewState extends State<UpdatePopupView> {
  Set<String> _selectedFilters = <String>{};
  Set<String> _selectedScripts = <String>{};
  Set<FilterListCategory> _selectedCategories = <FilterListCategory>{};
  List<UserScript> _scriptsWithUpdates = [];

  int get progressPercentage => (widget.filterManager.progress * 100).round();

  bool get hasScriptUpdates => _scriptsWithUpdates.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeSelectedItems();
    _loadScriptUpdates();
  }

  void _initializeSelectedItems() {
    // Initialize selected filters
    _selectedFilters = Set<String>.from(widget.filterManager.availableUpdates.map((f) => f.id));

    // Initialize selected categories from filters
    final categories = <FilterListCategory>{};
    for (final filter in widget.filterManager.availableUpdates) {
      categories.add(filter.category);
    }
    _selectedCategories = categories;
  }

  Future<void> _loadScriptUpdates() async {
    if (widget.userScriptManager != null) {
      // In a real implementation, you would check for script updates
      // For now, we'll simulate this
      _scriptsWithUpdates = widget.userScriptManager!.userScripts
          .where((script) => script.isDownloaded)
          .take(2) // Simulate some scripts having updates
          .toList();

      if (_scriptsWithUpdates.isNotEmpty) {
        _selectedScripts = Set<String>.from(_scriptsWithUpdates.map((s) => s.id));
        _selectedCategories.add(FilterListCategory.scripts);
      }
      setState(() {});
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
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 450,
          height: 350,
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
      children: [
        _buildHeader(),
        Expanded(
          child: widget.filterManager.isLoading ? _buildDownloadProgress() : _buildFilterSelection(),
        ),
        if (!widget.filterManager.isLoading) _buildButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            widget.filterManager.isLoading ? 'Downloading Updates' : 'Available Updates',
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
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
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
      ),
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

  Widget _buildFilterSelection() {
    final filtersByCategory = <FilterListCategory, List<FilterList>>{};
    for (final filter in widget.filterManager.availableUpdates) {
      filtersByCategory.putIfAbsent(filter.category, () => []).add(filter);
    }

    final allCategories = <FilterListCategory>[...filtersByCategory.keys];
    if (hasScriptUpdates) {
      allCategories.add(FilterListCategory.scripts);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final category = allCategories[index];
        return _buildCategorySection(category, filtersByCategory[category] ?? []);
      },
    );
  }

  Widget _buildCategorySection(FilterListCategory category, List<FilterList> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader(category, filters),
        const SizedBox(height: 8),
        ...filters.map((filter) => _buildFilterRow(filter)),
        if (category == FilterListCategory.scripts && hasScriptUpdates) ..._scriptsWithUpdates.map((script) => _buildScriptRow(script)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryHeader(FilterListCategory category, List<FilterList> filters) {
    final isCategorySelected = _selectedCategories.contains(category);

    return Row(
      children: [
        Text(
          category.rawValue,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const Spacer(),
        Platform.isMacOS
            ? MacosSwitch(
                value: isCategorySelected,
                onChanged: (value) => _toggleCategory(category, value, filters),
              )
            : CupertinoSwitch(
                value: isCategorySelected,
                onChanged: (value) => _toggleCategory(category, value, filters),
              ),
      ],
    );
  }

  Widget _buildFilterRow(FilterList filter) {
    final isSelected = _selectedFilters.contains(filter.id);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: isSelected
                ? (Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue)
                : (Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                  ),
                ),
                if (filter.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    filter.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptRow(UserScript script) {
    final isSelected = _selectedScripts.contains(script.id);

    return GestureDetector(
      onTap: () => _toggleScript(script.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected
                  ? (Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue)
                  : (Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    script.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                    ),
                  ),
                  if (script.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      script.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Spacer(),
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  onPressed: (_selectedFilters.isEmpty && _selectedScripts.isEmpty) ? null : _downloadUpdates,
                  child: const Text('Download'),
                )
              : CupertinoButton.filled(
                  onPressed: (_selectedFilters.isEmpty && _selectedScripts.isEmpty) ? null : _downloadUpdates,
                  child: const Text('Download'),
                ),
          const Spacer(),
        ],
      ),
    );
  }

  void _toggleCategory(FilterListCategory category, bool value, List<FilterList> filters) {
    setState(() {
      if (value) {
        _selectedCategories.add(category);
        if (category == FilterListCategory.scripts) {
          _selectedScripts.addAll(_scriptsWithUpdates.map((s) => s.id));
        } else {
          _selectedFilters.addAll(filters.map((f) => f.id));
        }
      } else {
        _selectedCategories.remove(category);
        if (category == FilterListCategory.scripts) {
          _selectedScripts.clear();
        } else {
          for (final filter in filters) {
            _selectedFilters.remove(filter.id);
          }
        }
      }
    });
  }

  void _toggleFilter(String filterId) {
    setState(() {
      if (_selectedFilters.contains(filterId)) {
        _selectedFilters.remove(filterId);

        // Check if all filters in this category are deselected
        final filter = widget.filterManager.availableUpdates.firstWhere((f) => f.id == filterId);
        final categoryFilters = widget.filterManager.availableUpdates.where((f) => f.category == filter.category).toList();
        final selectedCategoryFilters = categoryFilters.where((f) => _selectedFilters.contains(f.id)).toList();

        if (selectedCategoryFilters.isEmpty) {
          _selectedCategories.remove(filter.category);
        }
      } else {
        _selectedFilters.add(filterId);
        final filter = widget.filterManager.availableUpdates.firstWhere((f) => f.id == filterId);
        _selectedCategories.add(filter.category);
      }
    });
  }

  void _toggleScript(String scriptId) {
    setState(() {
      if (_selectedScripts.contains(scriptId)) {
        _selectedScripts.remove(scriptId);
        if (_selectedScripts.isEmpty) {
          _selectedCategories.remove(FilterListCategory.scripts);
        }
      } else {
        _selectedScripts.add(scriptId);
        _selectedCategories.add(FilterListCategory.scripts);
      }
    });
  }

  Future<void> _downloadUpdates() async {
    // Handle filter list updates
    final filtersToUpdate = widget.filterManager.availableUpdates.where((f) => _selectedFilters.contains(f.id)).toList();

    if (filtersToUpdate.isNotEmpty) {
      await widget.filterManager.downloadSelectedFilters(filtersToUpdate);
    }

    // Handle script updates
    if (widget.userScriptManager != null && _selectedScripts.isNotEmpty) {
      final scriptsToUpdate = _scriptsWithUpdates.where((s) => _selectedScripts.contains(s.id)).toList();

      if (scriptsToUpdate.isNotEmpty) {
        for (final script in scriptsToUpdate) {
          await widget.userScriptManager!.updateUserScript(script);
        }
      }
    }
  }
}
