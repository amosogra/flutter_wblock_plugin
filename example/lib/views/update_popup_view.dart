import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class UpdatePopupView extends StatefulWidget {
  final List<FilterList> availableUpdates;
  final VoidCallback onDismiss;
  final Function(List<FilterList>) onUpdate;

  const UpdatePopupView({
    super.key,
    required this.availableUpdates,
    required this.onDismiss,
    required this.onUpdate,
  });

  @override
  State<UpdatePopupView> createState() => _UpdatePopupViewState();
}

class _UpdatePopupViewState extends State<UpdatePopupView> {
  late Map<String, bool> _selectedUpdates;

  @override
  void initState() {
    super.initState();
    _selectedUpdates = {
      for (var filter in widget.availableUpdates) filter.id: true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 400,
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: MacosTheme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  'Updates Available',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(Icons.close),
                  onPressed: widget.onDismiss,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Update List
          Expanded(
            child: MacosScrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.availableUpdates.length,
                itemBuilder: (context, index) {
                  final filter = widget.availableUpdates[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        MacosCheckbox(
                          value: _selectedUpdates[filter.id] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _selectedUpdates[filter.id] = value;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filter.name,
                                style: MacosTheme.of(context).typography.body,
                              ),
                              if (filter.version.isNotEmpty)
                                Text(
                                  'Current version: ${filter.version}',
                                  style: MacosTheme.of(context).typography.caption1.copyWith(
                                    color: MacosTheme.of(context)
                                        .typography
                                        .caption1
                                        .color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: MacosTheme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: widget.onDismiss,
                    secondary: true,
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: _selectedUpdates.values.any((v) => v)
                        ? () {
                            final selectedFilters = widget.availableUpdates
                                .where((f) => _selectedUpdates[f.id] ?? false)
                                .toList();
                            widget.onUpdate(selectedFilters);
                            widget.onDismiss();
                          }
                        : null,
                    child: const Text('Update Selected'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
