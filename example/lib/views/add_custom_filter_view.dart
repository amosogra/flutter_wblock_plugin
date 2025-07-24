import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

class AddCustomFilterView extends StatefulWidget {
  final VoidCallback onDismiss;

  const AddCustomFilterView({
    super.key,
    required this.onDismiss,
  });

  @override
  State<AddCustomFilterView> createState() => _AddCustomFilterViewState();
}

class _AddCustomFilterViewState extends State<AddCustomFilterView> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get _canAdd => _nameController.text.trim().isNotEmpty && _urlController.text.trim().isNotEmpty && Uri.tryParse(_urlController.text.trim()) != null;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
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
                  'Add Custom Filter',
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

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  MacosTextField(
                    controller: _nameController,
                    placeholder: 'Filter Name',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  MacosTextField(
                    controller: _urlController,
                    placeholder: 'Filter URL',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  MacosTextField(
                    controller: _descriptionController,
                    placeholder: 'Description (Optional)',
                    maxLines: 3,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.large,
                          onPressed: widget.onDismiss,
                          secondary: true,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.large,
                          onPressed: _canAdd ? _addFilter : null,
                          child: const Text('Add'),
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

  void _addFilter() {
    final filter = FilterList(
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      category: FilterListCategory.custom,
      isSelected: true,
      description: _descriptionController.text.trim(),
    );

    final filterManager = context.read<FilterListManager>();
    filterManager.addCustomFilterList(filter);
    widget.onDismiss();
  }
}
