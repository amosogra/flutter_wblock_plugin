import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'dart:math' as math;

class WhitelistManagerView extends StatefulWidget {
  final AppFilterManager filterManager;
  final VoidCallback onDismiss;

  const WhitelistManagerView({
    super.key,
    required this.filterManager,
    required this.onDismiss,
  });

  @override
  State<WhitelistManagerView> createState() => _WhitelistManagerViewState();
}

class _WhitelistManagerViewState extends State<WhitelistManagerView> {
  final _newDomainController = TextEditingController();
  Set<String> _selectedDomains = <String>{};
  bool _showError = false;
  String _errorMessage = '';
  bool _isProcessing = false;

  List<String> get whitelistedDomains => widget.filterManager.whitelistViewModel.whitelistedDomains;

  // Create a padded list to ensure minimum 10 rows for better UX
  List<String> get paddedDomains {
    final domains = whitelistedDomains.toList();
    final padding = List.filled(math.max(0, 10 - domains.length), '');
    return domains + padding;
  }

  @override
  void initState() {
    super.initState();
    widget.filterManager.whitelistViewModel.loadWhitelistedDomains();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 400,
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MacosColors.windowBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildDomainsList(),
              ),
              _buildAddDomainSection(),
              if (_showError) _buildErrorMessage(),
              if (_isProcessing) _buildProgressIndicator(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Whitelisted Domains',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MacosColors.labelColor,
          ),
        ),
        const Spacer(),
        MacosIconButton(
          icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }

  Widget _buildDomainsList() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 250, // Fixed height to prevent jumping
      decoration: BoxDecoration(
        color: MacosColors.controlBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MacosColors.separatorColor),
      ),
      child: ListView.builder(
        itemCount: paddedDomains.length,
        itemBuilder: (context, index) {
          final domain = paddedDomains[index];
          if (domain.isEmpty) {
            return const SizedBox(height: 24); // Empty row placeholder
          }
          return _buildDomainRow(domain, index);
        },
      ),
    );
  }

  Widget _buildDomainRow(String domain, int index) {
    final isSelected = _selectedDomains.contains(domain);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          MacosCheckbox(
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedDomains.add(domain);
                } else {
                  _selectedDomains.remove(domain);
                }
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              domain,
              style: const TextStyle(
                fontSize: 13,
                color: MacosColors.labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDomainSection() {
    return Row(
      children: [
        Expanded(
          child: MacosTextField(
            controller: _newDomainController,
            placeholder: 'Add domain (e.g. example.com)',
            onSubmitted: (_) => _addDomain(),
          ),
        ),
        const SizedBox(width: 12),
        PushButton(
          controlSize: ControlSize.large,
          onPressed: (_newDomainController.text.trim().isEmpty || _isProcessing) ? null : _addDomain,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        _errorMessage,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: const Column(
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 4),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 12,
              color: MacosColors.secondaryLabelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          PushButton(
            controlSize: ControlSize.large,
            onPressed: (whitelistedDomains.isEmpty || _isProcessing) ? null : _selectAllDomains,
            child: const Text('Select All'),
          ),
          const SizedBox(width: 16),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: (_selectedDomains.isEmpty || _isProcessing) ? null : _deleteSelectedDomains,
            child: const Text('Delete Selected'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _addDomain() {
    final trimmed = _newDomainController.text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _showError = false;
    });

    // Simulate async operation
    Future.delayed(const Duration(milliseconds: 500), () {
      final result = widget.filterManager.whitelistViewModel.addDomain(trimmed);

      setState(() {
        _isProcessing = false;
        if (result.isSuccess) {
          _newDomainController.clear();
        } else {
          _showError = true;
          _errorMessage = result.error!.localizedDescription;
        }
      });
    });
  }

  void _selectAllDomains() {
    setState(() {
      _selectedDomains = Set<String>.from(whitelistedDomains);
    });
  }

  void _deleteSelectedDomains() {
    if (_selectedDomains.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate async operation
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final domain in _selectedDomains) {
        widget.filterManager.whitelistViewModel.removeDomain(domain);
      }

      setState(() {
        _selectedDomains.clear();
        _isProcessing = false;
      });
    });
  }

  @override
  void dispose() {
    _newDomainController.dispose();
    super.dispose();
  }
}
