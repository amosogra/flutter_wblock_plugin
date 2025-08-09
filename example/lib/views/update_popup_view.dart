import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';
import 'dart:ui';

class UpdatePopupView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const UpdatePopupView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<UpdatePopupView> createState() => _UpdatePopupViewState();
}

class _UpdatePopupViewState extends ConsumerState<UpdatePopupView> {
  Set<String> _selectedFilters = <String>{};
  Set<String> _selectedScripts = <String>{};
  Set<FilterListCategory> _selectedCategories = <FilterListCategory>{};
  List<UserScript> _scriptsWithUpdates = [];

  @override
  void initState() {
    super.initState();
    _initializeSelectedItems();
    _loadScriptUpdates();
  }

  void _initializeSelectedItems() {
    final filterManager = ref.read(appFilterManagerProvider);
    
    // Initialize selected filters
    _selectedFilters = Set<String>.from(filterManager.availableUpdates.map((f) => f.id));

    // Initialize selected categories from filters
    final categories = <FilterListCategory>{};
    for (final filter in filterManager.availableUpdates) {
      categories.add(filter.category);
    }
    _selectedCategories = categories;
  }

  Future<void> _loadScriptUpdates() async {
    final userScriptManager = ref.read(userScriptManagerProvider);
    
    // In a real implementation, you would check for script updates
    // For now, we'll simulate this
    _scriptsWithUpdates = userScriptManager.userScripts
        .where((script) => script.isDownloaded)
        .take(2) // Simulate some scripts having updates
        .toList();

    if (_scriptsWithUpdates.isNotEmpty) {
      _selectedScripts = Set<String>.from(_scriptsWithUpdates.map((s) => s.id));
      _selectedCategories.add(FilterListCategory.scripts);
    }
    if (mounted) {
      setState(() {});
    }
  }

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
          width: 450,
          height: 350,
          child: AppTheme.ultraThinMaterial(
            child: _buildContent(filterManager, progressPercentage),
          ),
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
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildContent(filterManager, progressPercentage),
        ),
      ),
    );
  }

  Widget _buildContent(filterManager, int progressPercentage) {
    return Column(
      children: [
        _buildHeader(filterManager),
        Expanded(
          child: filterManager.isLoading 
            ? _buildDownloadProgress(filterManager, progressPercentage) 
            : _buildFilterSelection(filterManager),
        ),
        if (!filterManager.isLoading) _buildButtons(filterManager),
      ],
    );
  }

  Widget _buildHeader(filterManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            filterManager.isLoading ? 'Downloading Updates' : 'Available Updates',
            style: AppTheme.headline.copyWith(fontSize: 18),
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
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppTheme.secondaryLabel,
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(filterManager, int progressPercentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
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
      ),
    );
  }

  Widget _buildProgressIndicator(filterManager, int progressPercentage) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: filterManager.progress,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 3,
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

  Widget _buildFilterSelection(filterManager) {
    final filtersByCategory = <FilterListCategory, List<FilterList>>{};
    for (final filter in filterManager.availableUpdates) {
      filtersByCategory.putIfAbsent(filter.category, () => []).add(filter);
    }

    final allCategories = <FilterListCategory>[...filtersByCategory.keys];
    if (_scriptsWithUpdates.isNotEmpty) {
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
        if (category == FilterListCategory.scripts && _scriptsWithUpdates.isNotEmpty) 
          ..._scriptsWithUpdates.map((script) => _buildScriptRow(script)),
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
          style: AppTheme.headline,
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

    return GestureDetector(
      onTap: () => _toggleFilter(filter.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryLabel,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filter.name,
                    style: AppTheme.body,
                  ),
                  if (filter.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      filter.description,
                      style: AppTheme.caption,
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
              color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryLabel,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    script.name,
                    style: AppTheme.body,
                  ),
                  if (script.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      script.description,
                      style: AppTheme.caption,
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

  Widget _buildButtons(filterManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Spacer(),
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  color: AppTheme.primaryColor,
                  onPressed: (_selectedFilters.isEmpty && _selectedScripts.isEmpty) 
                      ? null 
                      : _downloadUpdates,
                  child: const Text('Download'),
                )
              : CupertinoButton.filled(
                  onPressed: (_selectedFilters.isEmpty && _selectedScripts.isEmpty) 
                      ? null 
                      : _downloadUpdates,
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
    final filterManager = ref.read(appFilterManagerProvider);
    
    setState(() {
      if (_selectedFilters.contains(filterId)) {
        _selectedFilters.remove(filterId);

        // Check if all filters in this category are deselected
        final filter = filterManager.availableUpdates.firstWhere((f) => f.id == filterId);
        final categoryFilters = filterManager.availableUpdates
            .where((f) => f.category == filter.category)
            .toList();
        final selectedCategoryFilters = categoryFilters
            .where((f) => _selectedFilters.contains(f.id))
            .toList();

        if (selectedCategoryFilters.isEmpty) {
          _selectedCategories.remove(filter.category);
        }
      } else {
        _selectedFilters.add(filterId);
        final filter = filterManager.availableUpdates.firstWhere((f) => f.id == filterId);
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
    final filterManager = ref.read(appFilterManagerProvider);
    final userScriptManager = ref.read(userScriptManagerProvider);
    
    // Handle filter list updates
    final filtersToUpdate = filterManager.availableUpdates
        .where((f) => _selectedFilters.contains(f.id))
        .toList();

    if (filtersToUpdate.isNotEmpty) {
      await filterManager.downloadSelectedFilters(filtersToUpdate);
    }

    // Handle script updates
    if (_selectedScripts.isNotEmpty) {
      final scriptsToUpdate = _scriptsWithUpdates
          .where((s) => _selectedScripts.contains(s.id))
          .toList();

      if (scriptsToUpdate.isNotEmpty) {
        for (final script in scriptsToUpdate) {
          await userScriptManager.updateUserScript(script);
        }
      }
    }
  }
}
