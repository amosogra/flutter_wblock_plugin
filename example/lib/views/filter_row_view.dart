import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class FilterRowView extends StatefulWidget {
  final FilterList filter;
  final FilterListManager filterManager;

  const FilterRowView({
    super.key,
    required this.filter,
    required this.filterManager,
  });

  @override
  State<FilterRowView> createState() => _FilterRowViewState();
}

class _FilterRowViewState extends State<FilterRowView> {
  bool _isHovering = false;
  int _ruleCount = 0;
  bool _isLoadingRuleCount = false;

  @override
  void initState() {
    super.initState();
    _loadRuleCount();
  }

  @override
  void didUpdateWidget(FilterRowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.isSelected != widget.filter.isSelected ||
        oldWidget.filterManager.isUpdating != widget.filterManager.isUpdating) {
      _loadRuleCount();
    }
  }

  Future<void> _loadRuleCount() async {
    if (!widget.filter.isSelected) {
      setState(() => _ruleCount = 0);
      return;
    }

    setState(() => _isLoadingRuleCount = true);

    try {
      final count = await WBlockPlatformInterface.instance
          .getRuleCount(widget.filter);
      if (mounted) {
        setState(() {
          _ruleCount = count;
          _isLoadingRuleCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ruleCount = 0;
          _isLoadingRuleCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => widget.filterManager.toggleFilterListSelection(widget.filter.id),
        child: Container(
          color: _isHovering
              ? MacosTheme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Filter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and source link
                    Row(
                      children: [
                        Text(
                          widget.filter.name,
                          style: MacosTheme.of(context).typography.body,
                        ),
                        
                        if (widget.filter.category != FilterListCategory.custom) ...[
                          const SizedBox(width: 8),
                          MacosIconButton(
                            icon: Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: MacosTheme.of(context)
                                  .typography
                                  .body
                                  .color
                                  ?.withOpacity(0.5),
                            ),
                            onPressed: () async {
                              if (await canLaunchUrl(Uri.parse(widget.filter.url))) {
                                await launchUrl(Uri.parse(widget.filter.url));
                              }
                            },
                            semanticLabel: 'View Source',
                          ),
                        ],
                        
                        if (_ruleCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($_ruleCount rules)',
                            style: MacosTheme.of(context).typography.caption2.copyWith(
                              color: MacosTheme.of(context)
                                  .typography
                                  .caption2
                                  .color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                        
                        if (_isLoadingRuleCount) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: ProgressBar(value: 0),
                          ),
                        ],
                      ],
                    ),
                    
                    // Description
                    if (widget.filter.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.filter.description,
                        style: MacosTheme.of(context).typography.caption1.copyWith(
                          color: MacosTheme.of(context)
                              .typography
                              .caption1
                              .color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                    
                    // Version
                    if (widget.filter.version.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Version: ${widget.filter.version}',
                        style: MacosTheme.of(context).typography.caption2.copyWith(
                          color: MacosTheme.of(context)
                              .typography
                              .caption2
                              .color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Toggle Switch
              MacosSwitch(
                value: widget.filter.isSelected,
                onChanged: (_) =>
                    widget.filterManager.toggleFilterListSelection(widget.filter.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
