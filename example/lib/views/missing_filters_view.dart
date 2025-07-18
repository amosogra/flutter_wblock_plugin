import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class MissingFiltersView extends StatelessWidget {
  final List<FilterList> missingFilters;
  final VoidCallback onDismiss;
  final VoidCallback onUpdate;

  const MissingFiltersView({
    super.key,
    required this.missingFilters,
    required this.onDismiss,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 350,
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
                  'Missing Filters',
                  style: MacosTheme.of(context).typography.title2,
                ),
                const Spacer(),
                MacosIconButton(
                  icon: const MacosIcon(Icons.close),
                  onPressed: onDismiss,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The following filter lists need to be downloaded:',
                    style: MacosTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 16),
                  
                  // Missing Filters List
                  Expanded(
                    child: MacosScrollbar(
                      child: ListView.builder(
                        itemCount: missingFilters.length,
                        itemBuilder: (context, index) {
                          final filter = missingFilters[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: MacosColors.systemOrangeColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    filter.name,
                                    style: MacosTheme.of(context).typography.body,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.regular,
                          onPressed: onDismiss,
                          secondary: true,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.regular,
                          onPressed: onUpdate,
                          child: const Text('Download Missing'),
                        ),
                      ),
                    ],
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
