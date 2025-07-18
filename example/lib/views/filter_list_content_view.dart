import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'filter_row_view.dart';
import 'filter_stats_banner.dart';

class FilterListContentView extends StatelessWidget {
  final FilterListCategory selectedCategory;
  final bool showOnlyEnabledFilters;

  const FilterListContentView({
    super.key,
    required this.selectedCategory,
    required this.showOnlyEnabledFilters,
  });

  @override
  Widget build(BuildContext context) {
    final filterManager = context.watch<FilterListManager>();

    return MacosScrollbar(
      child: ListView(
        children: [
          // Stats Banner
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilterStatsBanner(filterManager: filterManager),
          ),

          // Filter Content
          _buildCategoryContent(context, filterManager),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context, FilterListManager filterManager) {
    if (selectedCategory == FilterListCategory.all) {
      // Show all categories
      final categories = FilterListCategory.values.where((cat) => cat != FilterListCategory.all).toList();

      return Column(
        children: categories.map((category) {
          final filters = _getFilteredLists(filterManager, category);

          if (filters.isEmpty) return const SizedBox.shrink();

          return _buildCategorySection(context, category, filters, filterManager);
        }).toList(),
      );
    } else if (selectedCategory == FilterListCategory.custom) {
      // Show custom filters
      final filters = showOnlyEnabledFilters ? filterManager.customFilterLists.where((f) => f.isSelected).toList() : filterManager.customFilterLists;

      return Column(
        children: filters
            .map((filter) => Column(
                  children: [
                    FilterRowView(
                      filter: filter,
                      filterManager: filterManager,
                    ),
                    if (filter != filters.last) const Divider(indent: 16),
                  ],
                ))
            .toList(),
      );
    } else {
      // Show specific category
      final filters = _getFilteredLists(filterManager, selectedCategory);

      return Column(
        children: filters
            .map((filter) => Column(
                  children: [
                    FilterRowView(
                      filter: filter,
                      filterManager: filterManager,
                    ),
                    if (filter != filters.last) const Divider(indent: 16),
                  ],
                ))
            .toList(),
      );
    }
  }

  Widget _buildCategorySection(
    BuildContext context,
    FilterListCategory category,
    List<FilterList> filters,
    FilterListManager filterManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category.displayName,
            style: MacosTheme.of(context).typography.headline.copyWith(
                  color: MacosTheme.of(context).typography.headline.color?.withOpacity(0.6),
                ),
          ),
        ),

        // Filter Rows
        ...filters.map((filter) => Column(
              children: [
                FilterRowView(
                  filter: filter,
                  filterManager: filterManager,
                ),
                if (filter != filters.last) const Divider(indent: 16),
              ],
            )),

        // Category Divider
        if (category != FilterListCategory.foreign)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
      ],
    );
  }

  List<FilterList> _getFilteredLists(
    FilterListManager filterManager,
    FilterListCategory category,
  ) {
    final lists = filterManager.filterListsForCategory(category);

    if (showOnlyEnabledFilters) {
      return lists.where((f) => f.isSelected).toList();
    }

    return lists;
  }
}
